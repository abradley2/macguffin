package lib

import (
	"context"
	"encoding/json"

	"github.com/spaolacci/murmur3"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var TestDB DB = &testDB{}

type testDB struct {
	queries map[string]*[]byte
}

func (db *testDB) HashQuery(q interface{}, doc []byte) {
	j, err := json.Marshal(q)
	if err != nil {
		panic(err)
	}

	h := murmur3.New64()
	h.Write(j)

	db.queries[string(h.Sum(nil))] = &doc
}

func (db *testDB) Collection(collectionName string) Collection {
	return &testCollection{
		name:    collectionName,
		queries: db.queries,
	}
}

type testCollection struct {
	name    string
	queries map[string]*[]byte
}

func (c *testCollection) InsertOne(ctx context.Context, q interface{}, opts *options.InsertOneOptions) (string, error) {
	var s string = "hello"
	var err error

	return s, err
}

func (c *testCollection) Find(ctx context.Context, q interface{}, opts *options.FindOptions) (Cursor, error) {
	j, err := json.Marshal(q)

	if err != nil {
		return &testCursor{}, nil
	}

	h := murmur3.New64()
	h.Write(j)

	colBytes := c.queries[string(h.Sum(nil))]

	var col []*json.RawMessage
	err = json.Unmarshal(*colBytes, &col)

	return &testCursor{documents: col, blob: colBytes}, err
}

func (c *testCollection) FindOne(ctx context.Context, q interface{}, opts *options.FindOneOptions) SingleResult {
	j, err := json.Marshal(q)

	if err != nil {
		return &testSingleResult{err: err}
	}

	h := murmur3.New64()
	h.Write(j)

	colBytes := c.queries[string(h.Sum(nil))]

	return &testSingleResult{
		err:         err,
		resultBytes: colBytes,
	}
}

type testCursor struct {
	target    string
	blob      *[]byte
	index     int
	documents []*json.RawMessage
}

func (c *testCursor) Blob() *[]byte {
	return c.blob
}

func (c *testCursor) All(ctx context.Context, dest interface{}) error {
	return json.Unmarshal(*c.blob, dest)
}

func (c *testCursor) Decode(target interface{}) error {
	return nil
}

func (c *testCursor) Next(ctx context.Context) bool {
	var hasNext bool

	// TODO: should probably mutex lock this
	if c.index+1 != len(c.documents) {
		hasNext = true
		c.index = c.index + 1
	}

	return hasNext
}

func (c *testCursor) Err() error {
	return nil
}

type testSingleResult struct {
	resultBytes *[]byte
	err         error
}

func (r *testSingleResult) Err() error {
	return r.err
}

func (r *testSingleResult) Decode(ref interface{}) error {
	return json.Unmarshal(*r.resultBytes, ref)
}

func (r *testSingleResult) DecodeBytes() ([]byte, error) {
	return *r.resultBytes, r.err
}
