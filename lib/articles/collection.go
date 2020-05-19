package articles

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/pkg/errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type article struct {
	ItemTitle   string    `json:"itemTitle" bson:"itemTitle"`
	Thumbnail   string    `json:"string,omitempty" bson:"string,omitempty"`
	ID          string    `json:"_id" bson:"_id"`
	Content     string    `json:"content" bson:"content"`
	CreatedAt   time.Time `json:"createdAt" bson:"createdAt"`
	Approved    bool      `json:"approved" bson:"approved"`
	Creator     string    `json:"creator" bson:"creator"`
	ArticleType string    `json:"articleType" bson:"articleType"`
}

type getArticlesJSONOptions struct {
	userID      string
	articleType string
	creator     string
}

var admins = map[string]bool{
	"8582764": true,
}

func (opts getArticlesJSONOptions) toQuery(userID string) (bson.M, error) {
	var err error
	q := make(map[string]interface{})

	if admins[userID] == false {
		q["approved"] = bson.M{
			"$eq": true,
		}
	}

	q["articleType"] = bson.M{
		"$eq": opts.articleType,
	}

	if opts.creator != "" {
		q["creator"] = bson.M{
			"$eq": opts.creator,
		}
	}

	if opts.articleType == "" {
		err = fmt.Errorf("getArticlesOptions missing required parameter 'articleType'")
	}

	return q, err
}

func getArticlesJSON(
	ctx context.Context,
	articles database.Collection,
	opts getArticlesJSONOptions,
) ([]byte, error) {
	var (
		js  []byte
		err error
	)

	dlCtx, cancel := context.WithDeadline(ctx, time.Now().Add(5*time.Second))
	defer cancel()

	findQuery, err := opts.toQuery(opts.userID)

	if err != nil {
		return js, errors.Wrapf(err, "Could not generate query from getArticlesJSONOptions")
	}

	res, err := articles.Find(
		dlCtx,
		findQuery,
		&options.FindOptions{
			Sort: bson.M{
				"createdAt": 1,
			},
		},
	)

	if err != nil {
		return js, errors.Wrap(err, "Failed in execution of getArticles query")
	}

	artList := []article{}
	err = res.All(dlCtx, &artList)

	if err != nil {
		return js, errors.Wrapf(err, "Failed reading/decoding results of getArticles query")
	}

	return json.Marshal(artList)
}

type createArticleParams struct {
	tokens   database.Collection
	articles database.Collection
	users    database.Collection
}

func createArticle(
	ctx context.Context,
	clientToken string,
	art article,
	params createArticleParams,
) (string, error) {
	var err error
	var createdID string

	user, err := token.GetLoggedInUser(
		ctx,
		clientToken,
		token.GetLoggedInUserParams{
			Tokens: params.tokens,
			Users:  params.users,
		},
	)

	if err != nil {
		return createdID, errors.Wrap(err, "Failed to get logged in user")
	}

	createdID, err = params.articles.InsertOne(
		ctx,
		bson.M{
			"creator":     user.UserID,
			"content":     art.Content,
			"approved":    false,
			"createdAt":   primitive.NewDateTimeFromTime(time.Now()),
			"itemTitle":   art.ItemTitle,
			"thumbnail":   art.Thumbnail,
			"articleType": art.ArticleType,
		},
		&options.InsertOneOptions{},
	)

	if err != nil {
		return createdID, errors.Wrapf(err, "Failed to insert document into db for user: %s\n%s", user.UserID, art.ItemTitle)
	}

	return createdID, err
}

func updateArticle(ctx context.Context) {

}

func getArticleCollection(
	artType string,
	db database.Database,
) (database.Collection, error) {
	var c database.Collection
	var collectionName string

	for i := 0; i < len(database.ArticleCollections); i++ {
		if database.ArticleCollections[i] == artType {
			collectionName = database.ArticleCollections[i]
		}
	}

	if collectionName == "" {
		return c, fmt.Errorf("invalid collection name: %s", artType)
	}

	c = db.Collection(artType)

	if c == nil {
		return c, fmt.Errorf("failed to load collection with name = %s", artType)
	}

	return c, nil
}
