package request

import (
	"log"
	"os"

	"github.com/lucsky/cuid"
)

type loggerKey struct{}

// LoggerKey key to retrieve the logger from request context
var LoggerKey = loggerKey{}

// NewRID generate a cuid for a client request
func NewRID() string {
	return cuid.New() + " "
}

// NewLogger create a logger for a client request
func NewLogger() *log.Logger {
	return log.New(os.Stderr, NewRID(), log.LstdFlags)
}
