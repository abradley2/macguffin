package database

import (
	"context"
	"encoding/json"

	"github.com/lucsky/cuid"
	"github.com/spaolacci/murmur3"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func GetQueryHash(q interface{}) (string, error) {
	j, err := json.Marshal(q)
	if err != nil {
		return "", err
	}

	h := murmur3.New64()
	h.Write(j)

	return string(h.Sum(nil)), err
}

type TestDatabase struct {
	queries map[string]*[]byte
}

func (db *TestDatabase) Collection(collectionName string) Collection {
	return &TestCollection{
		name:    collectionName,
		queries: db.queries,
	}
}

type TestCollection struct {
	name       string
	LastInsert []byte
	queries    map[string]*[]byte
}

func (c *TestCollection) HashQuery(q interface{}, doc []byte) {
	h, err := GetQueryHash(q)

	if err != nil {
		panic(err)
	}

	if c.queries == nil {
		c.queries = make(map[string]*[]byte)
	}
	c.queries[h] = &doc
}

func (c *TestCollection) InsertOne(ctx context.Context, q interface{}, opts *options.InsertOneOptions) (string, error) {
	var s string = cuid.New()
	var err error

	js, err := json.Marshal(q)

	c.LastInsert = js

	return s, err
}

func (c *TestCollection) Find(ctx context.Context, q interface{}, opts *options.FindOptions) (Cursor, error) {
	j, err := json.Marshal(q)

	if err != nil {
		return &TestCursor{}, nil
	}

	h := murmur3.New64()
	h.Write(j)

	colBytes := c.queries[string(h.Sum(nil))]

	var col []*json.RawMessage
	err = json.Unmarshal(*colBytes, &col)

	return &TestCursor{documents: col, blob: colBytes}, err
}

func (c *TestCollection) FindOne(ctx context.Context, q interface{}, opts *options.FindOneOptions) SingleResult {
	j, err := json.Marshal(q)

	if err != nil {
		return &TestSingleResult{err: err}
	}

	h := murmur3.New64()
	h.Write(j)

	colBytes := c.queries[string(h.Sum(nil))]

	if colBytes == nil {
		err = mongo.ErrNoDocuments
	}

	return &TestSingleResult{
		err:         err,
		resultBytes: colBytes,
	}
}

type TestCursor struct {
	target    string
	blob      *[]byte
	index     int
	documents []*json.RawMessage
}

func (c *TestCursor) Blob() *[]byte {
	return c.blob
}

func (c *TestCursor) All(ctx context.Context, dest interface{}) error {
	return json.Unmarshal(*c.blob, dest)
}

func (c *TestCursor) Decode(target interface{}) error {
	return nil
}

func (c *TestCursor) Next(ctx context.Context) bool {
	var hasNext bool

	// TODO: should probably mutex lock this
	if c.index+1 != len(c.documents) {
		hasNext = true
		c.index = c.index + 1
	}

	return hasNext
}

func (c *TestCursor) Err() error {
	return nil
}

type TestSingleResult struct {
	resultBytes *[]byte
	err         error
}

func (r *TestSingleResult) Err() error {
	return r.err
}

func (r *TestSingleResult) Decode(ref interface{}) error {
	return json.Unmarshal(*r.resultBytes, ref)
}

func (r *TestSingleResult) DecodeBytes() ([]byte, error) {
	return *r.resultBytes, r.err
}
