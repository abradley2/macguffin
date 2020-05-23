package articles

import (
	"bytes"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
	"go.mongodb.org/mongo-driver/bson"
)

func TestCreateArticle(t *testing.T) {
	const (
		testClientToken = "test-client-token"
		testUserID      = "test-user-id"
	)
	w := httptest.NewRecorder()

	db := &database.TestDatabase{}
	tokensCollection := &database.TestCollection{}
	articlesCollection := &database.TestCollection{}
	usersCollection := &database.TestCollection{}

	tokenData := token.UserTokenData{
		ClientToken: testClientToken,
		UserID:      testUserID,
	}

	tokenJs, err := json.Marshal(tokenData)

	if err != nil {
		t.Errorf("Could not create token fixture: %v", err)
	}

	userData := token.UserData{
		UserID: testUserID,
	}

	userJs, err := json.Marshal(userData)

	if err != nil {
		t.Errorf("Could not create user fixture: %v", err)
	}

	usersCollection.HashQuery(
		bson.M{
			"userID": bson.M{"$eq": testUserID},
		},
		userJs,
	)

	tokensCollection.HashQuery(
		bson.M{
			"clientToken": bson.M{"$eq": testClientToken},
		},
		tokenJs,
	)

	bod := createArticleBody{
		ItemTitle:   "some random article",
		Thumbnail:   "img.jpg",
		Content:     "markdown content goes here",
		ArticleType: "macguffins",
	}

	bodJs, _ := json.Marshal(bod)

	r, _ := http.NewRequest(http.MethodGet, "", bytes.NewBuffer(bodJs))
	r.Header.Set("Authorization", testClientToken)

	p := CreateArticleParams{
		Logger:            log.New(os.Stderr, "", log.LstdFlags),
		TokensCollection:  tokensCollection,
		ArticleCollection: articlesCollection,
		UsersCollection:   usersCollection,
	}

	p.FromRequest(r, db)

	HandleCreateArticle(
		context.Background(),
		w,
		p,
	)

	if w.Code != http.StatusOK {
		t.Errorf("HandleCreateArticle did not give OK status code, got: %d", w.Code)
	}
}
