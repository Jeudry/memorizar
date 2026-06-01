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

const (
	writeWait  = 10 * time.Second
	pongWait   = 60 * time.Second
	pingPeriod = (pongWait * 9) / 10
)

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
	Code           string
	HostID         string
	CreatedAt      time.Time
	LastActivityAt time.Time
	mu             sync.RWMutex
	members        map[string]*Member
	IsPublic       bool
	DeckID         string
	DeckName       string
	Mode           string // "grupal", "versus", "libre"
	MaxPlayers     int
	Difficulty     int
	DailyTarget    int
}

type CoopInvitation struct {
	FriendUserID string    `json:"friendUserId"`
	RoomCode     string    `json:"roomCode"`
	HostName     string    `json:"hostName"`
	Timestamp    time.Time `json:"timestamp"`
}

type Hub struct {
	mu        sync.RWMutex
	rooms     map[string]*Room
	invitesMu sync.RWMutex
	invites   map[string][]CoopInvitation
}

func NewHub() *Hub {
	h := &Hub{
		rooms:   map[string]*Room{},
		invites: make(map[string][]CoopInvitation),
	}
	go h.cleanupLoop()
	return h
}

func (h *Hub) cleanupLoop() {
	ticker := time.NewTicker(1 * time.Minute)
	for range ticker.C {
		h.mu.Lock()
		for code, r := range h.rooms {
			r.mu.RLock()
			memberCount := len(r.members)
			createdAt := r.CreatedAt
			lastActivity := r.LastActivityAt
			r.mu.RUnlock()

			// Si la sala no tiene miembros y lleva más de 1 minuto creada, se borra.
			// O si lleva más de 30 minutos sin ninguna actividad (inactiva), se borra.
			if (memberCount == 0 && time.Since(createdAt) > 1*time.Minute) ||
				(time.Since(lastActivity) > 30*time.Minute) {
				delete(h.rooms, code)
				log.Printf("[coop] room %s cleaned up due to inactivity/emptiness/timeout", code)
				
				// Cerrar conexiones activas si quedaban miembros colgados
				r.mu.Lock()
				for _, m := range r.members {
					m.conn.Close()
				}
				r.mu.Unlock()
			}
		}
		h.mu.Unlock()
	}
}

type PublicRoomInfo struct {
	Code        string   `json:"code"`
	HostID      string   `json:"hostId"`
	MemberCount int      `json:"memberCount"`
	DeckID      string   `json:"deckId"`
	DeckName    string   `json:"deckName"`
	Mode        string   `json:"mode"`
	CreatedAt   string   `json:"createdAt"`
	Difficulty  int      `json:"difficulty"`
	DailyTarget int      `json:"dailyTarget"`
	MaxPlayers  int      `json:"maxPlayers"`
}

// CreateRoom genera un código de 6 letras y devuelve la sala.
func (h *Hub) CreateRoom(hostID string, isPublic bool, deckID string, deckName string) *Room {
	code := generateCode()
	room := &Room{
		Code:           code,
		HostID:         hostID,
		CreatedAt:      time.Now().UTC(),
		LastActivityAt: time.Now().UTC(),
		members:        map[string]*Member{},
		IsPublic:       isPublic,
		DeckID:         deckID,
		DeckName:       deckName,
		Mode:           "grupal",
		MaxPlayers:     4,
		Difficulty:     1,
		DailyTarget:    0,
	}
	h.mu.Lock()
	h.rooms[code] = room
	h.mu.Unlock()
	return room
}

func (h *Hub) ListPublicRooms() []PublicRoomInfo {
	h.mu.RLock()
	defer h.mu.RUnlock()
	
	list := []PublicRoomInfo{}
	for _, r := range h.rooms {
		r.mu.RLock()
		if r.IsPublic && len(r.members) > 0 {
			list = append(list, PublicRoomInfo{
				Code:        r.Code,
				HostID:      r.HostID,
				MemberCount: len(r.members),
				DeckID:      r.DeckID,
				DeckName:    r.DeckName,
				Mode:        r.Mode,
				CreatedAt:   r.CreatedAt.Format(time.RFC3339),
				Difficulty:  r.Difficulty,
				DailyTarget: r.DailyTarget,
				MaxPlayers:  r.MaxPlayers,
			})
		}
		r.mu.RUnlock()
	}
	return list
}

