package articles

import (
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

	js, err := getArticlesJSON(ctx, artType)

	if err != nil {
		logger.Printf("Failed to get articles json: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(js)
}

func HandleCreateArticle(w http.ResponseWriter, r *http.Request) {

}
