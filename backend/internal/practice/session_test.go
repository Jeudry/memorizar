package practice

import (
	"testing"
)

func TestCreateSession(t *testing.T) {
	sm := NewSessionManager()
	cardIDs := []string{"card_A", "card_B", "card_C"}

	session, err := sm.CreateSession("session_1", "user_1", "deck_1", cardIDs)
	if err != nil {
		t.Fatalf("failed to create session: %v", err)
	}

	if session.ID != "session_1" {
		t.Errorf("expected session ID session_1, got %s", session.ID)
	}

	if len(session.Queue) != 5 {
		t.Errorf("expected queue length 5, got %d", len(session.Queue))
	}

	// Verificar regla estricta: 3 de Lectura, 2 de Escucha
	expectedTypes := []ExerciseType{
		ExerciseLectura,
		ExerciseLectura,
		ExerciseLectura,
		ExerciseEscucha,
		ExerciseEscucha,
	}

	for i, expectedType := range expectedTypes {
		if session.Queue[i].Type != expectedType {
			t.Errorf("expected exercise %d type %s, got %s", i, expectedType, session.Queue[i].Type)
		}
	}
}

func TestSubmitExerciseResult_StrictOrder(t *testing.T) {
	sm := NewSessionManager()
	cardIDs := []string{"card_A", "card_B"}
	session, _ := sm.CreateSession("session_1", "user_1", "deck_1", cardIDs)

	// Intentar enviar el segundo ejercicio antes que el primero
	_, err := sm.SubmitExerciseResult("session_1", session.Queue[1].ID, true, nil)
	if err == nil {
		t.Error("expected error when submitting exercise out of order, got nil")
	}
}

func TestSubmitExerciseResult_WithFailures_InjectsReinforcement(t *testing.T) {
	sm := NewSessionManager()
	cardIDs := []string{"card_A", "card_B", "card_C"}
	session, _ := sm.CreateSession("session_1", "user_1", "deck_1", cardIDs)

	// Ejercicio 1 (Lectura) - Éxito
	_, err := sm.SubmitExerciseResult("session_1", session.Queue[0].ID, true, nil)
	if err != nil {
		t.Fatalf("submit exercise 0 failed: %v", err)
	}

	// Ejercicio 2 (Lectura) - Fallo en card_A
	_, err = sm.SubmitExerciseResult("session_1", session.Queue[1].ID, false, []string{"card_A"})
	if err != nil {
		t.Fatalf("submit exercise 1 failed: %v", err)
	}

	// Ejercicio 3 (Lectura) - Fallo en card_B
	_, err = sm.SubmitExerciseResult("session_1", session.Queue[2].ID, false, []string{"card_B"})
	if err != nil {
		t.Fatalf("submit exercise 2 failed: %v", err)
	}

	// Ejercicio 4 (Escucha) - Fallo en card_A
	_, err = sm.SubmitExerciseResult("session_1", session.Queue[3].ID, false, []string{"card_A"})
	if err != nil {
		t.Fatalf("submit exercise 3 failed: %v", err)
	}

	// Ejercicio 5 (Escucha) - Éxito
	sessionUpdated, err := sm.SubmitExerciseResult("session_1", session.Queue[4].ID, true, nil)
	if err != nil {
		t.Fatalf("submit exercise 4 failed: %v", err)
	}

	// Al finalizar los 5, dado que hubo fallos, debe haberse inyectado el Ejercicio de Refuerzo (6to elemento)
	if len(sessionUpdated.Queue) != 6 {
		t.Fatalf("expected queue length 6 (5 core + 1 reinforcement), got %d", len(sessionUpdated.Queue))
	}

	reinforcement := sessionUpdated.Queue[5]
	if reinforcement.Type != ExerciseRefuerzo {
		t.Errorf("expected 6th exercise type to be %s, got %s", ExerciseRefuerzo, reinforcement.Type)
	}

	// La tarjeta con más fallos es "card_A" (2 fallos contra 1 de "card_B")
	if reinforcement.CardID != "card_A" {
		t.Errorf("expected reinforcement target CardID to be 'card_A', got '%s'", reinforcement.CardID)
	}

	if sessionUpdated.CompletedAt != nil {
		t.Error("expected CompletedAt to be nil because reinforcement exercise is pending")
	}

	// Completar el ejercicio de refuerzo
	finalSession, err := sm.SubmitExerciseResult("session_1", reinforcement.ID, true, nil)
	if err != nil {
		t.Fatalf("submit reinforcement failed: %v", err)
	}

	if finalSession.CompletedAt == nil {
		t.Error("expected CompletedAt to be populated after completing reinforcement exercise")
	}
}

func TestSubmitExerciseResult_NoFailures_CleanCompletion(t *testing.T) {
	sm := NewSessionManager()
	cardIDs := []string{"card_A"}
	session, _ := sm.CreateSession("session_1", "user_1", "deck_1", cardIDs)

	var sessionUpdated *Session
	var err error

	// Completar los 5 ejercicios con éxito
	for i := 0; i < 5; i++ {
		sessionUpdated, err = sm.SubmitExerciseResult("session_1", session.Queue[i].ID, true, nil)
		if err != nil {
			t.Fatalf("submit exercise %d failed: %v", i, err)
		}
	}

	// Sin fallos, no debe inyectarse refuerzo
	if len(sessionUpdated.Queue) != 5 {
		t.Errorf("expected queue length 5, got %d", len(sessionUpdated.Queue))
	}

	if sessionUpdated.CompletedAt == nil {
		t.Error("expected CompletedAt to be populated after completing the 5 exercises successfully")
	}
}