// ListPublicRoomsPaged lists rooms applying paginated results and filters
func (h *Hub) ListPublicRoomsPaged(difficulty int, mode string, query string, hideFull bool, page int, limit int) ([]PublicRoomInfo, int) {
	h.mu.RLock()
	defer h.mu.RUnlock()

	filtered := []PublicRoomInfo{}
	for _, r := range h.rooms {
		r.mu.RLock()
		if r.IsPublic && len(r.members) > 0 {
			// Filtro por dificultad
			if difficulty > 0 && r.Difficulty != difficulty {
				r.mu.RUnlock()
				continue
			}
			// Filtro por modo
			if mode != "" && r.Mode != mode {
				r.mu.RUnlock()
				continue
			}
			// Filtro por nombre de mazo o código de sala
			if query != "" && !strings.Contains(strings.ToLower(r.DeckName), strings.ToLower(query)) && !strings.Contains(strings.ToLower(r.Code), strings.ToLower(query)) {
				r.mu.RUnlock()
				continue
			}
			// Filtro por salas llenas
			if hideFull && r.MaxPlayers > 0 && len(r.members) >= r.MaxPlayers {
				r.mu.RUnlock()
				continue
			}

			filtered = append(filtered, PublicRoomInfo{
				Code:        r.Code,
				HostID:      r.HostID,
				MemberCount: len(r.members),
				DeckID:      r.DeckID,
				DeckName:    r.DeckName,
				Mode:        r.Mode,
				CreatedAt:   r.CreatedAt.Format(time.RFC3339),
				Difficulty:  r.Difficulty,
				DailyTarget: r.DailyTarget,
				MaxPlayers:  r.MaxPlayers,
			})
		}
		r.mu.RUnlock()
	}

	total := len(filtered)

	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	start := (page - 1) * limit
	if start >= total {
		return []PublicRoomInfo{}, total
	}

	end := start + limit
	if end > total {
		end = total
	}

	return filtered[start:end], total
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
	room.mu.RLock()
	_, isAlreadyMember := room.members[userID]
	if !isAlreadyMember && room.MaxPlayers > 0 && len(room.members) >= room.MaxPlayers {
		room.mu.RUnlock()
		http.Error(w, "room is full", http.StatusForbidden)
		return
	}
	room.mu.RUnlock()
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
	go member.writeLoop()
	room.add(member)
	defer h.RemoveMember(room, member)
	member.readLoop(room)
}

func (r *Room) add(m *Member) {
	r.mu.Lock()
	r.LastActivityAt = time.Now().UTC()
	// Enviar mensaje "join" por cada miembro existente al nuevo integrante
	for _, existing := range r.members {
		msg := Message{Type: "join", UserID: existing.UserID}
		data, _ := json.Marshal(msg)
		select {
		case m.send <- data:
		default:
		}
	}
	r.members[m.UserID] = m
	r.mu.Unlock()
	r.broadcast(Message{Type: "join", UserID: m.UserID})
}

