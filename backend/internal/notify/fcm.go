package notify

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
)

// fcmScope es el OAuth scope requerido por la API FCM HTTP v1.
const fcmScope = "https://www.googleapis.com/auth/firebase.messaging"

// FcmNotifier envía notificaciones push reales vía la API FCM HTTP v1
// (https://fcm.googleapis.com/v1/projects/{project}/messages:send).
//
// Reemplaza al LogNotifier cuando hay credenciales de service account
// configuradas. No depende del repo directamente: recibe un callback
// tokensFor que resuelve los push tokens del destinatario, manteniendo el
// paquete notify desacoplado de la capa de datos.
type FcmNotifier struct {
	httpClient *http.Client
	projectID  string
	endpoint   string // override para tests; vacío = endpoint real de FCM
	tokensFor  func(userID string) ([]string, error)
}

// fcmServiceAccount es el subconjunto del JSON de service account que
// necesitamos para construir el notifier (el resto lo parsea oauth2/google).
type fcmServiceAccount struct {
	ProjectID string `json:"project_id"`
	Type      string `json:"type"`
}

// NewFcmNotifier construye un FcmNotifier a partir del JSON de un service
// account de Google (el archivo que descarga la consola de Firebase). tokensFor
// resuelve los device tokens de un usuario. Devuelve error si el JSON es
// inválido o no trae project_id.
func NewFcmNotifier(
	ctx context.Context,
	credentialsJSON []byte,
	tokensFor func(userID string) ([]string, error),
) (*FcmNotifier, error) {
	projectID, err := parseFcmProjectID(credentialsJSON)
	if err != nil {
		return nil, err
	}
	creds, err := google.CredentialsFromJSON(ctx, credentialsJSON, fcmScope)
	if err != nil {
		return nil, fmt.Errorf("fcm: credenciales inválidas: %w", err)
	}
	client := oauth2.NewClient(ctx, creds.TokenSource)
	return &FcmNotifier{
		httpClient: client,
		projectID:  projectID,
		tokensFor:  tokensFor,
	}, nil
}

// parseFcmProjectID extrae y valida el project_id del JSON de credenciales.
func parseFcmProjectID(credentialsJSON []byte) (string, error) {
	var sa fcmServiceAccount
	if err := json.Unmarshal(credentialsJSON, &sa); err != nil {
		return "", fmt.Errorf("fcm: JSON de credenciales inválido: %w", err)
	}
	if sa.ProjectID == "" {
		return "", fmt.Errorf("fcm: el service account no trae project_id")
	}
	return sa.ProjectID, nil
}

// Notify resuelve los tokens del destinatario y envía un mensaje FCM por cada
// uno. El envío corre en una goroutine para no bloquear el request que disparó
// la notificación; los errores se loguean sin propagarse.
func (n *FcmNotifier) Notify(notification Notification) {
	if n.tokensFor == nil {
		return
	}
	go n.deliver(notification)
}

func (n *FcmNotifier) deliver(notification Notification) {
	if notification.UserID == "" {
		return
	}
	tokens, err := n.tokensFor(notification.UserID)
	if err != nil {
		log.Printf("[fcm] no se pudieron leer tokens de %s: %v", notification.UserID, err)
		return
	}
	if len(tokens) == 0 {
		return
	}
	for _, token := range tokens {
		if err := n.send(token, notification); err != nil {
			log.Printf("[fcm] envío fallido (%s): %v", notification.Type, err)
		}
	}
}

// send arma y manda un único mensaje FCM HTTP v1 a un device token.
func (n *FcmNotifier) send(token string, notification Notification) error {
	payload := buildFcmMessage(token, notification)
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	url := n.endpoint
	if url == "" {
		url = fmt.Sprintf("https://fcm.googleapis.com/v1/projects/%s/messages:send", n.projectID)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := n.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		snippet, _ := io.ReadAll(io.LimitReader(resp.Body, 512))
		return fmt.Errorf("status %d: %s", resp.StatusCode, bytes.TrimSpace(snippet))
	}
	return nil
}

// buildFcmMessage construye el cuerpo de la petición FCM HTTP v1 para un token.
// Es puro (sin red) para poder testearlo de forma determinista.
func buildFcmMessage(token string, n Notification) map[string]any {
	message := map[string]any{
		"token": token,
		"notification": map[string]string{
			"title": n.Title,
			"body":  n.Body,
		},
	}
	if len(n.Data) > 0 {
		// FCM exige que todos los valores de data sean strings (ya lo son).
		message["data"] = n.Data
	}
	return map[string]any{"message": message}
}
