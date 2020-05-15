package lib

import (
	"context"
	"fmt"
	"os"
	"time"

	"log"

	"github.com/abradley2/macguffin/lib/env"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
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

// MongoClient client for accessing mongodb instance
var MongoClient *mongo.Client

type mgDB struct {
	db *mongo.Database
}
type mgCollection struct {
	collection *mongo.Collection
}
type mgCursor struct {
	cursor *mongo.Cursor
}
type mgSingleResult struct {
	result *mongo.SingleResult
}

var MgDB DB

type DB interface {
	Collection(string) Collection
}

func (d *mgDB) Collection(collectionName string) Collection {
	var c = new(mgCollection)
	c.collection = d.db.Collection(collectionName, nil)

	return c
}

type Collection interface {
	Find(context.Context, interface{}, *options.FindOptions) (Cursor, error)
	FindOne(context.Context, interface{}, *options.FindOneOptions) SingleResult
	InsertOne(context.Context, interface{}, *options.InsertOneOptions) (string, error)
}

func (c *mgCollection) Find(ctx context.Context, filter interface{}, opts *options.FindOptions) (Cursor, error) {
	var err error
	curs, err := c.collection.Find(ctx, filter, opts)

	return &mgCursor{cursor: curs}, err
}

func (c *mgCollection) FindOne(ctx context.Context, filter interface{}, opts *options.FindOneOptions) SingleResult {
	return &mgSingleResult{result: c.collection.FindOne(ctx, filter, opts)}
}

func (c *mgCollection) InsertOne(ctx context.Context, doc interface{}, opts *options.InsertOneOptions) (string, error) {
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

type Cursor interface {
	All(context.Context, interface{}) error
	Next(context.Context) bool
	Decode(interface{}) error
}

func (c *mgCursor) All(ctx context.Context, ref interface{}) error {
	return c.cursor.All(ctx, ref)
}

func (c *mgCursor) Next(ctx context.Context) bool {
	return c.cursor.Next(ctx)
}

func (c *mgCursor) Decode(ref interface{}) error {
	return c.cursor.Decode(ref)
}

type SingleResult interface {
	Decode(interface{}) error
	DecodeBytes() ([]byte, error)
	Err() error
}

func (r *mgSingleResult) Decode(ref interface{}) error {
	return r.result.Decode(ref)
}

func (r *mgSingleResult) DecodeBytes() ([]byte, error) {
	return r.result.DecodeBytes()
}

func (r *mgSingleResult) Err() error {
	return r.result.Err()
}

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

	db := MongoClient.Database("macguffin_main", nil)

	MgDB = &mgDB{db: db}

	setupTokensCollection(db)
}

func setupTokensCollection(db *mongo.Database) {
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
