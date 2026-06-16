// Package notify dispara notificaciones push a usuarios cuando ocurren
// eventos sociales (invitación de amigo, mazo compartido, etc.).
//
// Estado: stub. La función Send sólo imprime a log; cuando se integre
// Firebase Admin (FCM), reemplazar la implementación de Send por una que
// busque los push tokens del usuario destino en la DB y llame a la API
// de FCM.
//
// El service layer NUNCA depende del transporte real — solo invoca a
// Notifier.Notify(...) con el tipo de evento. Eso permite tests y permite
// switch del transporte (FCM, OneSignal, APNs directo) sin tocar lógica.
package notify

import (
	"log"
)

type EventType string

const (
	EventFriendRequested EventType = "friend_requested"
	EventFriendAccepted  EventType = "friend_accepted"
	EventDeckShared      EventType = "deck_shared"
	EventReactionAdded   EventType = "reaction_added"
	EventCommentAdded    EventType = "comment_added"
	EventDeckLiked       EventType = "deck_liked"
	EventFollowed        EventType = "followed"
)

type Notification struct {
	Type   EventType
	UserID string // destinatario
	Title  string
	Body   string
	Data   map[string]string // payload adicional (deeplink, IDs)
}

type Notifier interface {
	Notify(n Notification)
}

// LogNotifier es el stub default. Loguea a stdout. Reemplazable por
// FcmNotifier cuando esté Firebase configurado.
type LogNotifier struct{}

func (LogNotifier) Notify(n Notification) {
	log.Printf("[notify] → %s | %s | %s | %s | data=%v",
		n.Type, n.UserID, n.Title, n.Body, n.Data)
}

// FcmNotifier (fcm.go) implementa el envío real vía FCM HTTP v1. Se activa
// desde cmd/api/main.go cuando hay credenciales de service account; si no, se
// usa LogNotifier. El service layer no cambia: ambos cumplen Notifier.
