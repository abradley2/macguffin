package articles

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/abradley2/macguffin/lib"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/pkg/errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type article struct {
	ItemTitle   string `json:"itemTitle"`
	Thumbnail   string `json:"string,omitempty"`
	ID          string `json:"id"`
	Content     string `json:"content"`
	CreatedAt   string `json:"createdAt"`
	Approved    bool   `json:"approved"`
	Creator     string `json:"creator"`
	ArticleType string `json:"articleType"`
}

func getArticlesJSON(ctx context.Context, artType string) ([]byte, error) {
	var (
		js  []byte
		err error
	)

	dlCtx, cancel := context.WithDeadline(ctx, time.Now().Add(5*time.Second))
	defer cancel()

	c, err := articleCollection(artType)

	if err != nil {
		return js, errors.Wrap(err, "Could not get collection for getArticlesJSON")
	}

	res, err := c.Find(
		dlCtx,
		bson.M{
			"approved": bson.M{
				"$eq": true,
			},
		},
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
	err = res.All(dlCtx, artList)

	if err != nil {
		return js, errors.Wrap(err, "Failed reading/decoding results of getArticles query")
	}

	return json.Marshal(artList)
}

func createArticle(ctx context.Context, clientToken string, art article) (string, error) {
	var err error
	var createdID string

	user, err := token.GetLoggedInUser(ctx, clientToken)

	if err != nil {
		return createdID, errors.Wrap(err, "Failed to get logged in user")
	}

	c, err := articleCollection(art.ArticleType)

	if err != nil {
		return createdID, errors.Wrap(err, "Could not get collection to create article")
	}

	insRes, err := c.InsertOne(
		ctx,
		bson.M{
			"Creator":     user.UserID,
			"Content":     art.Content,
			"Approved":    false,
			"CreatedAt":   primitive.NewDateTimeFromTime(time.Now()),
			"ItemTitle":   art.ItemTitle,
			"Thumbnail":   art.Thumbnail,
			"ArticleType": art.ArticleType,
		},
		&options.InsertOneOptions{},
	)

	if err != nil {
		return createdID, errors.Wrapf(err, "Failed to insert document into db for user: %s\n%s", user.UserID, art.ItemTitle)
	}

	if oid, ok := insRes.InsertedID.(primitive.ObjectID); ok {
		createdID = oid.Hex()
	}

	return createdID, err
}

func updateArticle(ctx context.Context) {

}

func articleCollection(artType string) (*mongo.Collection, error) {
	var c *mongo.Collection
	var collectionName string

	for i := 0; i < len(lib.ArticleCollections); i++ {
		if lib.ArticleCollections[i] == artType {
			collectionName = lib.ArticleCollections[i]
		}
	}

	c = lib.MongoDB.Collection(artType)

	if c == nil || collectionName == "" {
		return c, fmt.Errorf("Failed to load collection: %s", artType)
	}

	return c, nil
}
