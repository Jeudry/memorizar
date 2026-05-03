package httpapi

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/Jeudry/memorizar/backend/internal/social/application"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

type Server struct {
	service *application.Service
	mux     *http.ServeMux
}

func NewServer(service *application.Service) *Server {
	server := &Server{
		service: service,
		mux:     http.NewServeMux(),
	}
	server.registerRoutes()
	return server
}

func (s *Server) Handler() http.Handler {
	return withCORS(s.mux)
}

func (s *Server) registerRoutes() {
	s.mux.HandleFunc("/healthz", s.handleHealth)
	s.mux.HandleFunc("/v1/auth/social/login", s.handleSocialLogin)
	s.mux.HandleFunc("/v1/auth/me", s.withAuth(s.handleMe))
	s.mux.HandleFunc("/v1/social/friends", s.withAuth(s.handleFriends))
	s.mux.HandleFunc("/v1/social/suggestions", s.withAuth(s.handleSuggestions))
	s.mux.HandleFunc("/v1/social/friends/request", s.withAuth(s.handleFriendRequest))
	s.mux.HandleFunc("/v1/social/friends/accept", s.withAuth(s.handleFriendAccept))
	s.mux.HandleFunc("/v1/social/feed", s.withAuth(s.handleFeed))
	s.mux.HandleFunc("/v1/social/feed/reactions", s.withAuth(s.handleFeedReaction))
	s.mux.HandleFunc("/v1/social/feed/comments", s.withAuth(s.handleFeedComment))
	s.mux.HandleFunc("/v1/social/achievements", s.withAuth(s.handleCreateAchievement))
	s.mux.HandleFunc("/v1/social/activities", s.withAuth(s.handleCreateActivity))
	s.mux.HandleFunc("/v1/social/shares", s.withAuth(s.handleShares))
	s.mux.HandleFunc("/v1/sync/progress", s.withAuth(s.handleSyncProgress))
}

func (s *Server) withAuth(next func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "))
		if token == "" {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "missing bearer token"})
			return
		}
		user, err := s.service.Authenticate(token)
		if err != nil || user == nil {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid session"})
			return
		}
		next(w, r, user.ID)
	}
}

func (s *Server) handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status":  "ok",
		"service": "memorizar-api",
	})
}

func (s *Server) handleSocialLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var input application.SocialLoginInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	output, err := s.service.SocialLogin(input)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, application.ErrInvalidProvider) {
			status = http.StatusUnprocessableEntity
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, output)
}

func (s *Server) handleMe(w http.ResponseWriter, _ *http.Request, userID string) {
	user, err := s.service.GetUser(userID)
	if err != nil || user == nil {
		writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "invalid session"})
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func (s *Server) handleFriends(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	friends, err := s.service.ListFriends(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	pending, err := s.service.ListPendingRequests(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"friends":         friends,
		"pendingRequests": pending,
	})
}

func (s *Server) handleSuggestions(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	users, err := s.service.ListSuggestedPeople(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"users": users})
}

func (s *Server) handleFriendRequest(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		FriendUserID string `json:"friendUserId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	friendship, err := s.service.RequestFriend(userID, strings.TrimSpace(body.FriendUserID))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, friendship)
}

func (s *Server) handleFriendAccept(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		FriendshipID string `json:"friendshipId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	friendship, err := s.service.AcceptFriend(userID, strings.TrimSpace(body.FriendshipID))
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, application.ErrFriendshipForbidden) {
			status = http.StatusForbidden
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, friendship)
}

func (s *Server) handleFeed(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	feed, err := s.service.BuildFeed(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"entries": feed})
}

func (s *Server) handleFeedReaction(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		EntryID string `json:"entryId"`
		Emoji   string `json:"emoji"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	reaction, err := s.service.AddReaction(userID, strings.TrimSpace(body.EntryID), strings.TrimSpace(body.Emoji))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, reaction)
}

func (s *Server) handleFeedComment(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		EntryID string `json:"entryId"`
		Body    string `json:"body"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	comment, err := s.service.AddComment(userID, strings.TrimSpace(body.EntryID), strings.TrimSpace(body.Body))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, comment)
}

func (s *Server) handleCreateAchievement(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		Code        string `json:"code"`
		Title       string `json:"title"`
		Description string `json:"description"`
		DeckName    string `json:"deckName"`
		Emoji       string `json:"emoji"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	achievement, err := s.service.RecordAchievement(
		userID,
		body.Code,
		body.Title,
		body.Description,
		body.DeckName,
		body.Emoji,
	)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, achievement)
}

func (s *Server) handleCreateActivity(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		Code        string `json:"code"`
		Title       string `json:"title"`
		Description string `json:"description"`
		DeckName    string `json:"deckName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	activity, err := s.service.RecordActivity(userID, body.Code, body.Title, body.Description, body.DeckName)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, activity)
}

func (s *Server) handleShares(w http.ResponseWriter, r *http.Request, userID string) {
	switch r.Method {
	case http.MethodGet:
		shares, err := s.service.ListSharedResources(userID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"shares": shares})
	case http.MethodPost:
		var body application.ShareResourceInput
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
			return
		}
		share, err := s.service.ShareResource(userID, body)
		if err != nil {
			status := http.StatusBadRequest
			if errors.Is(err, application.ErrInvalidShareKind) {
				status = http.StatusUnprocessableEntity
			}
			writeJSON(w, status, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, share)
	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
	}
}

func (s *Server) handleSyncProgress(w http.ResponseWriter, r *http.Request, userID string) {
	switch r.Method {
	case http.MethodGet:
		snapshot, err := s.service.GetLatestProgressSnapshot(userID)
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		if snapshot == nil {
			writeJSON(w, http.StatusOK, map[string]any{"snapshot": nil})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"snapshot": snapshot})
	case http.MethodPost:
		var body application.ProgressSyncInput
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
			return
		}
		snapshot, err := s.service.SaveProgressSnapshot(userID, body)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, snapshot)
	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
	}
}

var _ = domain.ProviderGoogle
