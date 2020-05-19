package database

import (
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func setupTokenIndexes(db *mongo.Database) {
	tc := db.Collection(TokensCollection, nil)

	exp := int32(3600)
	bg := true
	v := int32(1)

	tc.Indexes().CreateOne(
		context.Background(),
		mongo.IndexModel{
			Keys: bson.M{"createdAt": 1},
			Options: &options.IndexOptions{
				ExpireAfterSeconds: &exp,
				Background:         &bg,
				Version:            &v,
			},
		},
		nil,
	)
}
