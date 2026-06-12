package httpapi

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/Jeudry/memorizar/backend/internal/coop"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

type Server struct {
	service *application.Service
	coop    *coop.Hub
	mux     *http.ServeMux
}

func NewServer(service *application.Service) *Server {
	server := &Server{
		service: service,
		coop:    coop.NewHub(),
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
	s.mux.HandleFunc("/v1/auth/email/register", s.handleEmailRegister)
	s.mux.HandleFunc("/v1/auth/email/login", s.handleEmailLogin)
	s.mux.HandleFunc("/v1/auth/me", s.withAuth(s.handleMe))
	s.mux.HandleFunc("/v1/auth/profile", s.withAuth(s.handleProfile))
	s.mux.HandleFunc("/v1/auth/account", s.withAuth(s.handleAccount))
	s.mux.HandleFunc("/v1/auth/avatar", s.withAuth(s.handleAvatarUpload))
	s.mux.HandleFunc("/v1/auth/email/verify/request", s.withAuth(s.handleVerifyRequest))
	s.mux.HandleFunc("/v1/auth/email/verify/confirm", s.handleVerifyConfirm)
	s.mux.HandleFunc("/v1/auth/password/reset/request", s.handlePasswordResetRequest)
	s.mux.HandleFunc("/v1/auth/password/reset/confirm", s.handlePasswordResetConfirm)
	s.mux.HandleFunc("/avatars/", s.handleAvatarServe)
	s.mux.HandleFunc("/v1/social/friends", s.withAuth(s.handleFriends))
	s.mux.HandleFunc("/v1/social/user", s.withAuth(s.handleGetUser))
	s.mux.HandleFunc("/v1/social/suggestions", s.withAuth(s.handleSuggestions))
	s.mux.HandleFunc("/v1/social/search", s.withAuth(s.handleSearch))
	s.mux.HandleFunc("/v1/community/decks", s.withAuth(s.handleCommunitySearch))
	s.mux.HandleFunc("/v1/community/mine", s.withAuth(s.handleCommunityMine))
	s.mux.HandleFunc("/v1/community/overview", s.withAuth(s.handleCommunityOverview))
	s.mux.HandleFunc("/v1/community/reports", s.withAuth(s.handleCommunityReports))
	s.mux.HandleFunc("/v1/community/reports/resolve", s.withAuth(s.handleCommunityReportResolve))
	s.mux.HandleFunc("/v1/community/imports", s.withAuth(s.handleCommunityImport))
	// Endpoint público (sin auth) para resolver deeplinks `memorizar://deck/ID`.
	// Solo expone shares con IsPublic=true.
	s.mux.HandleFunc("/v1/public/shares/", s.handlePublicShare)
	s.mux.HandleFunc("/v1/social/friends/request", s.withAuth(s.handleFriendRequest))
	s.mux.HandleFunc("/v1/social/friends/accept", s.withAuth(s.handleFriendAccept))
	s.mux.HandleFunc("/v1/social/friends/invite/accept", s.withAuth(s.handleFriendInviteAccept))
	s.mux.HandleFunc("/v1/social/feed", s.withAuth(s.handleFeed))
	s.mux.HandleFunc("/v1/social/feed/reactions", s.withAuth(s.handleFeedReaction))
	s.mux.HandleFunc("/v1/social/feed/comments", s.withAuth(s.handleFeedComment))
	s.mux.HandleFunc("/v1/social/achievements", s.withAuth(s.handleCreateAchievement))
	s.mux.HandleFunc("/v1/social/activities", s.withAuth(s.handleCreateActivity))
	s.mux.HandleFunc("/v1/social/shares", s.withAuth(s.handleShares))
	s.mux.HandleFunc("/v1/sync/progress", s.withAuth(s.handleSyncProgress))

	// Cooperativo en tiempo real (websocket).
	s.mux.HandleFunc("/v1/coop/rooms", s.withOptionalAuth(s.handleCoopCreateRoom))
	s.mux.HandleFunc("/v1/coop/rooms/lookup", s.withOptionalAuth(s.handleCoopLookup))
	s.mux.HandleFunc("/v1/coop/rooms/public", s.withOptionalAuth(s.handleCoopListPublicRooms))
	s.mux.HandleFunc("/v1/coop/invite", s.withAuth(s.handleCoopInvite))
	s.mux.HandleFunc("/v1/coop/invites/pending", s.withAuth(s.handleCoopGetPendingInvites))
	s.mux.HandleFunc("/v1/coop/ws", s.coop.HandleWebsocket)
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

func (s *Server) withOptionalAuth(next func(http.ResponseWriter, *http.Request, string)) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		token := strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "))
		if token == "" {
			next(w, r, "")
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
	sanitized := user.Sanitize()
	writeJSON(w, http.StatusOK, sanitized)
}

func (s *Server) handleEmailRegister(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var input application.EmailRegisterInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	output, err := s.service.RegisterEmail(input)
	if err != nil {
		status := http.StatusBadRequest
		switch {
		case errors.Is(err, application.ErrEmailInUse):
			status = http.StatusConflict
		case errors.Is(err, application.ErrWeakPassword):
			status = http.StatusUnprocessableEntity
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusCreated, output)
}

func (s *Server) handleEmailLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var input application.EmailLoginInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	output, err := s.service.LoginEmail(input)
	if err != nil {
		status := http.StatusUnauthorized
		if errors.Is(err, application.ErrMissingIdentity) {
			status = http.StatusBadRequest
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, output)
}

func (s *Server) handleProfile(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPatch && r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var input application.UpdateProfileInput
	if err := json.NewDecoder(r.Body).Decode(&input); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	user, err := s.service.UpdateProfile(userID, input)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, user)
}

func (s *Server) handleAccount(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodDelete {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	if err := s.service.DeleteAccount(userID); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusNoContent, nil)
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

	friendsList := make([]map[string]any, len(friends))
	for i, f := range friends {
		friendsList[i] = map[string]any{
			"id":            f.ID,
			"email":         f.Email,
			"displayName":   f.DisplayName,
			"avatarUrl":     f.AvatarURL,
			"locale":        f.Locale,
			"emailVerified": f.EmailVerified,
			"isOnline":      s.coop.IsUserOnline(f.ID),
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"friends":         friendsList,
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

func (s *Server) handleGetUser(w http.ResponseWriter, r *http.Request, _ string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	targetID := r.URL.Query().Get("id")
	if targetID == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "missing user id"})
		return
	}
	user, err := s.service.GetUser(targetID)
	if err != nil || user == nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "user not found"})
		return
	}
	sanitized := user.Sanitize()

	// Cargar logros e insignias del usuario
	achievements, _ := s.service.ListAchievementsByUserIDs([]string{targetID})
	if achievements == nil {
		achievements = []domain.Achievement{}
	}

	// Cargar recursos compartidos públicos del usuario para contar sus mazos
	shares, _ := s.service.ListPublicSharedResourcesByUserIDs([]string{targetID})
	sharedCount := len(shares)

	writeJSON(w, http.StatusOK, map[string]any{
		"user":         sanitized,
		"achievements": achievements,
		"stats": map[string]any{
			"sharedCount":       sharedCount,
			"achievementsCount": len(achievements),
		},
	})
}

