package sqlite

import "testing"

func TestBuildDSN(t *testing.T) {
	cases := []struct {
		path string
		sep  string
	}{
		{"data/memorizar.db", "?"},
		{"file:memdb?mode=memory&cache=shared", "&"},
	}
	for _, c := range cases {
		got := buildDSN(c.path)
		wantPrefix := c.path + c.sep + "_pragma="
		if len(got) < len(wantPrefix) || got[:len(wantPrefix)] != wantPrefix {
			t.Errorf("buildDSN(%q) = %q, want prefix %q", c.path, got, wantPrefix)
		}
		for _, pragma := range []string{"busy_timeout(5000)", "journal_mode(WAL)", "foreign_keys(ON)"} {
			if !contains(got, pragma) {
				t.Errorf("buildDSN(%q) missing %q: %q", c.path, pragma, got)
			}
		}
	}
}

func contains(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}
