package database

import "go.mongodb.org/mongo-driver/mongo"

// SingleResult wrapper of mongo.SingleResult
type SingleResult interface {
	Decode(interface{}) error
	DecodeBytes() ([]byte, error)
	Err() error
}

type mongoSingleResult struct {
	result *mongo.SingleResult
}

func (r *mongoSingleResult) Decode(ref interface{}) error {
	return r.result.Decode(ref)
}

func (r *mongoSingleResult) DecodeBytes() ([]byte, error) {
	return r.result.DecodeBytes()
}

func (r *mongoSingleResult) Err() error {
	return r.result.Err()
}
