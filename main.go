package main

import (
	"context"
	"encoding/json"
	"io"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/articles"
	"github.com/abradley2/macguffin/lib/request"
	"github.com/abradley2/macguffin/lib/token"
	"github.com/rs/cors"
)

type server struct {
	multiplexer *http.ServeMux
}

func (s server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	ctx := context.WithValue(r.Context(), request.LoggerKey, request.NewLogger())

	s.multiplexer.ServeHTTP(w, r.WithContext(ctx))
}

func main() {
	mux := http.NewServeMux()
	s := server{mux}

	mux.HandleFunc("/", index)
	mux.HandleFunc("/log", clientLog)
	mux.HandleFunc("/token", token.HandleFunc)
	mux.HandleFunc("/articles", articles.HandleGetArticleList)

	http.ListenAndServe(":8080", cors.Default().Handler(s))
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
