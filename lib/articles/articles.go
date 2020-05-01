package articles

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/request"
)

type articleList struct {
	ItemTitle string `json:"itemTitle"`
	ID        string `json:"id"`
}

// HandleGetArticleList return the articles we want to display opn an agent's initial dashboard
func HandleGetArticleList(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method not allowed"))
		return
	}

	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

	artList := []articleList{}

	res, err := json.Marshal(artList)

	if err != nil {
		logger.Printf("Failed to encoded article list to json: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(res)
}

func HandleCreateArticle(w http.ResponseWriter, r *http.Request) {

}
