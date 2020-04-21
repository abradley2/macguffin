package lib

import (
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var MongoClient *mongo.Client

func init() {
	var err error
	MongoClient, err = mongo.NewClient(options.Client().ApplyURI("mongodb://localhost:27017"))

	if err != nil {
		panic(err)
	}
}
