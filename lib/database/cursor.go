package database

import (
	"context"

	"go.mongodb.org/mongo-driver/mongo"
)

// Cursor wrapper of mongo.Cursor
type Cursor interface {
	All(context.Context, interface{}) error
	Next(context.Context) bool
	Decode(interface{}) error
}

type mongoCursor struct {
	cursor *mongo.Cursor
}

func (c *mongoCursor) All(ctx context.Context, ref interface{}) error {
	return c.cursor.All(ctx, ref)
}

func (c *mongoCursor) Next(ctx context.Context) bool {
	return c.cursor.Next(ctx)
}

func (c *mongoCursor) Decode(ref interface{}) error {
	return c.cursor.Decode(ref)
}
