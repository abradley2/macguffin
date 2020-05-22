package token

import (
	"context"
	"encoding/json"
	"testing"

	"github.com/abradley2/macguffin/lib/database"
	"go.mongodb.org/mongo-driver/mongo"
)

type tokenTestCollection struct {
	testCollection database.Collection
}

func TestCreateUser(t *testing.T) {
	const testGhUserID = "$$testGhUserID"

	tokensCollection := &database.TestCollection{}
	usersCollection := &database.TestCollection{}

	_, err := storeToken(
		context.Background(),
		githubAccessTokenResponse{
			AccessToken: "whatever",
		},
		testGhUserID,
		storeTokenParams{
			tokensCollection: tokensCollection,
			agentsCollection: usersCollection,
		},
	)

	// our mock collections do not really insert, so fail
	// if we get an error but not if it's ErrNoDocuments
	if err != nil && err != mongo.ErrNoDocuments {
		t.Errorf("Failed to store token: %v", err)
	}

	ud := UserData{}
	err = json.Unmarshal(usersCollection.LastInsert, &ud)

	if err != nil {
		t.Errorf("Failed to unmarshal usersCollection lastinsert into user data: %v", err)
	}

	if ud.UserID != testGhUserID {
		t.Errorf(
			"Did not find github user id in users collection after storeToken was called: %s != %s",
			ud.UserID,
			testGhUserID,
		)
	}
}
