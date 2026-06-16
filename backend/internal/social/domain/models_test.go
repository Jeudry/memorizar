package domain

import "testing"

func TestPublicProfileOmitsEmail(t *testing.T) {
	u := User{
		ID: "u1", Email: "secret@x.io", DisplayName: "Alice",
		Username: "alice", PasswordHash: "hash", Age: 30,
	}
	p := u.PublicProfile()
	if p.Email != "" {
		t.Errorf("PublicProfile leaked email: %q", p.Email)
	}
	if p.PasswordHash != "" {
		t.Errorf("PublicProfile leaked password hash")
	}
	// Campos públicos se conservan.
	if p.ID != "u1" || p.DisplayName != "Alice" || p.Username != "alice" || p.Age != 30 {
		t.Errorf("PublicProfile dropped public fields: %+v", p)
	}
	// El original no se muta.
	if u.Email == "" {
		t.Errorf("PublicProfile mutated the receiver")
	}
}
