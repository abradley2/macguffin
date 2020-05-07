package token

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"github.com/abradley2/macguffin/lib/env"
	"github.com/pkg/errors"
)

const ghURL = "https://github.com/login/oauth/access_token"

var client = http.Client{
	Timeout: 5 * time.Second,
}

type githubAccessTokenResponse struct {
	AccessToken string `json:"access_token"`
}

func retrieveGithubToken(ctx context.Context, logger *log.Logger, code string) (githubAccessTokenResponse, error) {
	var (
		tokenRes githubAccessTokenResponse
		err      error
	)

	ghReq, err := http.NewRequest(
		http.MethodPost,
		fmt.Sprintf(
			"%s?client_id=%s&client_secret=%s&code=%s",
			ghURL,
			env.GHClientID,
			env.GHClientSecret,
			code,
		),
		nil,
	)

	if err != nil {
		return tokenRes, errors.Wrap(err, "Error creating gh token request")
	}

	ghReq.Header.Set("Accept", "application/json")
	ghRes, err := client.Do(ghReq)

	if err != nil {
		return tokenRes, errors.Wrap(err, "Error sending gh token request")
	}

	ghResContent, err := ioutil.ReadAll(
		io.LimitReader(ghRes.Body, 50000),
	)

	if err != nil {
		return tokenRes, errors.Wrap(err, "Error reading gh token response body")
	}

	if ghRes.StatusCode >= 300 {
		err = fmt.Errorf("Unexpected status code in gh token response: \n%d\n%s", ghRes.StatusCode, ghResContent)
		return tokenRes, err
	}

	err = json.Unmarshal(ghResContent, &tokenRes)

	if err != nil {
		return tokenRes, errors.Wrapf(err, "Could not decode gh token response content: \n%s", ghResContent)
	}

	if tokenRes.AccessToken == "" {
		return tokenRes, fmt.Errorf("Access token missing in gh token response: \n%s", ghResContent)
	}

	return tokenRes, err
}
