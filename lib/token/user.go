package token

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"

	"github.com/pkg/errors"
)

type ghUserInfo struct {
	ID *int `json:"id"`
}

func retrieveUser(ctx context.Context, logger *log.Logger, authToken string) (string, error) {
	var user string
	var err error

	req, err := http.NewRequest(http.MethodGet, "https://api.github.com/user", nil)

	req.Header.Add("Authorization", fmt.Sprintf("token %s", authToken))

	if err != nil {
		return user, err
	}

	res, err := client.Do(req)

	if err != nil {
		return user, errors.Wrap(err, "Error performing gh request to retrieve user")
	}

	resContent, err := ioutil.ReadAll(
		io.LimitReader(res.Body, 50000),
	)

	if err != nil {
		return user, errors.Wrap(err, "Error reading gh response body to retrieve user")
	}

	if res.StatusCode >= 300 {
		return user, fmt.Errorf("Unexpected status code retrieving github user: %d \n %s", res.StatusCode, resContent)
	}

	ui := ghUserInfo{}
	err = json.Unmarshal(resContent, &ui)

	if err != nil {
		return user, errors.Wrap(err, "Error decoding github user info")
	}

	if ui.ID == nil {
		return user, errors.Wrap(err, "Failed to retrieve user id from github user info")
	}

	return strconv.Itoa(*ui.ID), err
}
