package articles

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/database"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/pkg/errors"
)

// GetArticleListParams _
type GetArticleListParams struct {
	Logger            *log.Logger
	TokensCollection  database.Collection
	ArticleCollection database.Collection
	UsersCollection   database.Collection

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
func (params *GetArticleListParams) FromRequest(r *http.Request, db database.Database) error {
	var err error
	q := r.URL.Query()
	params.artType = q.Get("type")
	params.creator = q.Get("creator")
	params.clientToken = r.Header.Get("Authorization")

	if params.artType == "" {
		err = fmt.Errorf("Missing required parameter query.type")
		return err
	}

	articles, err := getArticleCollection(params.artType, db)

	params.ArticleCollection = articles

	return err
}

// HandleGetArticleList return the articles we want to display opn an agent's initial dashboard
func HandleGetArticleList(ctx context.Context, w http.ResponseWriter, params GetArticleListParams) {
	logger := params.Logger

	var userID string
	if params.clientToken != "" {
		userData, err := token.GetLoggedInUser(
			ctx,
			params.clientToken,
			token.GetLoggedInUserParams{
				Tokens: params.TokensCollection,
				Users:  params.UsersCollection,
			},
		)

		if err != nil {
			logger.Printf("Error retrieving token: %v", err)
			w.WriteHeader(http.StatusUnauthorized)
			w.Write([]byte("Invalid Authorization token"))
			return
		}

		userID = userData.UserID
	}

	js, err := getArticlesJSON(
		ctx,
		params.ArticleCollection,
		getArticlesJSONOptions{
			articleType: params.artType,
			creator:     params.creator,
			userID:      userID,
		})

	if err != nil {
		logger.Printf("Failed reading articles from db via getArticlesJSON: %v", err)
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
	Logger            *log.Logger
	TokensCollection  database.Collection
	ArticleCollection database.Collection
	UsersCollection   database.Collection

	// clientToken: headers.Authorization - optional
	// token of the user who is creating the article
	clientToken string

	// body - required
	// the article to be created, without
	body createArticleBody
}

// FromRequest get CreateArticleParams from an http.Request
func (params *CreateArticleParams) FromRequest(r *http.Request, db database.Database) error {
	params.clientToken = r.Header.Get("Authorization")

	if params.clientToken == "" {
		return fmt.Errorf("Missing required parameter: headers.Authorization")
	}

	bodyContent, err := ioutil.ReadAll(io.LimitReader(r.Body, 50000))

	if err != nil {
		return errors.Wrap(err, "Could not read request body")
	}

	err = json.Unmarshal(bodyContent, &params.body)

	if err != nil {
		return err
	}

	if params.ArticleCollection == nil {
		articles, err := getArticleCollection(params.body.ArticleType, db)

		params.ArticleCollection = articles

		return err
	}

	return err
}

// HandleCreateArticle creates a new article and adds it to the db
func HandleCreateArticle(ctx context.Context, w http.ResponseWriter, params CreateArticleParams) {
	logger := params.Logger

	body := params.body

	reqBodyArticle := article{
		ItemTitle:   body.ItemTitle,
		ArticleType: body.ArticleType,
		Content:     body.Content,
		Thumbnail:   body.Thumbnail,
	}

	createdID, err := createArticle(
		ctx,
		params.clientToken,
		reqBodyArticle,
		createArticleParams{
			tokens:   params.TokensCollection,
			articles: params.ArticleCollection,
			users:    params.UsersCollection,
		},
	)

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
