package token

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	"crypto/sha256"

	"github.com/lucsky/cuid"

	"github.com/abradley2/macguffin/lib/env"
	"github.com/abradley2/macguffin/lib/request"
)

const ghURL = "https://github.com/login/oauth/access_token"

var client = http.Client{
	Timeout: 5 * time.Second,
}

type reqBody struct {
	Code *string `json:"code"`
}

type ghResBody struct {
	AccessToken *string `json:"access_token"`
}

// HandleFunc returns on oauth token from github
func HandleFunc(w http.ResponseWriter, r *http.Request) {
	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

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

	ghReq, err := http.NewRequest(
		http.MethodPost,
		fmt.Sprintf(
			"%s?client_id=%s&client_secret=%s&code=%s",
			ghURL,
			env.GHClientID,
			env.GHClientSecret,
			*body.Code,
		),
		nil,
	)

	ghReq.Header.Set("Accept", "application/json")

	if err != nil {
		logger.Printf("Error creating token request: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	ghRes, err := client.Do(ghReq)

	if err != nil {
		logger.Printf("Error sending token request: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	ghResContent, err := ioutil.ReadAll(
		io.LimitReader(ghRes.Body, 50000),
	)

	if err != nil {
		logger.Printf("Error reading github response: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	if ghRes.StatusCode >= 300 {
		logger.Printf(
			"Unexpected status code %d: \nresponse: %s",
			ghRes.StatusCode,
			ghResContent,
		)
		w.WriteHeader(ghRes.StatusCode)
		w.Write([]byte("Unexpected status code during authorization"))
		return
	}

	grb := ghResBody{}
	err = json.Unmarshal(ghResContent, &grb)

	if err != nil {
		logger.Printf(
			"Failed to read body from github response: %v",
			err,
		)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	if grb.AccessToken == nil {
		logger.Printf(
			"Failed to retrieve access token from github response",
		)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	user, err := retrieveUser(logger, *grb.AccessToken)

	if err != nil {
		logger.Printf("Error retrieving gh user: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	clientToken := fmt.Sprintf("%s*%s", cuid.New(), user)

	h := sha256.New()
	h.Write([]byte(clientToken))

	enc := base64.StdEncoding.EncodeToString(h.Sum(nil))

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(fmt.Sprintf(`{"access_token": "%s"}`, enc)))

	return
}

type ghUserInfo struct {
	ID *int `json:"id"`
}

func retrieveUser(logger *log.Logger, authToken string) (string, error) {
	var user string
	var err error

	req, err := http.NewRequest(http.MethodGet, "https://api.github.com/user", nil)

	req.Header.Add("Authorization", fmt.Sprintf("token %s", authToken))

	if err != nil {
		return user, err
	}

	res, err := client.Do(req)

	if err != nil {
		logger.Printf("Error performing gh request to retrieve user: %v", err)
		return user, err
	}

	resContent, err := ioutil.ReadAll(
		io.LimitReader(res.Body, 50000),
	)

	if err != nil {
		logger.Printf("Error reading gh response body to retrieve user: %v", err)
		return user, err
	}

	if res.StatusCode >= 300 {
		return user, fmt.Errorf("Unexpected status code retrieving github user: %d", res.StatusCode)
	}

	ui := ghUserInfo{}
	err = json.Unmarshal(resContent, &ui)

	if err != nil {
		logger.Printf("Error decoding github user info: %v", err)
		return user, err
	}

	if ui.ID == nil {
		err = fmt.Errorf("Failed to retrieve user id from github user info")
		logger.Printf(err.Error())
		return user, err
	}

	return string(*ui.ID), err
}
