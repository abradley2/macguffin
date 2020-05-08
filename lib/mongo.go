package lib

import (
	"context"
	"fmt"
	"os"
	"time"

	"log"

	"github.com/abradley2/macguffin/lib/env"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var logger *log.Logger = log.New(os.Stderr, "mongo.go ", log.LstdFlags)

// MacguffinsCollection articles about macguffins
const MacguffinsCollection = "macguffins"

// SitesCollection articles about sites
const SitesCollection = "sites"

// EventsCollection articles about events
const EventsCollection = "events"

// ArticleCollections All article collections
var ArticleCollections = [3]string{
	MacguffinsCollection,
	SitesCollection,
	EventsCollection,
}

// TokensCollection where we store tokens
const TokensCollection = "tokens"

// AgentsCollection where we store agent data
const AgentsCollection = "agents"

// MongoClient client for accessing mongodb instance
var MongoClient *mongo.Client

// MongoDB the default database used for this application
var MongoDB *mongo.Database

func init() {
	logger.Printf("Initializing db")
	var err error

	mongoURI := fmt.Sprintf("mongodb://%s:%s", env.MongoHost, env.MongoPort)
	MongoClient, err = mongo.NewClient(options.Client().ApplyURI(mongoURI))

	if err != nil {
		logger.Fatalf("Error creating mongo client: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	err = MongoClient.Connect(ctx)

	if err != nil {
		logger.Fatalf("Error connecting to mongo instance: %v", err)
	}

	MongoDB = MongoClient.Database("macguffin_main", nil)

	setupTokensCollection()
}

func setupTokensCollection() {
	tc := MongoDB.Collection(TokensCollection, nil)

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
