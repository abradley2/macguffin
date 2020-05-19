package profile

import (
	"encoding/json"
	"testing"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
)

func TestGetArticles(t *testing.T) {
	tokens := &database.TestCollection{}
	users := &database.TestCollection{}

	var testRequestToken = "test-request-token"
	var testUserID = "test-user-id"
	var testPublicAgentID = "test-public-agent-id"

	userProfJSON, _ := json.Marshal(userProfile{
		UserID: testUserID,
		PublicAgentID: testPublicAgentID,
	})

	users.HashQuery(
		bson.M{
			"userID": bson.M{
				"$eq": testUserID,
			},
		},
		userProfJSON,
	)

	userTokenJSON, _ := json.Marshal(token.UserTokenData{
		UserID: testUserID,
		ClientToken: testRequestToken,
	})

	tokens.HashQuery((
		bson.M{
			"clientToken": bson.M{
				"$eq": testRequestToken,
			},
		},
		useruserTokenJSON,
	))


}
