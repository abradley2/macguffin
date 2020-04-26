package lib

import (
	"context"
	"fmt"
	"os"
	"time"

	"log"

	"github.com/abradley2/macguffin/lib/env"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var logger *log.Logger = log.New(os.Stderr, "mongo.go ", log.LstdFlags)

// MongoClient client for accessing mongodb instance
var MongoClient *mongo.Client

func init() {
	var err error

	mongoURI := fmt.Sprintf("mongodb://%s:%s", env.MongoHost, env.MongoPort)
	MongoClient, err = mongo.NewClient(options.Client().ApplyURI(mongoURI))

	if err != nil {
		logger.Fatalf("Error creating mongo client: %v", err)
	}

	ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
	err = MongoClient.Connect(ctx)

	if err != nil {
		logger.Fatalf("Error connecting to mongo instance: %v", err)
	}
}
