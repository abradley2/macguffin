package token

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"log"
	"time"

	"github.com/abradley2/macguffin/lib"
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

func storeToken(
	ctx context.Context,
	ghUserRes githubAccessTokenResponse,
	userID string,
	logger *log.Logger,
) (string, error) {
	var token string
	var err error

	h := sha256.New()
	h.Write(
		[]byte(
			fmt.Sprintf("%s:%s", ghUserRes.AccessToken, userID),
		),
	)

	token = base64.StdEncoding.EncodeToString(h.Sum(nil))

	logger.Printf("Storing token for user: %s", userID)

	doc := bson.M{
		"userID":      userID,
		"accessToken": ghUserRes.AccessToken,
		"clientToken": token,
		"createdAt":   primitive.NewDateTimeFromTime(time.Now()),
	}

	tc := lib.MongoDB.Collection(lib.TokensCollection, nil)

	_, err = tc.InsertOne(ctx, doc, &options.InsertOneOptions{})

	if err != nil {
		return "", errors.Wrap(err, "Could not insert user document into tokens collection")
	}

	checkUser(ctx, userID, false)

	return token, err
}

func checkUser(ctx context.Context, userID string, retry bool) error {
	agents := lib.MongoDB.Collection(lib.AgentsCollection)

	f := bson.M{
		"userID": bson.M{
			"$eq": userID,
		},
	}

	res := agents.FindOne(ctx, f, &options.FindOneOptions{})

	if res.Err() == mongo.ErrNoDocuments && retry == false {
		err := createUser(ctx, userID)

		if err != nil {
			return err
		}

		checkUser(ctx, userID, true)
	}

	return nil
}

func createUser(ctx context.Context, userID string) error {
	u := bson.M{
		"userID":      userID,
		"initialized": false,
	}

	agents := lib.MongoDB.Collection(lib.AgentsCollection)

	res, err := agents.InsertOne(ctx, u, &options.InsertOneOptions{})

	if err != nil {
		return err
	}

	if oid, ok := res.InsertedID.(primitive.ObjectID); ok {
		id := oid.Hex()

		fmt.Println(id)
	}

	return nil
}

type ErrTokenExpired struct{}

func (_ ErrTokenExpired) Error() string {
	return "Client token is expired"
}

func GetLoggedInUser(ctx context.Context, clientToken string) (UserData, error) {
	var (
		loggedInUser UserData
		err          error
	)

	tokens := lib.MongoDB.Collection(lib.TokensCollection)

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
		return loggedInUser, ErrTokenExpired{}
	}

	tokenData := UserTokenData{}

	err = tokensRes.Decode(&tokenData)

	if err != nil {
		return loggedInUser, errors.Wrap(err, "Failed to decode token document from db")
	}

	agents := lib.MongoDB.Collection(lib.AgentsCollection)

	userRes := agents.FindOne(
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

	user := UserData{}

	err = userRes.Decode(&user)

	if err != nil {
		err = errors.Wrapf(err, "Failed to decode agent document into user data for userID: %s", tokenData.UserID)
	}

	return loggedInUser, err
}
