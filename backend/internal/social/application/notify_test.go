package application_test

import (
	"sync"
	"testing"

	"github.com/Jeudry/memorizar/backend/internal/notify"
	memrepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/memory"
	"github.com/Jeudry/memorizar/backend/internal/social/application"
)

// captureNotifier es un Notifier in-memory para tests. No tocar campos sin
// el lock — Notify se llama desde el goroutine del request handler.
type captureNotifier struct {
	mu     sync.Mutex
	events []notify.Notification
}

func (c *captureNotifier) Notify(n notify.Notification) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.events = append(c.events, n)
}

func (c *captureNotifier) byType(t notify.EventType) []notify.Notification {
	c.mu.Lock()
	defer c.mu.Unlock()
	out := []notify.Notification{}
	for _, e := range c.events {
		if e.Type == t {
			out = append(out, e)
		}
	}
	return out
}

func newSvcWithCapture() (*application.Service, *captureNotifier) {
	cap := &captureNotifier{}
	s := application.NewService(memrepo.NewRepository(), application.WithNotifier(cap))
	return s, cap
}

func TestNotifier_FriendRequestFires(t *testing.T) {
	s, cap := newSvcWithCapture()
	a, _ := s.RegisterEmail(application.EmailRegisterInput{Email: "a@x.io", Password: "abcdefgh", DisplayName: "A"})
	b, _ := s.RegisterEmail(application.EmailRegisterInput{Email: "b@x.io", Password: "abcdefgh", DisplayName: "B"})

	if _, err := s.RequestFriend(a.User.ID, b.User.ID); err != nil {
		t.Fatalf("request friend: %v", err)
	}
	// Filtrar a eventos cuyo target es b — el seed dispara otros eventos
	// de friend_requested entre los users seed.
	matching := 0
	for _, e := range cap.byType(notify.EventFriendRequested) {
		if e.UserID == b.User.ID {
			matching++
		}
	}
	if matching != 1 {
		t.Fatalf("expected 1 friend_requested for %s, got %d", b.User.ID, matching)
	}
}

func TestNotifier_FriendAcceptFires(t *testing.T) {
	s, cap := newSvcWithCapture()
	a, _ := s.RegisterEmail(application.EmailRegisterInput{Email: "a@x.io", Password: "abcdefgh", DisplayName: "A"})
	b, _ := s.RegisterEmail(application.EmailRegisterInput{Email: "b@x.io", Password: "abcdefgh", DisplayName: "B"})

	fr, err := s.RequestFriend(a.User.ID, b.User.ID)
	if err != nil {
		t.Fatalf("request: %v", err)
	}
	if _, err := s.AcceptFriend(b.User.ID, fr.ID); err != nil {
		t.Fatalf("accept: %v", err)
	}
	// Filtrar a eventos cuyo target es a (el requester).
	matching := 0
	for _, e := range cap.byType(notify.EventFriendAccepted) {
		if e.UserID == a.User.ID {
			matching++
		}
	}
	if matching != 1 {
		t.Fatalf("expected 1 friend_accepted for %s, got %d", a.User.ID, matching)
	}
}
