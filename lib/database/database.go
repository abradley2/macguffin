package database

import "go.mongodb.org/mongo-driver/mongo"

type Database interface {
	Collection(string) Collection
}

type mongoDatabase struct {
	db *mongo.Database
}

func (d *mongoDatabase) Collection(collectionName string) Collection {
	var c = new(mongoCollection)
	c.collection = d.db.Collection(collectionName, nil)

	return c
}