func (h *Hub) RemoveMember(r *Room, m *Member) {
	r.mu.Lock()
	current, ok := r.members[m.UserID]
	if !ok || current != m {
		// Este Member ya fue reemplazado por una conexión más nueva con el mismo UserID. No borrar la nueva.
		r.mu.Unlock()
		return
	}
	r.LastActivityAt = time.Now().UTC()
	close(m.send)
	delete(r.members, m.UserID)
	empty := len(r.members) == 0
	r.mu.Unlock()

	r.broadcast(Message{Type: "leave", UserID: m.UserID})

	if empty {
		h.mu.Lock()
		r.mu.RLock()
		if len(r.members) == 0 {
			delete(h.rooms, r.Code)
			log.Printf("[coop] room %s deleted (last member left)", r.Code)
		}
		r.mu.RUnlock()
		h.mu.Unlock()
	}
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
	defer func() {
		m.conn.Close()
	}()
	m.conn.SetReadLimit(1 << 14)
	_ = m.conn.SetReadDeadline(time.Now().Add(pongWait))
	m.conn.SetPongHandler(func(string) error {
		_ = m.conn.SetReadDeadline(time.Now().Add(pongWait))
		return nil
	})
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

		room.mu.Lock()
		room.LastActivityAt = time.Now().UTC()
		room.mu.Unlock()

		if msg.Type == "deck" {
			type DeckPayload struct {
				DeckID   string `json:"deckId"`
				DeckName string `json:"deckName"`
			}
			var p DeckPayload
			if err := json.Unmarshal(msg.Payload, &p); err == nil {
				room.mu.Lock()
				room.DeckID = p.DeckID
				room.DeckName = p.DeckName
				room.mu.Unlock()
			}
		} else if msg.Type == "mode" {
			type ModePayload struct {
				Mode string `json:"mode"`
			}
			var p ModePayload
			if err := json.Unmarshal(msg.Payload, &p); err == nil {
				room.mu.Lock()
				room.Mode = p.Mode
				room.mu.Unlock()
			}
		} else if msg.Type == "visibility" {
			type VisibilityPayload struct {
				IsPublic bool `json:"isPublic"`
			}
			var p VisibilityPayload
			if err := json.Unmarshal(msg.Payload, &p); err == nil {
				room.mu.Lock()
				room.IsPublic = p.IsPublic
				room.mu.Unlock()
			}
		} else if msg.Type == "session_config" {
			type SessionConfigPayload struct {
				MaxPlayers  int `json:"maxPlayers"`
				Difficulty  int `json:"difficulty"`
				DailyTarget int `json:"dailyTarget"`
			}
			var p SessionConfigPayload
			if err := json.Unmarshal(msg.Payload, &p); err == nil {
				room.mu.Lock()
				if p.MaxPlayers > 0 {
					room.MaxPlayers = p.MaxPlayers
				}
				if p.Difficulty > 0 {
					room.Difficulty = p.Difficulty
				}
				if p.DailyTarget > 0 {
					room.DailyTarget = p.DailyTarget
				}
				room.mu.Unlock()
			}
		}

		room.broadcast(msg)
	}
}

func (m *Member) writeLoop() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		m.conn.Close()
	}()
	for {
		select {
		case data, ok := <-m.send:
			_ = m.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				_ = m.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			if err := m.conn.WriteMessage(websocket.TextMessage, data); err != nil {
				log.Printf("[coop] write error: %v", err)
				return
			}
		case <-ticker.C:
			_ = m.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := m.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				log.Printf("[coop] ping write error: %v", err)
				return
			}
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

func (h *Hub) AddInvitation(friendUserID string, roomCode string, hostName string) {
	h.invitesMu.Lock()
	defer h.invitesMu.Unlock()
	if h.invites == nil {
		h.invites = make(map[string][]CoopInvitation)
	}
	h.invites[friendUserID] = append(h.invites[friendUserID], CoopInvitation{
		FriendUserID: friendUserID,
		RoomCode:     roomCode,
		HostName:     hostName,
		Timestamp:    time.Now(),
	})
}

func (h *Hub) GetPendingInvitations(friendUserID string) []CoopInvitation {
	h.invitesMu.RLock()
	defer h.invitesMu.RUnlock()
	if h.invites == nil {
		return nil
	}
	return h.invites[friendUserID]
}

func (h *Hub) ClearPendingInvitations(friendUserID string) {
	h.invitesMu.Lock()
	defer h.invitesMu.Unlock()
	if h.invites != nil {
		delete(h.invites, friendUserID)
	}
}

func (h *Hub) IsUserOnline(userID string) bool {
	h.mu.RLock()
	defer h.mu.RUnlock()
	for _, room := range h.rooms {
		room.mu.RLock()
		if _, exists := room.members[userID]; exists {
			room.mu.RUnlock()
			return true
		}
		room.mu.RUnlock()
	}
	return false
}
