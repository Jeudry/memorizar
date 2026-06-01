package practice

import (
	"encoding/json"
	"net/http"
)

type CreateSessionRequest struct {
	SessionID string   `json:"sessionId"`
	DeckID    string   `json:"deckId"`
	CardIDs   []string `json:"cardIds"`
}

type SubmitResultRequest struct {
	ExerciseID    string   `json:"exerciseId"`
	Success       bool     `json:"success"`
	FailedCardIDs []string `json:"failedCardIds"`
}

type PracticeHandler struct {
	manager *SessionManager
}

func NewPracticeHandler(manager *SessionManager) *PracticeHandler {
	return &PracticeHandler{manager: manager}
}

func (h *PracticeHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	switch r.URL.Path {
	case "/v1/practice/sessions":
		if r.Method == http.MethodPost {
			h.handleCreateSession(w, r)
		} else {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	case "/v1/practice/sessions/submit":
		if r.Method == http.MethodPost {
			h.handleSubmitResult(w, r)
		} else {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	default:
		http.NotFound(w, r)
	}
}

func (h *PracticeHandler) handleCreateSession(w http.ResponseWriter, r *http.Request) {
	var req CreateSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	userID := "user_temp" // Mapeado desde auth en entorno real

	session, err := h.manager.CreateSession(req.SessionID, userID, req.DeckID, req.CardIDs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(session)
}

func (h *PracticeHandler) handleSubmitResult(w http.ResponseWriter, r *http.Request) {
	sessionID := r.URL.Query().Get("sessionId")
	if sessionID == "" {
		http.Error(w, "missing sessionId parameter", http.StatusBadRequest)
		return
	}

	var req SubmitResultRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	session, err := h.manager.SubmitExerciseResult(sessionID, req.ExerciseID, req.Success, req.FailedCardIDs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(session)
}
