// Package coop implementa salas de estudio cooperativo en tiempo real con
// websockets. Cada sala tiene un host, un código de 6 caracteres y un puñado
// de invitados. Los mensajes se broadcastan a todos los miembros.
//
// Estado: in-memory. Para producción se debe persistir snapshot + reconectar
// con Redis pub/sub.
package coop

import (
	"encoding/json"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

// Message es lo que viaja por el canal. `type` define el handler.
//   join          → cliente avisa que entró (UI sincroniza member list)
//   leave         → cliente avisa que sale
//   answer        → host avanzó / un miembro dio una respuesta
//   reaction      → emoji rápido
//   chat          → mensaje de texto
//   state         → host empuja estado completo de la sala
type Message struct {
	Type    string          `json:"type"`
	UserID  string          `json:"userId"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

type Member struct {
	UserID      string
	DisplayName string
	conn        *websocket.Conn
	send        chan []byte
}

type Room struct {
	Code      string
	HostID    string
	CreatedAt time.Time
	mu        sync.RWMutex
	members   map[string]*Member
}

type Hub struct {
	mu    sync.RWMutex
	rooms map[string]*Room
}

func NewHub() *Hub {
	return &Hub{rooms: map[string]*Room{}}
}

// CreateRoom genera un código de 6 letras y devuelve la sala.
func (h *Hub) CreateRoom(hostID string) *Room {
	code := generateCode()
	room := &Room{
		Code:      code,
		HostID:    hostID,
		CreatedAt: time.Now().UTC(),
		members:   map[string]*Member{},
	}
	h.mu.Lock()
	h.rooms[code] = room
	h.mu.Unlock()
	return room
}

func (h *Hub) Get(code string) *Room {
	h.mu.RLock()
	defer h.mu.RUnlock()
	return h.rooms[strings.ToUpper(code)]
}

// HandleWebsocket sube la conexión y la une al room indicado en query
// `?code=ABC123&user=usr_xxx&name=Pedro`.
func (h *Hub) HandleWebsocket(w http.ResponseWriter, r *http.Request) {
	code := strings.ToUpper(r.URL.Query().Get("code"))
	userID := r.URL.Query().Get("user")
	name := r.URL.Query().Get("name")
	if code == "" || userID == "" {
		http.Error(w, "missing code or user", http.StatusBadRequest)
		return
	}
	room := h.Get(code)
	if room == nil {
		http.Error(w, "room not found", http.StatusNotFound)
		return
	}
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return
	}
	member := &Member{
		UserID:      userID,
		DisplayName: name,
		conn:        conn,
		send:        make(chan []byte, 32),
	}
	room.add(member)
	defer room.remove(userID)
	go member.writeLoop()
	member.readLoop(room)
}

func (r *Room) add(m *Member) {
	r.mu.Lock()
	r.members[m.UserID] = m
	r.mu.Unlock()
	r.broadcast(Message{Type: "join", UserID: m.UserID})
}

func (r *Room) remove(userID string) {
	r.mu.Lock()
	if m, ok := r.members[userID]; ok {
		close(m.send)
	}
	delete(r.members, userID)
	r.mu.Unlock()
	r.broadcast(Message{Type: "leave", UserID: userID})
}

func (r *Room) broadcast(msg Message) {
	data, _ := json.Marshal(msg)
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, m := range r.members {
		select {
		case m.send <- data:
		default:
			// client lento — drop, no bloqueamos al resto.
		}
	}
}

func (m *Member) readLoop(room *Room) {
	defer m.conn.Close()
	m.conn.SetReadLimit(1 << 14)
	for {
		_, raw, err := m.conn.ReadMessage()
		if err != nil {
			return
		}
		var msg Message
		if err := json.Unmarshal(raw, &msg); err != nil {
			continue
		}
		msg.UserID = m.UserID
		room.broadcast(msg)
	}
}

func (m *Member) writeLoop() {
	for data := range m.send {
		if err := m.conn.WriteMessage(websocket.TextMessage, data); err != nil {
			log.Printf("[coop] write error: %v", err)
			return
		}
	}
}

const codeAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

func generateCode() string {
	b := make([]byte, 6)
	for i := range b {
		b[i] = codeAlphabet[rand.Intn(len(codeAlphabet))]
	}
	return string(b)
}
