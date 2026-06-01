package practice

import (
	"errors"
	"sync"
	"time"
)

type ExerciseType string

const (
	ExerciseLectura   ExerciseType = "Lectura"
	ExerciseEscucha   ExerciseType = "Escucha"
	ExerciseRefuerzo  ExerciseType = "Refuerzo"
)

type ExerciseState string

const (
	StatePending    ExerciseState = "Pending"
	StateInProgress ExerciseState = "InProgress"
	StateCompleted  ExerciseState = "Completed"
	StateFailed     ExerciseState = "Failed"
)

type Exercise struct {
	ID     string        `json:"id"`
	Type   ExerciseType  `json:"type"`
	State  ExerciseState `json:"state"`
	CardID string        `json:"cardId"`
}

type Session struct {
	ID             string         `json:"id"`
	UserID         string         `json:"userId"`
	DeckID         string         `json:"deckId"`
	Queue          []*Exercise    `json:"queue"`
	CurrentIndex   int            `json:"currentIndex"`
	IncorrectItems map[string]int `json:"incorrectItems"` // cardId -> cantidad de fallos
	CreatedAt      time.Time      `json:"createdAt"`
	CompletedAt    *time.Time     `json:"completedAt,omitempty"`
}

type SessionManager struct {
	mu       sync.RWMutex
	sessions map[string]*Session
}

func NewSessionManager() *SessionManager {
	return &SessionManager{
		sessions: make(map[string]*Session),
	}
}

// CreateSession crea la sesión con los 5 slots ordenados de forma fija y estricta
func (sm *SessionManager) CreateSession(sessionID, userID, deckID string, cardIDs []string) (*Session, error) {
	if len(cardIDs) == 0 {
		return nil, errors.New("cardIDs cannot be empty")
	}

	sm.mu.Lock()
	defer sm.mu.Unlock()

	queue := make([]*Exercise, 5)
	for i := 0; i < 5; i++ {
		cardID := cardIDs[i%len(cardIDs)]
		var extType ExerciseType
		if i < 3 {
			extType = ExerciseLectura
		} else {
			extType = ExerciseEscucha
		}

		queue[i] = &Exercise{
			ID:     string(rune('1'+i)) + "_" + string(extType),
			Type:   extType,
			State:  StatePending,
			CardID: cardID,
		}
	}

	session := &Session{
		ID:             sessionID,
		UserID:         userID,
		DeckID:         deckID,
		Queue:          queue,
		CurrentIndex:   0,
		IncorrectItems: make(map[string]int),
		CreatedAt:      time.Now(),
	}

	sm.sessions[sessionID] = session
	return session, nil
}

// SubmitExerciseResult evalúa la finalización de un ejercicio y ejecuta el refuerzo automático al final
func (sm *SessionManager) SubmitExerciseResult(sessionID string, exerciseID string, success bool, failedCardIDs []string) (*Session, error) {
	sm.mu.Lock()
	defer sm.mu.Unlock()

	session, exists := sm.sessions[sessionID]
	if !exists {
		return nil, errors.New("session not found")
	}

	if session.CurrentIndex >= len(session.Queue) {
		return nil, errors.New("session already completed")
	}

	currentExercise := session.Queue[session.CurrentIndex]
	if currentExercise.ID != exerciseID {
		return nil, errors.New("exercise submitted out of order: must complete current index first")
	}

	// Registrar fallos
	if !success {
		currentExercise.State = StateFailed
		for _, cardID := range failedCardIDs {
			session.IncorrectItems[cardID]++
		}
	} else {
		currentExercise.State = StateCompleted
	}

	session.CurrentIndex++

	// Inyección del Ejercicio de Refuerzo Automático al finalizar el 5to ejercicio
	if session.CurrentIndex == 5 {
		if len(session.IncorrectItems) > 0 {
			// Buscar la tarjeta con mayor cantidad de fallos acumulados en la sesión
			weakestCardID := ""
			maxFailures := -1
			for cardID, count := range session.IncorrectItems {
				if count > maxFailures {
					maxFailures = count
					weakestCardID = cardID
				}
			}

			// Inyección dinámica
			reinforcementExercise := &Exercise{
				ID:     "6_Refuerzo",
				Type:   ExerciseRefuerzo,
				State:  StatePending,
				CardID: weakestCardID,
			}
			session.Queue = append(session.Queue, reinforcementExercise)
		} else {
			// Sin fallos, sesión terminada perfectamente en 5 ejercicios
			now := time.Now()
			session.CompletedAt = &now
		}
	} else if session.CurrentIndex == len(session.Queue) {
		// Completó el ejercicio de refuerzo, sesión terminada
		now := time.Now()
		session.CompletedAt = &now
	}

	return session, nil
}
