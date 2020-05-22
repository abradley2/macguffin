package token

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/pkg/errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type UserTokenData struct {
	UserID      string `json:"userID"`
	AccessToken string `json:"accessToken"`
	ClientToken string `json:"clientToken"`
}

type UserData struct {
	UserID string `json:"userID"`
}

type storeTokenParams struct {
	tokensCollection database.Collection
	agentsCollection database.Collection
}

func storeToken(
	ctx context.Context,
	ghUserRes githubAccessTokenResponse,
	userID string,
	params storeTokenParams,
) (string, error) {
	var (
		tokensCollection = params.tokensCollection
		agentsCollection = params.agentsCollection
		token            string
		err              error
	)

	h := sha256.New()
	h.Write(
		[]byte(
			fmt.Sprintf("%s:%s", ghUserRes.AccessToken, userID),
		),
	)

	token = base64.StdEncoding.EncodeToString(h.Sum(nil))

	doc := bson.M{
		"userID":      userID,
		"accessToken": ghUserRes.AccessToken,
		"clientToken": token,
		"createdAt":   primitive.NewDateTimeFromTime(time.Now()),
	}

	_, err = tokensCollection.InsertOne(ctx, doc, &options.InsertOneOptions{})

	if err != nil {
		return "", errors.Wrap(err, "Could not insert user document into tokens collection")
	}

	err = checkUser(ctx, agentsCollection, userID, false)

	return token, err
}

func checkUser(ctx context.Context, agents database.Collection, userID string, retry bool) error {
	f := bson.M{
		"userID": bson.M{
			"$eq": userID,
		},
	}

	res := agents.FindOne(ctx, f, &options.FindOneOptions{})

	if res.Err() == mongo.ErrNoDocuments && retry == false {
		err := createUser(ctx, userID, agents)

		if err != nil {
			return err
		}

		checkUser(ctx, agents, userID, true)
	}

	return res.Err()
}

func createUser(ctx context.Context, userID string, agents database.Collection) error {
	u := bson.M{
		"userID":      userID,
		"initialized": false,
	}

	_, err := agents.InsertOne(ctx, u, &options.InsertOneOptions{})

	if err != nil {
		return err
	}

	return nil
}

type errTokenExpired struct{}

// Error _
func (errTokenExpired) Error() string {
	return "Client token is expired"
}

// ErrTokenExpired indicates an expired token
var ErrTokenExpired errTokenExpired

type GetLoggedInUserParams struct {
	Tokens database.Collection
	Users  database.Collection
}

func GetLoggedInUser(
	ctx context.Context,
	clientToken string,
	params GetLoggedInUserParams,
) (UserData, error) {
	var (
		loggedInUser UserData
		err          error
		tokens       = params.Tokens
		users        = params.Users
	)

	tokensRes := tokens.FindOne(
		ctx,
		bson.M{
			"clientToken": bson.M{
				"$eq": clientToken,
			},
		},
		&options.FindOneOptions{},
	)

	if tokensRes.Err() == mongo.ErrNoDocuments {
		return loggedInUser, ErrTokenExpired
	}

	tokenData := UserTokenData{}

	err = tokensRes.Decode(&tokenData)

	if err != nil {
		return loggedInUser, errors.Wrap(err, "Failed to decode token document from db")
	}

	userRes := users.FindOne(
		ctx,
		bson.M{
			"userID": bson.M{
				"$eq": tokenData.UserID,
			},
		},
		&options.FindOneOptions{},
	)

	if userRes.Err() == mongo.ErrNoDocuments {
		return loggedInUser, fmt.Errorf("Failed to find user for token userID: %s", tokenData.UserID)
	}

	err = userRes.Decode(&loggedInUser)

	if err != nil {
		err = errors.Wrapf(err, "Failed to decode agent document into user data for userID: %s", tokenData.UserID)
	}

	return loggedInUser, err
}