func (s *Server) handleSearch(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	query := r.URL.Query().Get("q")
	users, err := s.service.SearchPeople(userID, query)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"users": users})
}

func (s *Server) handlePublicShare(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	id := strings.TrimPrefix(r.URL.Path, "/v1/public/shares/")
	if id == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "missing share id"})
		return
	}
	share, err := s.service.FindShareByID(id)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	if share == nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "share not found"})
		return
	}
	writeJSON(w, http.StatusOK, share)
}

func (s *Server) handleCommunitySearch(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	query := r.URL.Query().Get("q")
	decks, err := s.service.SearchCommunityDecks(userID, query)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"decks": decks})
}

// handleCommunityMine devuelve los decks que el usuario publicó a la
// comunidad con sus stats (importaciones por usuarios distintos).
func (s *Server) handleCommunityMine(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	decks, err := s.service.ListOwnedCommunityDecks(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"decks": decks})
}

// handleCommunityOverview alimenta la portada de Comunidad con datos reales.
func (s *Server) handleCommunityOverview(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	overview, err := s.service.CommunityOverview(userID)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, overview)
}

// handleCommunityReports archiva (POST) y lista (GET) denuncias de mazos.
func (s *Server) handleCommunityReports(w http.ResponseWriter, r *http.Request, userID string) {
	switch r.Method {
	case http.MethodGet:
		reports, err := s.service.ListDeckReports()
		if err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"reports": reports})
	case http.MethodPost:
		var body application.FileDeckReportInput
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
			return
		}
		report, err := s.service.FileDeckReport(userID, body)
		if err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
			return
		}
		writeJSON(w, http.StatusCreated, report)
	default:
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
	}
}

