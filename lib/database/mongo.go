package database

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

// ProfileCollection where we store profile data describing agents- this is mostly their stats
const ProfileCollection = "agentprofiles"

func OpenDatabase() (Database, error) {
	var err error

	mongoURI := fmt.Sprintf("mongodb://%s:%s", env.MongoHost, env.MongoPort)
	mClient, err := mongo.NewClient(options.Client().ApplyURI(mongoURI))

	if err != nil {
		logger.Fatalf("Error creating mongo client: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	err = mClient.Connect(ctx)

	if err != nil {
		logger.Fatalf("Error connecting to mongo instance: %v", err)
	}

	db := mClient.Database("macguffin_main", nil)

	setupTokenIndexes(db)

	select {
	case <-ctx.Done():
		return &mongoDatabase{}, fmt.Errorf("Failed to initialize database before timeout")
	default:
		return &mongoDatabase{db: db}, err
	}
}
