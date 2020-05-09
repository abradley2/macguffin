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
	ItemTitle   string    `json:"itemTitle"`
	Thumbnail   string    `json:"string,omitempty"`
	ID          string    `json:"_id" bson:"_id"`
	Content     string    `json:"content"`
	CreatedAt   time.Time `json:"createdAt"`
	Approved    bool      `json:"approved"`
	Creator     string    `json:"creator"`
	ArticleType string    `json:"articleType"`
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

func getArticlesJSON(ctx context.Context, opts getArticlesJSONOptions) ([]byte, error) {
	var (
		js      []byte
		err     error
		artType = opts.articleType
	)

	dlCtx, cancel := context.WithDeadline(ctx, time.Now().Add(5*time.Second))
	defer cancel()

	c, err := articleCollection(artType)

	if err != nil {
		return js, errors.Wrapf(err, "Could not get collection containing articles")
	}

	findQuery, err := opts.toQuery(opts.userID)

	if err != nil {
		return js, errors.Wrapf(err, "Could not generate query from getArticlesJSONOptions")
	}

	res, err := c.Find(
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

func createArticle(ctx context.Context, clientToken string, art article) (string, error) {
	var err error
	var createdID string

	user, err := token.GetLoggedInUser(ctx, clientToken)

	if err != nil {
		return createdID, errors.Wrap(err, "Failed to get logged in user")
	}

	c, err := articleCollection(art.ArticleType)

	if err != nil {
		return createdID, errors.Wrapf(err, "Could not get collection to create article")
	}

	insRes, err := c.InsertOne(
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

	switch t := insRes.InsertedID.(type) {
	case primitive.ObjectID:
		createdID = t.Hex()
	default:
		err = fmt.Errorf("Failed to decode created objectId into hex")
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

	if collectionName == "" {
		return c, fmt.Errorf("invalid collection name: %s", artType)
	}

	c = lib.MongoDB.Collection(artType)

	if c == nil {
		return c, fmt.Errorf("failed to load collection with name = %s", artType)
	}

	return c, nil
}
