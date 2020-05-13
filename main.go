package main

import (
	"context"
	"encoding/json"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"github.com/abradley2/macguffin/lib/articles"
	"github.com/abradley2/macguffin/lib/profile"
	"github.com/abradley2/macguffin/lib/request"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/rs/cors"
)

var logger = log.New(os.Stderr, "main.go ", log.LstdFlags)

type server struct {
	multiplexer *http.ServeMux
}

func (s server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx := context.WithValue(r.Context(), request.LoggerKey, request.NewLogger())

	s.multiplexer.ServeHTTP(w, r.WithContext(ctx))
}

type handler = func(w http.ResponseWriter, r *http.Request)

func setupRoute(mux *http.ServeMux, method string, url string, h handler) {
	mux.HandleFunc(url, func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			w.WriteHeader(http.StatusMethodNotAllowed)
			w.Write([]byte("Method not allowed"))
			return
		}
		h(w, r)
	})
}

func (s server) initRoutes() {
	mux := s.multiplexer

	mux.HandleFunc("/", index)
	mux.HandleFunc("/log", clientLog)

	setupRoute(mux, http.MethodGet, "/profile", func(w http.ResponseWriter, r *http.Request) {
		logger := request.NewLogger()

		params := profile.GetProfileParams{Logger: logger}
		err := params.FromRequest(r)

		if err != nil {
			logger.Printf("Failed to initialze params from request to /profile\n%v", err)
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte(err.Error()))
			return
		}

		profile.HandleGetProfile(r.Context(), w, params)
	})

	setupRoute(mux, http.MethodPost, "/token", func(w http.ResponseWriter, r *http.Request) {
		logger := request.NewLogger()

		params := token.GetTokenParams{Logger: logger}
		err := params.FromRequest(r)

		if err != nil {
			logger.Printf("Failed to initialze params from request for /token\n%v", err)
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte(err.Error()))
			return
		}

		token.HandleGetToken(r.Context(), w, params)
	})

	setupRoute(mux, http.MethodGet, "/articles", func(w http.ResponseWriter, r *http.Request) {
		logger := request.NewLogger()

		params := articles.GetArticleListParams{Logger: logger}
		err := params.FromRequest(r)

		if err != nil {
			logger.Printf("Failed to initialize params from request for /articles\n%v", err)
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte(err.Error()))
			return
		}

		articles.HandleGetArticleList(r.Context(), w, params)
	})

	setupRoute(mux, http.MethodPost, "/create-article", func(w http.ResponseWriter, r *http.Request) {
		logger := request.NewLogger()

		params := articles.CreateArticleParams{Logger: logger}
		err := params.FromRequest(r)

		if err != nil {
			logger.Printf("Failed to initialize params from request for /create-article\n%v", err)
			w.WriteHeader(http.StatusBadRequest)
			w.Write([]byte(err.Error()))
			return
		}

		articles.HandleCreateArticle(r.Context(), w, params)
	})
}

func main() {
	err := run()

	if err != nil {
		logger.Printf("Error running server: %v", err)
		os.Exit(1)
	}
}

func run() error {
	mux := http.NewServeMux()
	s := server{mux}

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	})

	s.initRoutes()

	return http.ListenAndServe(":8080", c.Handler(s))
}

func index(w http.ResponseWriter, r *http.Request) {
	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusMethodNotAllowed)
		w.Write([]byte("Method not allowed"))
		return
	}

	logger.Print("Sending index")

	w.WriteHeader(http.StatusOK)
	w.Write([]byte("Hello World!"))
}

type clientLogBody struct {
	Msg *string `json:"logMessage"`
}

func clientLog(w http.ResponseWriter, r *http.Request) {
	logger := r.Context().Value(request.LoggerKey).(*log.Logger)

	if r.Method != http.MethodPost {
		logger.Printf("Method not allowed")
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var body clientLogBody

	b, err := ioutil.ReadAll(
		io.LimitReader(r.Body, 50000),
	)

	if err != nil {
		logger.Printf("Failed to read client error log: %v", err)
		w.WriteHeader(http.StatusUnprocessableEntity)
		return
	}

	err = json.Unmarshal(b, &body)

	if err != nil || body.Msg == nil {
		logger.Printf("Failed")
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	logger.Printf(*body.Msg)
	w.WriteHeader(http.StatusAccepted)
}
