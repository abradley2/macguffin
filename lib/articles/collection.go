package articles

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/abradley2/macguffin/lib"
	"github.com/pkg/errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type article struct {
	ItemTitle string `json:"itemTitle"`
	Thumbnail string `json:"string,omitempty"`
	ID        string `json:"id"`
	Content   string `json:"content"`
	CreatedAt string `json:"createdAt"`
}

func getArticlesJSON(ctx context.Context, artType string) ([]byte, error) {
	var (
		collectionName string
		js             []byte
		err            error
	)

	for i := 0; i < len(lib.ArticleCollections); i++ {
		if lib.ArticleCollections[i] == artType {
			collectionName = lib.ArticleCollections[i]
		}
	}

	c := lib.MongoDB.Collection(artType)

	if c == nil || collectionName == "" {
		return js, fmt.Errorf("Failed to load collection: %s", artType)
	}

	dlCtx, cancel := context.WithDeadline(ctx, time.Now().Add(5*time.Second))
	defer cancel()

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
