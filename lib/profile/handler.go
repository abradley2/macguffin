package profile

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/abradley2/macguffin/lib/token"
)

// GetProfileParams _
type GetProfileParams struct {
	Logger *log.Logger
	// clientToken: Header.Authorization - required
	clientToken string
}

// FromRequest populate GetProfileParams from an http.Request
func (params GetProfileParams) FromRequest(r *http.Request) error {
	var err error

	params.clientToken = r.Header.Get("Authorization")

	if params.clientToken == "" {
		err = fmt.Errorf("Missing clientToken in Headers.Authorization")
	}

	return err
}

// HandleGetProfile retrieves the profile for an agent, which is their stats data
func HandleGetProfile(ctx context.Context, w http.ResponseWriter, params GetProfileParams) {
	logger := params.Logger

	userData, err := token.GetLoggedInUser(ctx, params.clientToken)

	if err != nil {
		if err == token.ErrTokenExpired {
			w.WriteHeader(http.StatusForbidden)
			return
		}
		logger.Printf("Could not get logged in user when fetching profile: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	usrJSON, err := getUserProfileJSON(ctx, userData)

	if err != nil {
		logger.Printf("Could not get user profile from logged in user: %v", err)
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte("Internal server error"))
		return
	}

	w.WriteHeader(http.StatusOK)
	w.Write(usrJSON)
}