// handleCommunityReportResolve cierra un reporte con su resolución.
func (s *Server) handleCommunityReportResolve(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		ReportID   string `json:"reportId"`
		Resolution string `json:"resolution"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	report, err := s.service.ResolveDeckReport(body.ReportID, body.Resolution)
	if err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, application.ErrReportNotFound) {
			status = http.StatusNotFound
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, report)
}

// handleCommunityImport registra que el usuario importó un deck comunitario.
func (s *Server) handleCommunityImport(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		ShareID string `json:"shareId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	if err := s.service.RegisterCommunityImport(userID, body.ShareID); err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, application.ErrShareNotFound) {
			status = http.StatusNotFound
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	w.WriteHeader(http.StatusNoContent)
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

func (s *Server) handleFriendInviteAccept(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		ReferrerID string `json:"referrerId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	friendship, err := s.service.AcceptInviteFriend(userID, strings.TrimSpace(body.ReferrerID))
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
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

// ─── Avatars / verificación / reset ────────────────────────────────────

const avatarsDir = "data/avatars"

func (s *Server) handleAvatarUpload(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	// Espera multipart/form-data con campo "file".
	if err := r.ParseMultipartForm(8 << 20); err != nil { // 8 MB max
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid multipart"})
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "missing file"})
		return
	}
	defer file.Close()
	// Validar mime y tamaño básico.
	if header.Size > 8<<20 {
		writeJSON(w, http.StatusRequestEntityTooLarge, map[string]string{"error": "file too large"})
		return
	}
	ext := strings.ToLower(filepath.Ext(header.Filename))
	if ext != ".png" && ext != ".jpg" && ext != ".jpeg" && ext != ".webp" {
		writeJSON(w, http.StatusUnsupportedMediaType, map[string]string{"error": "unsupported format"})
		return
	}
	if err := os.MkdirAll(avatarsDir, 0o755); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	dstPath := filepath.Join(avatarsDir, userID+ext)
	dst, err := os.Create(dstPath)
	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	defer dst.Close()
	if _, err := io.Copy(dst, file); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	url := "/avatars/" + userID + ext
	if err := s.service.SetAvatarURL(userID, url); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"avatarUrl": url})
}

func (s *Server) handleAvatarServe(w http.ResponseWriter, r *http.Request) {
	name := strings.TrimPrefix(r.URL.Path, "/avatars/")
	if strings.Contains(name, "..") || strings.Contains(name, "/") {
		http.Error(w, "bad path", http.StatusBadRequest)
		return
	}
	http.ServeFile(w, r, filepath.Join(avatarsDir, name))
}

func (s *Server) handleVerifyRequest(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	token, err := s.service.RequestEmailVerify(userID)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	// En dev devolvemos el token. En prod sólo confirmamos el envío.
	writeJSON(w, http.StatusOK, map[string]any{
		"sent":     true,
		"devToken": token, // TODO(smtp): quitar en producción.
	})
}

func (s *Server) handleVerifyConfirm(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	if err := s.service.ConfirmEmailVerify(strings.TrimSpace(body.Token)); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"verified": true})
}

func (s *Server) handlePasswordResetRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		Email string `json:"email"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	token, _ := s.service.RequestPasswordReset(body.Email)
	writeJSON(w, http.StatusOK, map[string]any{
		"sent":     true,
		"devToken": token, // TODO(smtp): quitar en producción.
	})
}

func (s *Server) handlePasswordResetConfirm(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		Token       string `json:"token"`
		NewPassword string `json:"newPassword"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	if err := s.service.ConfirmPasswordReset(strings.TrimSpace(body.Token), body.NewPassword); err != nil {
		status := http.StatusBadRequest
		if errors.Is(err, application.ErrWeakPassword) {
			status = http.StatusUnprocessableEntity
		}
		writeJSON(w, status, map[string]string{"error": err.Error()})
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"reset": true})
}

// ─── Cooperativo ────────────────────────────────────────────────────────

func (s *Server) handleCoopCreateRoom(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	type CreateInput struct {
		IsPublic bool   `json:"isPublic"`
		DeckID   string `json:"deckId"`
		DeckName string `json:"deckName"`
		HostID   string `json:"hostId"`
	}
	input := CreateInput{
		IsPublic: true, // Default to public
	}
	if r.ContentLength > 0 {
		_ = json.NewDecoder(r.Body).Decode(&input)
	}
	effectiveHostID := userID
	if effectiveHostID == "" {
		effectiveHostID = input.HostID
	}
	if effectiveHostID == "" {
		effectiveHostID = "guest_temp"
	}
	room := s.coop.CreateRoom(effectiveHostID, input.IsPublic, input.DeckID, input.DeckName)
	writeJSON(w, http.StatusCreated, map[string]any{
		"code":   room.Code,
		"hostId": room.HostID,
	})
}

func (s *Server) handleCoopListPublicRooms(w http.ResponseWriter, r *http.Request, _ string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}

	q := r.URL.Query()

	difficulty := 0
	if diffStr := q.Get("difficulty"); diffStr != "" {
		if val, err := strconv.Atoi(diffStr); err == nil {
			difficulty = val
		}
	}

	mode := q.Get("mode")
	query := q.Get("query")

	hideFull := false
	if hideStr := q.Get("hideFull"); hideStr == "true" {
		hideFull = true
	}

	page := 1
	if pageStr := q.Get("page"); pageStr != "" {
		if val, err := strconv.Atoi(pageStr); err == nil && val > 0 {
			page = val
		}
	}

	limit := 10
	if limitStr := q.Get("limit"); limitStr != "" {
		if val, err := strconv.Atoi(limitStr); err == nil && val > 0 {
			limit = val
		}
	}

	rooms, total := s.coop.ListPublicRoomsPaged(difficulty, mode, query, hideFull, page, limit)

	totalPages := 0
	if limit > 0 {
		totalPages = (total + limit - 1) / limit
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"rooms":      rooms,
		"total":      total,
		"page":       page,
		"limit":      limit,
		"totalPages": totalPages,
	})
}

func (s *Server) handleCoopLookup(w http.ResponseWriter, r *http.Request, _ string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	code := r.URL.Query().Get("code")
	if code == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "missing code"})
		return
	}
	room := s.coop.Get(code)
	if room == nil {
		writeJSON(w, http.StatusNotFound, map[string]string{"error": "room not found"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"code":     room.Code,
		"hostId":   room.HostID,
		"deckId":   room.DeckID,
		"deckName": room.DeckName,
	})
}

func (s *Server) handleCoopInvite(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodPost {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	var body struct {
		FriendUserID string `json:"friendUserId"`
		RoomCode     string `json:"roomCode"`
		HostName     string `json:"hostName"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid json body"})
		return
	}
	s.coop.AddInvitation(strings.TrimSpace(body.FriendUserID), strings.TrimSpace(body.RoomCode), strings.TrimSpace(body.HostName))
	writeJSON(w, http.StatusOK, map[string]bool{"success": true})
}

func (s *Server) handleCoopGetPendingInvites(w http.ResponseWriter, r *http.Request, userID string) {
	if r.Method != http.MethodGet {
		writeJSON(w, http.StatusMethodNotAllowed, map[string]string{"error": "method not allowed"})
		return
	}
	invites := s.coop.GetPendingInvitations(userID)
	if invites == nil {
		invites = []coop.CoopInvitation{}
	}
	s.coop.ClearPendingInvitations(userID)
	writeJSON(w, http.StatusOK, invites)
}

var _ = domain.ProviderGoogle
