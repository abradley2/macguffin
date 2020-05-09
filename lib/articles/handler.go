package articles

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/request"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/pkg/errors"
)

// GetArticleListParams _
type GetArticleListParams struct {
	// artType: query.type - required
	// can be macguffins, sites, or events
	// see ArticleCollections type in lib
	artType string

	// clientToken: headers.Authorization - optional
	// needed to determine if the requestor is an admin
	// who can see unapproved articles
	clientToken string

	// creator: query.creator - optional
	// filter which articles are sent back by creator's userID
	creator string
}

// FromRequest create GetArticleListParams from an http.Request
func (params *GetArticleListParams) FromRequest(r *http.Request) error {
	var err error
	q := r.URL.Query()
	params.artType = q.Get("type")
	params.creator = q.Get("creator")
	params.clientToken = r.Header.Get("Authorization")

	if params.artType == "" {
		err = fmt.Errorf("Missing required parameter query.type")
	}

	return err
}

// HandleGetArticleList return the articles we want to display opn an agent's initial dashboard
func HandleGetArticleList(ctx context.Context, w http.ResponseWriter, params GetArticleListParams) {
	logger := ctx.Value(request.LoggerKey).(*log.Logger)

	var userID string
	if params.clientToken != "" {
		userData, err := token.GetLoggedInUser(ctx, params.clientToken)

		if err != nil {
			logger.Printf("Error retrieving token: %v", err)
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte("Invalid Authorization token"))
			return
		}

		userID = userData.UserID
	}

	js, err := getArticlesJSON(ctx, getArticlesJSONOptions{
		articleType: params.artType,
		creator:     params.creator,
		userID:      userID,
	})

	if err != nil {
		logger.Printf("Failed reading articles from db via getArticlesJSON:\n %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(js)
}

type createArticleBody struct {
	ItemTitle   string `json:"itemTitle"`
	Thumbnail   string `json:"string,omitempty"`
	Content     string `json:"content"`
	ArticleType string `json:"articleType"`
}

// CreateArticleParams _
type CreateArticleParams struct {
	// clientToken: headers.Authorization - optional
	// token of the user who is creating the article
	clientToken string

	// body - required
	// the article to be created, without
	body createArticleBody
}

// FromRequest get CreateArticleParams from an http.Request
func (params *CreateArticleParams) FromRequest(r *http.Request) error {
	params.clientToken = r.Header.Get("Authorization")

	if params.clientToken == "" {
		return fmt.Errorf("Missing required parameter: headers.Authorization")
	}

	bodyContent, err := ioutil.ReadAll(io.LimitReader(r.Body, 50000))

	if err != nil {
		return errors.Wrap(err, "Could not read request body")
	}

	return json.Unmarshal(bodyContent, &params.body)
}

// HandleCreateArticle creates a new article and adds it to the db
func HandleCreateArticle(ctx context.Context, w http.ResponseWriter, params CreateArticleParams) {
	logger := ctx.Value(request.LoggerKey).(*log.Logger)

	body := params.body

	reqBodyArticle := article{
		ItemTitle:   body.ItemTitle,
		ArticleType: body.ArticleType,
		Content:     body.Content,
		Thumbnail:   body.Thumbnail,
	}

	createdID, err := createArticle(ctx, params.clientToken, reqBodyArticle)

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
