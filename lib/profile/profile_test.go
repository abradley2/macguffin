package profile

import (
	"context"
	"encoding/json"
	"io/ioutil"
	"log"
	"os"
	"testing"

	"net/http/httptest"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
	"go.mongodb.org/mongo-driver/bson"
)

func TestGetArticles(t *testing.T) {
	tokenCollection := &database.TestCollection{}
	userCollection := &database.TestCollection{}
	profileCollection := &database.TestCollection{}

	const testUserStrength = 10
	const testRequestToken = "test-request-token"
	const testUserID = "test-user-id"
	const testPublicAgentID = "test-public-agent-id"

	tokenJSON, _ := json.Marshal(token.UserTokenData{
		UserID:      testUserID,
		ClientToken: testRequestToken,
	})

	tokenCollection.HashQuery(
		bson.M{
			"clientToken": bson.M{
				"$eq": testRequestToken,
			},
		},
		tokenJSON,
	)

	userJSON, _ := json.Marshal(token.UserData{
		UserID: testUserID,
	})

	userCollection.HashQuery(
		bson.M{
			"userID": bson.M{
				"$eq": testUserID,
			},
		},
		userJSON,
	)

	profileJSON, _ := json.Marshal(userProfile{
		UserID:        testUserID,
		PublicAgentID: testPublicAgentID,
		Strength:      testUserStrength,
	})

	profileCollection.HashQuery(
		bson.M{
			"userID": bson.M{
				"$eq": testUserID,
			},
		},
		profileJSON,
	)

	w := httptest.NewRecorder()
	p := GetProfileParams{
		Logger:            log.New(os.Stderr, "", log.LstdFlags),
		clientToken:       testRequestToken,
		ProfileCollection: profileCollection,
		TokensCollection:  tokenCollection,
		UsersCollection:   userCollection,
	}
	HandleGetProfile(context.Background(), w, p)

	b, _ := ioutil.ReadAll(w.Body)
	prof := userProfile{}
	err := json.Unmarshal(b, &prof)

	if err != nil {
		t.Errorf("Could not unmarshal response json: %v", err)
	}

	if prof.Strength != testUserStrength {
		t.Errorf("Expected %d user strength but got %d", testUserStrength, prof.Strength)
	}
}
