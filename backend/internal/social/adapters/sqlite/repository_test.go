package sqlite_test

import (
	"path/filepath"
	"testing"
	"time"

	sqliterepo "github.com/Jeudry/memorizar/backend/internal/social/adapters/sqlite"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

func newTestRepo(t *testing.T) *sqliterepo.Repository {
	t.Helper()
	path := filepath.Join(t.TempDir(), "test.db")
	repo, err := sqliterepo.Open(path)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	t.Cleanup(func() { _ = repo.Close() })
	return repo
}

func TestUserCRUD(t *testing.T) {
	repo := newTestRepo(t)
	now := time.Now().UTC()
	u := domain.User{
		ID:          "usr_a",
		Email:       "a@x.io",
		DisplayName: "Alice",
		Providers:   map[string]string{"google": "g123"},
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := repo.SaveUser(u); err != nil {
		t.Fatalf("save: %v", err)
	}
	got, err := repo.FindUserByID("usr_a")
	if err != nil || got == nil {
		t.Fatalf("find by id: %v", err)
	}
	if got.Email != "a@x.io" || got.DisplayName != "Alice" {
		t.Errorf("got %+v", got)
	}
	if got.Providers["google"] != "g123" {
		t.Errorf("providers lost: %+v", got.Providers)
	}

	byEmail, err := repo.FindUserByEmail("a@x.io")
	if err != nil || byEmail == nil {
		t.Fatalf("by email: %v", err)
	}
	if byEmail.ID != "usr_a" {
		t.Errorf("wrong user")
	}

	byProvider, err := repo.FindUserByProvider("google", "g123")
	if err != nil || byProvider == nil || byProvider.ID != "usr_a" {
		t.Errorf("by provider: %v %+v", err, byProvider)
	}
}

func TestFriendshipsByStatus(t *testing.T) {
	repo := newTestRepo(t)
	now := time.Now().UTC()
	for _, id := range []string{"u1", "u2", "u3"} {
		_ = repo.SaveUser(domain.User{ID: id, Email: id + "@x.io", CreatedAt: now, UpdatedAt: now})
	}
	_ = repo.SaveFriendship(domain.Friendship{
		ID: "f1", RequesterID: "u1", AddresseeID: "u2",
		Status: domain.FriendshipPending, CreatedAt: now, UpdatedAt: now,
	})
	_ = repo.SaveFriendship(domain.Friendship{
		ID: "f2", RequesterID: "u1", AddresseeID: "u3",
		Status: domain.FriendshipAccepted, CreatedAt: now, UpdatedAt: now,
	})
	pending, _ := repo.ListFriendships("u1", domain.FriendshipPending)
	if len(pending) != 1 || pending[0].ID != "f1" {
		t.Errorf("pending: %+v", pending)
	}
	accepted, _ := repo.ListFriendships("u1", domain.FriendshipAccepted)
	if len(accepted) != 1 || accepted[0].ID != "f2" {
		t.Errorf("accepted: %+v", accepted)
	}
}

func TestDeleteUserCascade(t *testing.T) {
	repo := newTestRepo(t)
	now := time.Now().UTC()
	_ = repo.SaveUser(domain.User{ID: "u1", Email: "a@x.io", CreatedAt: now, UpdatedAt: now})
	_ = repo.SaveUser(domain.User{ID: "u2", Email: "b@x.io", CreatedAt: now, UpdatedAt: now})
	_ = repo.SaveFriendship(domain.Friendship{
		ID: "f1", RequesterID: "u1", AddresseeID: "u2",
		Status: domain.FriendshipAccepted, CreatedAt: now, UpdatedAt: now,
	})
	_ = repo.SaveSession(domain.Session{
		Token: "tk", UserID: "u1", Provider: domain.ProviderGoogle,
		CreatedAt: now, ExpiresAt: now.Add(24 * time.Hour),
	})

	if err := repo.DeleteUserCascade("u1"); err != nil {
		t.Fatalf("delete: %v", err)
	}
	if u, _ := repo.FindUserByID("u1"); u != nil {
		t.Error("user still exists")
	}
	if s, _ := repo.FindSession("tk"); s != nil {
		t.Error("session not cascaded")
	}
	if fs, _ := repo.ListFriendships("u2", domain.FriendshipAccepted); len(fs) != 0 {
		t.Error("friendship not cleaned")
	}
}

func TestProgressSnapshot(t *testing.T) {
	repo := newTestRepo(t)
	now := time.Now().UTC()
	_ = repo.SaveUser(domain.User{ID: "u1", Email: "a@x.io", CreatedAt: now, UpdatedAt: now})
	older := domain.ProgressSnapshot{
		ID: "s1", UserID: "u1", DeviceID: "d1",
		PayloadJSON: `{"v":1}`,
		CapturedAt:  now.Add(-1 * time.Hour),
	}
	newer := domain.ProgressSnapshot{
		ID: "s2", UserID: "u1", DeviceID: "d2",
		PayloadJSON: `{"v":2}`,
		CapturedAt:  now,
	}
	_ = repo.SaveProgressSnapshot(older)
	_ = repo.SaveProgressSnapshot(newer)
	got, err := repo.FindLatestProgressSnapshot("u1")
	if err != nil {
		t.Fatalf("find: %v", err)
	}
	if got == nil || got.ID != "s2" {
		t.Errorf("got %+v", got)
	}
}
