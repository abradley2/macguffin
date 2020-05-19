package token

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/pkg/errors"
)

type getTokenBody struct {
	Code string `json:"code"`
}

// GetTokenParams _
type GetTokenParams struct {
	Logger          *log.Logger
	TokenCollection database.Collection
	UserCollection  database.Collection

	// body - required
	// simple json body with a "code" field for github oauth
	body getTokenBody
}

// FromRequest build GetTokenParams from an http.Request
func (params *GetTokenParams) FromRequest(r *http.Request) error {
	bodyContent, err := ioutil.ReadAll(
		io.LimitReader(r.Body, 50000),
	)

	if err != nil {
		return errors.Wrap(err, "Failed to read bodyContent from request")
	}

	err = json.Unmarshal(bodyContent, &params.body)

	if err != nil {
		return errors.Wrap(err, "Failed to unmarshal body json")
	}

	if params.body.Code == "" {
		return fmt.Errorf("Body missing required parameter: 'code'")
	}

	return err
}

// HandleGetToken returns on oauth token from github
func HandleGetToken(ctx context.Context, w http.ResponseWriter, params GetTokenParams) {
	logger := params.Logger

	tokenRes, err := retrieveGithubToken(ctx, logger, params.body.Code)

	if err != nil {
		logger.Printf("Error retrieving access token for gh user: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
	}

	user, err := retrieveUser(ctx, logger, tokenRes.AccessToken)

	if err != nil {
		logger.Printf("Error retrieving gh user: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	// don't store the token if the request was cancelled
	select {
	case <-ctx.Done():
		return

	default:
		accessToken, err := storeToken(
			ctx,
			tokenRes,
			user,
			storeTokenParams{
				tokensCollection: params.TokenCollection,
				agentsCollection: params.UserCollection,
			},
		)

		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Internal server error"))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{"access_token": "%s"}`, accessToken)))
	}
}
