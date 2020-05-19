package database

import (
	"context"
	"fmt"

	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type mongoCollection struct {
	collection *mongo.Collection
}

// Collection wrapper of mongo.Collection
type Collection interface {
	Find(context.Context, interface{}, *options.FindOptions) (Cursor, error)
	FindOne(context.Context, interface{}, *options.FindOneOptions) SingleResult
	InsertOne(context.Context, interface{}, *options.InsertOneOptions) (string, error)
}

func (c *mongoCollection) Find(ctx context.Context, filter interface{}, opts *options.FindOptions) (Cursor, error) {
	var err error
	curs, err := c.collection.Find(ctx, filter, opts)

	return &mongoCursor{cursor: curs}, err
}

func (c *mongoCollection) FindOne(ctx context.Context, filter interface{}, opts *options.FindOneOptions) SingleResult {
	return &mongoSingleResult{result: c.collection.FindOne(ctx, filter, opts)}
}

func (c *mongoCollection) InsertOne(ctx context.Context, doc interface{}, opts *options.InsertOneOptions) (string, error) {
	var insertedID string
	var err error

	res, err := c.collection.InsertOne(ctx, doc, opts)

	if err != nil {
		return insertedID, err
	}

	if id, ok := res.InsertedID.(primitive.ObjectID); ok {
		return id.Hex(), err
	}

	return insertedID, fmt.Errorf("Failed to get ID for inserted document")
}
