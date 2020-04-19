package token

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/abradley2/macguffin/lib/request"
)

const ghURL = "https://github.com/login/oauth/access_token"

var client = http.Client{
	Timeout: 5 * time.Second,
}

type reqBody struct {
	Code *string `json:"code"`
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
		logger.SetOutput(os.Stderr)
		logger.Printf("Failed to read request body %e", err)
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
			"%s?client_id=c03a348dc743e9a1edc6&client_secret=%s&code=%s",
			ghURL,
			os.Getenv("GH_CLIENT_SECRET"),
			*body.Code,
		),
		nil,
	)

	ghReq.Header.Set("Accept", "application/json")

	if err != nil {
		logger.SetOutput(os.Stderr)
		logger.Printf("Error creating token request: %e", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	ghRes, err := client.Do(ghReq)

	if err != nil {
		logger.SetOutput(os.Stderr)
		logger.Printf("Error sending token request: %e", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	ghResContent, err := ioutil.ReadAll(
		io.LimitReader(ghRes.Body, 50000),
	)

	if err != nil {
		logger.SetOutput(os.Stderr)
		logger.Printf("Error reading github response: %e", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	if ghRes.StatusCode >= 300 {
		logger.SetOutput(os.Stderr)
		logger.Printf(
			"Unexpected status code %d: \nresponse: %s",
			ghRes.StatusCode,
			ghResContent,
		)
		w.WriteHeader(ghRes.StatusCode)
		w.Write([]byte("Unexpected status code during authorization"))
		return
	}

	w.WriteHeader(ghRes.StatusCode)
	w.Write(ghResContent)
	return
}
