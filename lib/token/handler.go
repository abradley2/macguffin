package token

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/request"
)

type reqBody struct {
	Code *string `json:"code"`
}

// HandleFunc returns on oauth token from github
func HandleFunc(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	logger := ctx.Value(request.LoggerKey).(*log.Logger)

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method not allowed"))
		return
	}

	bodyContent, err := ioutil.ReadAll(
		io.LimitReader(r.Body, 50000),
	)

	if err != nil {
		logger.Printf("Failed to read request body %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	var body reqBody
	json.Unmarshal(bodyContent, &body)

	if body.Code == nil {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("Missing Code parameter"))
		return
	}

	tokenRes, err := retrieveGithubToken(ctx, logger, *body.Code)

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
		accessToken, err := storeToken(r.Context(), tokenRes, user, logger)

		if err != nil {
			w.WriteHeader(http.StatusInternalServerError)
			w.Write([]byte("Internal server error"))
			return
		}

		w.WriteHeader(http.StatusOK)
		w.Write([]byte(fmt.Sprintf(`{"access_token": "%s"}`, accessToken)))
	}
}
