package articles

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/request"
)

// HandleGetArticleList return the articles we want to display opn an agent's initial dashboard
func HandleGetArticleList(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method not allowed"))
		return
	}

	q := r.URL.Query()

	artType := q.Get("type")

	if artType == "" {
		w.WriteHeader(http.StatusBadRequest)
		w.Write([]byte("missing required query parameter 'type'"))
		return
	}

	js, err := getArticlesJSON(ctx, getArticlesJSONOptions{
		articleType: artType,
		creator:     q.Get("creator"),
	})

	if err != nil {
		logger.Printf("Failed to get articles json: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(js)
}

// HandleCreateArticle creates a new article and adds it to the db
func HandleCreateArticle(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method not allowed"))
		return
	}

	clientToken := r.Header.Get("Authorization")

	if clientToken == "" {
		w.WriteHeader(http.StatusForbidden)
		w.Write([]byte("Missing Authorization header"))
		return
	}

	reqBodyArticle := article{}

	bodyContent, err := ioutil.ReadAll(
		io.LimitReader(r.Body, 50000),
	)

	if err != nil {
		logger.Printf("Error reading body content for create article endpoint: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	err = json.Unmarshal(bodyContent, &reqBodyArticle)

	if err != nil {
		logger.Printf("Error decoding create article body content: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	createdID, err := createArticle(ctx, clientToken, reqBodyArticle)

	if err != nil {
		logger.Printf("Error calling createArticle: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write([]byte(
		fmt.Sprintf(`{ "createdID": "%s" }`, createdID),
	))
}
