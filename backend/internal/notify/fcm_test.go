package notify

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"io"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
)

func TestBuildFcmMessage(t *testing.T) {
	n := Notification{
		Type:   EventDeckLiked,
		UserID: "u1",
		Title:  "Alguien dio me gusta",
		Body:   "A tu mazo",
		Data:   map[string]string{"deeplink": "memorizar://comunidad"},
	}
	msg := buildFcmMessage("dev-token-123", n)
	inner, ok := msg["message"].(map[string]any)
	if !ok {
		t.Fatalf("expected message object, got %T", msg["message"])
	}
	if inner["token"] != "dev-token-123" {
		t.Errorf("token = %v", inner["token"])
	}
	notif := inner["notification"].(map[string]string)
	if notif["title"] != n.Title || notif["body"] != n.Body {
		t.Errorf("notification = %+v", notif)
	}
	data := inner["data"].(map[string]string)
	if data["deeplink"] != "memorizar://comunidad" {
		t.Errorf("data = %+v", data)
	}
}

func TestBuildFcmMessage_OmitsEmptyData(t *testing.T) {
	msg := buildFcmMessage("t", Notification{Title: "x", Body: "y"})
	inner := msg["message"].(map[string]any)
	if _, present := inner["data"]; present {
		t.Errorf("expected no data key when Data is empty, got %+v", inner)
	}
}

func TestParseFcmProjectID(t *testing.T) {
	if _, err := parseFcmProjectID([]byte(`{"type":"service_account"}`)); err == nil {
		t.Error("expected error when project_id is missing")
	}
	id, err := parseFcmProjectID([]byte(`{"project_id":"memorizar-abc"}`))
	if err != nil || id != "memorizar-abc" {
		t.Fatalf("got id=%q err=%v", id, err)
	}
}

// fakeServiceAccount genera un JSON de service account válido con una clave RSA
// real, suficiente para que oauth2/google construya un TokenSource.
func fakeServiceAccount(t *testing.T) []byte {
	t.Helper()
	key, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		t.Fatalf("genkey: %v", err)
	}
	der := x509.MarshalPKCS1PrivateKey(key)
	pemBytes := pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: der})
	sa := map[string]string{
		"type":         "service_account",
		"project_id":   "memorizar-test",
		"private_key":  string(pemBytes),
		"client_email": "test@memorizar-test.iam.gserviceaccount.com",
		"token_uri":    "https://oauth2.googleapis.com/token",
	}
	b, err := json.Marshal(sa)
	if err != nil {
		t.Fatalf("marshal sa: %v", err)
	}
	return b
}

func TestFcmNotifier_SendsToEndpoint(t *testing.T) {
	var (
		mu       sync.Mutex
		captured []byte
		hits     int
	)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, _ := io.ReadAll(r.Body)
		mu.Lock()
		captured = body
		hits++
		mu.Unlock()
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"name":"projects/memorizar-test/messages/123"}`))
	}))
	defer srv.Close()

	n, err := NewFcmNotifier(
		context.Background(),
		fakeServiceAccount(t),
		func(userID string) ([]string, error) { return []string{"tok-A", "tok-B"}, nil },
	)
	if err != nil {
		t.Fatalf("NewFcmNotifier: %v", err)
	}
	if n.projectID != "memorizar-test" {
		t.Errorf("projectID = %q", n.projectID)
	}
	// Apuntamos el envío al server fake y usamos un http.Client plano para no
	// pegarle a la red real (el token source de oauth2 no se ejercita así).
	n.endpoint = srv.URL
	n.httpClient = srv.Client()

	// deliver es síncrono (Notify lo lanza en goroutine; aquí lo llamamos
	// directo para testear de forma determinista).
	n.deliver(Notification{
		Type:   EventFollowed,
		UserID: "u1",
		Title:  "Nuevo seguidor",
		Body:   "Alguien te sigue",
		Data:   map[string]string{"deeplink": "memorizar://comunidad"},
	})

	mu.Lock()
	defer mu.Unlock()
	if hits != 2 {
		t.Fatalf("expected 2 sends (one per token), got %d", hits)
	}
	var payload map[string]any
	if err := json.Unmarshal(captured, &payload); err != nil {
		t.Fatalf("captured body not JSON: %v", err)
	}
	inner := payload["message"].(map[string]any)
	if inner["token"] != "tok-B" {
		t.Errorf("last token = %v, want tok-B", inner["token"])
	}
	if notif, _ := inner["notification"].(map[string]any); notif["title"] != "Nuevo seguidor" {
		t.Errorf("title = %v", notif["title"])
	}
}
