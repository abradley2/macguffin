package profile

import (
	"context"
	"encoding/json"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/pkg/errors"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type userProfile struct {
	UserID        string `json:"userID" bson:"userID"`
	PublicAgentID string `json:"publicAgentID,omitempty" bson:"publicAgentID,omitempty"`
	Strength      int    `json:"strength" bson:"strength"`
	Constitution  int    `json:"constitution" bson:"constitution"`
	Dexterity     int    `json:"dexterity" bson:"dexterity"`
	Intelligence  int    `json:"intelligence" bson:"intelligence"`
	Wisdom        int    `json:"wisdom" bson:"wisdom"`
	Charisma      int    `json:"charisma" bson:"charisma"`
}

func getUserProfileJSON(
	ctx context.Context,
	profiles database.Collection,
	userData token.UserData,
) ([]byte, error) {
	var js []byte
	var err error
	var profile = userProfile{
		UserID:       userData.UserID,
		Strength:     8,
		Constitution: 8,
		Dexterity:    8,
		Intelligence: 8,
		Wisdom:       8,
		Charisma:     8,
	}

	q := bson.M{
		"userID": bson.M{
			"$eq": userData.UserID,
		},
	}

	res := profiles.FindOne(ctx, q, &options.FindOneOptions{})

	err = res.Err()

	if err == mongo.ErrNoDocuments {
		// send a default empty profile
		js, err = json.Marshal(profile)

		if err != nil {
			return js, errors.Wrapf(err, "Failed marshalling default profile into json")
		}

		return js, err
	}

	if err != nil {
		return js, errors.Wrapf(err, "Error executing findOne query in getUserProfileJSON")
	}

	return res.DecodeBytes()
}
