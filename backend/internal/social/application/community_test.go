package application

import (
	"errors"
	"testing"

	"github.com/Jeudry/memorizar/backend/internal/social/adapters/memory"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

// makeUser registra un usuario por email y devuelve su ID. Usa el flujo
// público (RegisterEmail) para mantener el setup consistente con los demás
// tests del paquete.
func makeUser(t *testing.T, s *Service, email, username, displayName string) string {
	t.Helper()
	out, err := s.RegisterEmail(EmailRegisterInput{
		Email:       email,
		Password:    "abcdefgh",
		DisplayName: displayName,
		Username:    username,
		Age:         25,
	})
	if err != nil {
		t.Fatalf("register %s: %v", email, err)
	}
	return out.User.ID
}

// publishDeck publica un deck público para el usuario y devuelve el shareID.
func publishDeck(t *testing.T, s *Service, userID, deckID, title, payload string) string {
	t.Helper()
	share, err := s.ShareResource(userID, ShareResourceInput{
		Kind:        domain.ShareKindDeck,
		DeckID:      deckID,
		Title:       title,
		PayloadJSON: payload,
		IsPublic:    true,
	})
	if err != nil {
		t.Fatalf("publish deck %s: %v", deckID, err)
	}
	return share.ID
}

// ─── UnpublishSharedResource ──────────────────────────────────────────────

func TestUnpublishSharedResource_OwnerRemovesIt(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner@dev.io", "owner_u", "Owner")

	shareID := publishDeck(t, s, owner, "deck-1", "Versículos", `{"icon":"✝️"}`)

	// El recurso existe antes de despublicar.
	if got, err := s.repo.FindSharedResource(shareID); err != nil || got == nil {
		t.Fatalf("expected share to exist before unpublish, got %v / %v", got, err)
	}

	if err := s.UnpublishSharedResource(owner, shareID); err != nil {
		t.Fatalf("unpublish as owner: %v", err)
	}

	got, err := s.repo.FindSharedResource(shareID)
	if err != nil {
		t.Fatalf("find after unpublish: %v", err)
	}
	if got != nil {
		t.Fatalf("expected nil share after unpublish, got %+v", got)
	}
}

func TestUnpublishSharedResource_NonOwnerForbidden(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner2@dev.io", "owner_u2", "Owner")
	stranger := makeUser(t, s, "stranger@dev.io", "stranger_u", "Stranger")

	shareID := publishDeck(t, s, owner, "deck-1", "Versículos", `{"icon":"✝️"}`)

	if err := s.UnpublishSharedResource(stranger, shareID); !errors.Is(err, ErrShareNotFound) {
		t.Fatalf("expected ErrShareNotFound for non-owner, got %v", err)
	}

	// El recurso sigue existiendo tras el intento del no-dueño.
	if got, err := s.repo.FindSharedResource(shareID); err != nil || got == nil {
		t.Fatalf("expected share to survive non-owner attempt, got %v / %v", got, err)
	}
}

func TestUnpublishSharedResource_UnknownShareID(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner3@dev.io", "owner_u3", "Owner")

	if err := s.UnpublishSharedResource(owner, ""); !errors.Is(err, ErrShareNotFound) {
		t.Fatalf("expected ErrShareNotFound for empty shareID, got %v", err)
	}
	if err := s.UnpublishSharedResource(owner, "shr_does_not_exist"); !errors.Is(err, ErrShareNotFound) {
		t.Fatalf("expected ErrShareNotFound for unknown shareID, got %v", err)
	}
}

// ─── ToggleDeckLike ───────────────────────────────────────────────────────

func TestToggleDeckLike_TogglesAndCounts(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner@dev.io", "owner_u", "Owner")
	liker := makeUser(t, s, "liker@dev.io", "liker_u", "Liker")

	shareID := publishDeck(t, s, owner, "deck-1", "Versículos", `{"icon":"✝️"}`)

	// Primer like → liked=true, count=1.
	liked, count, err := s.ToggleDeckLike(liker, shareID)
	if err != nil {
		t.Fatalf("first like: %v", err)
	}
	if !liked || count != 1 {
		t.Fatalf("expected (true, 1), got (%v, %d)", liked, count)
	}

	// Segundo toggle → liked=false, count=0.
	liked, count, err = s.ToggleDeckLike(liker, shareID)
	if err != nil {
		t.Fatalf("second toggle: %v", err)
	}
	if liked || count != 0 {
		t.Fatalf("expected (false, 0), got (%v, %d)", liked, count)
	}

	// Tercer toggle → liked=true, count=1.
	liked, count, err = s.ToggleDeckLike(liker, shareID)
	if err != nil {
		t.Fatalf("third toggle: %v", err)
	}
	if !liked || count != 1 {
		t.Fatalf("expected (true, 1), got (%v, %d)", liked, count)
	}
}

func TestToggleDeckLike_NonPublicShareNotFound(t *testing.T) {
	s := NewService(memory.NewRepository())
	liker := makeUser(t, s, "liker@dev.io", "liker_u", "Liker")

	if _, _, err := s.ToggleDeckLike(liker, ""); !errors.Is(err, ErrShareNotFound) {
		t.Fatalf("expected ErrShareNotFound for empty shareID, got %v", err)
	}
	if _, _, err := s.ToggleDeckLike(liker, "shr_unknown"); !errors.Is(err, ErrShareNotFound) {
		t.Fatalf("expected ErrShareNotFound for unknown share, got %v", err)
	}
}

func TestToggleDeckLike_TwoUsersAccumulate(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner@dev.io", "owner_u", "Owner")
	a := makeUser(t, s, "a@dev.io", "user_a", "A")
	b := makeUser(t, s, "b@dev.io", "user_b", "B")

	shareID := publishDeck(t, s, owner, "deck-1", "Versículos", `{"icon":"✝️"}`)

	if _, count, err := s.ToggleDeckLike(a, shareID); err != nil || count != 1 {
		t.Fatalf("first user like: count=%d err=%v", count, err)
	}
	liked, count, err := s.ToggleDeckLike(b, shareID)
	if err != nil {
		t.Fatalf("second user like: %v", err)
	}
	if !liked || count != 2 {
		t.Fatalf("expected (true, 2) for two distinct likers, got (%v, %d)", liked, count)
	}
}

// ─── ToggleFollow ─────────────────────────────────────────────────────────

func TestToggleFollow_TogglesAndCounts(t *testing.T) {
	s := NewService(memory.NewRepository())
	follower := makeUser(t, s, "follower@dev.io", "follower_u", "Follower")
	creator := makeUser(t, s, "creator@dev.io", "creator_u", "Creator")

	following, count, err := s.ToggleFollow(follower, creator)
	if err != nil {
		t.Fatalf("follow: %v", err)
	}
	if !following || count != 1 {
		t.Fatalf("expected (true, 1), got (%v, %d)", following, count)
	}

	following, count, err = s.ToggleFollow(follower, creator)
	if err != nil {
		t.Fatalf("unfollow: %v", err)
	}
	if following || count != 0 {
		t.Fatalf("expected (false, 0), got (%v, %d)", following, count)
	}
}

func TestToggleFollow_SelfForbidden(t *testing.T) {
	s := NewService(memory.NewRepository())
	me := makeUser(t, s, "me@dev.io", "me_u", "Me")

	if _, _, err := s.ToggleFollow(me, me); !errors.Is(err, ErrUserNotFound) {
		t.Fatalf("expected ErrUserNotFound following self, got %v", err)
	}
}

func TestToggleFollow_UnknownCreator(t *testing.T) {
	s := NewService(memory.NewRepository())
	follower := makeUser(t, s, "follower@dev.io", "follower_u", "Follower")

	if _, _, err := s.ToggleFollow(follower, "usr_unknown"); !errors.Is(err, ErrUserNotFound) {
		t.Fatalf("expected ErrUserNotFound for unknown creator, got %v", err)
	}
	if _, _, err := s.ToggleFollow(follower, ""); !errors.Is(err, ErrUserNotFound) {
		t.Fatalf("expected ErrUserNotFound for empty creator, got %v", err)
	}
}

// ─── IsModerator ──────────────────────────────────────────────────────────

func TestIsModerator_FalseByDefault(t *testing.T) {
	s := NewService(memory.NewRepository())
	user := makeUser(t, s, "plain@dev.io", "plain_u", "Plain")

	if s.IsModerator(user) {
		t.Fatal("expected non-moderator by default")
	}
}

func TestIsModerator_AllowlistEmail(t *testing.T) {
	s := NewService(memory.NewRepository(), WithModeratorEmails([]string{"Mod@Dev.io"}))
	mod := makeUser(t, s, "mod@dev.io", "mod_u", "Mod")
	other := makeUser(t, s, "other@dev.io", "other_u", "Other")

	if !s.IsModerator(mod) {
		t.Fatal("expected allowlisted email to be moderator (case-insensitive)")
	}
	if s.IsModerator(other) {
		t.Fatal("expected non-allowlisted email to not be moderator")
	}
}

func TestIsModerator_PersistedFlag(t *testing.T) {
	repo := memory.NewRepository()
	s := NewService(repo)
	userID := makeUser(t, s, "flagged@dev.io", "flagged_u", "Flagged")

	user, err := repo.FindUserByID(userID)
	if err != nil || user == nil {
		t.Fatalf("find user: %v", err)
	}
	user.IsModerator = true
	if err := repo.SaveUser(*user); err != nil {
		t.Fatalf("save moderator flag: %v", err)
	}

	if !s.IsModerator(userID) {
		t.Fatal("expected persisted IsModerator flag to grant moderation")
	}
}

// ─── SearchCommunityDecks ─────────────────────────────────────────────────

func TestSearchCommunityDecks_FilterByCategory(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner@dev.io", "owner_u", "Owner")
	searcher := makeUser(t, s, "searcher@dev.io", "searcher_u", "Searcher")

	bibleID := publishDeck(t, s, owner, "deck-bible", "Salmos", `{"icon":"✝️"}`)
	worldID := publishDeck(t, s, owner, "deck-world", "Inglés", `{"icon":"🌍"}`)

	// Categoría "✝️" devuelve solo el deck bíblico.
	bibleOnly, err := s.SearchCommunityDecks(searcher, "", "✝️")
	if err != nil {
		t.Fatalf("search by category: %v", err)
	}
	if len(bibleOnly) != 1 || bibleOnly[0].ID != bibleID {
		t.Fatalf("expected only the ✝️ deck, got %+v", bibleOnly)
	}

	// Categoría vacía devuelve ambos (excluyendo los del propio searcher).
	all, err := s.SearchCommunityDecks(searcher, "", "")
	if err != nil {
		t.Fatalf("search all: %v", err)
	}
	if len(all) != 2 {
		t.Fatalf("expected 2 decks for empty category, got %d", len(all))
	}
	_ = worldID
}

func TestSearchCommunityDecks_ExcludesOwnDecks(t *testing.T) {
	s := NewService(memory.NewRepository())
	searcher := makeUser(t, s, "searcher@dev.io", "searcher_u", "Searcher")
	other := makeUser(t, s, "other@dev.io", "other_u", "Other")

	_ = publishDeck(t, s, searcher, "mine", "Mío", `{"icon":"✝️"}`)
	othersID := publishDeck(t, s, other, "theirs", "Ajeno", `{"icon":"✝️"}`)

	results, err := s.SearchCommunityDecks(searcher, "", "")
	if err != nil {
		t.Fatalf("search: %v", err)
	}
	if len(results) != 1 || results[0].ID != othersID {
		t.Fatalf("expected only other users' decks, got %+v", results)
	}
}

// attachCommunityStats ejercitado indirectamente: el resultado de la búsqueda
// debe reflejar LikeCount y LikedByMe tras un like del propio searcher.
func TestSearchCommunityDecks_CarriesLikeStats(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "owner@dev.io", "owner_u", "Owner")
	searcher := makeUser(t, s, "searcher@dev.io", "searcher_u", "Searcher")

	shareID := publishDeck(t, s, owner, "deck-1", "Salmos", `{"icon":"✝️"}`)

	if _, count, err := s.ToggleDeckLike(searcher, shareID); err != nil || count != 1 {
		t.Fatalf("like: count=%d err=%v", count, err)
	}

	results, err := s.SearchCommunityDecks(searcher, "", "")
	if err != nil {
		t.Fatalf("search: %v", err)
	}
	if len(results) != 1 {
		t.Fatalf("expected 1 result, got %d", len(results))
	}
	if results[0].LikeCount != 1 {
		t.Fatalf("expected LikeCount=1, got %d", results[0].LikeCount)
	}
	if !results[0].LikedByMe {
		t.Fatal("expected LikedByMe=true for the searcher who liked it")
	}
}

func TestListLikedCommunityDecks(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "o2@dev.io", "o2_u", "Owner2")
	liker := makeUser(t, s, "l2@dev.io", "l2_u", "Liker2")
	share := publishDeck(t, s, owner, "deck-x", "Liked deck", `{"icon":"📚"}`)

	liked, err := s.ListLikedCommunityDecks(liker)
	if err != nil {
		t.Fatalf("list (empty): %v", err)
	}
	if len(liked) != 0 {
		t.Fatalf("expected 0 liked decks, got %d", len(liked))
	}

	if _, _, err := s.ToggleDeckLike(liker, share); err != nil {
		t.Fatalf("like: %v", err)
	}
	liked, err = s.ListLikedCommunityDecks(liker)
	if err != nil {
		t.Fatalf("list (after like): %v", err)
	}
	if len(liked) != 1 || liked[0].Title != "Liked deck" {
		t.Fatalf("expected 1 deck 'Liked deck', got %+v", liked)
	}
	if !liked[0].LikedByMe || liked[0].LikeCount != 1 {
		t.Errorf("expected LikedByMe + LikeCount=1, got %+v", liked[0])
	}

	if _, _, err := s.ToggleDeckLike(liker, share); err != nil {
		t.Fatalf("unlike: %v", err)
	}
	liked, _ = s.ListLikedCommunityDecks(liker)
	if len(liked) != 0 {
		t.Fatalf("after unlike expected 0, got %d", len(liked))
	}
}

func TestNotificationsFromLikeAndMarkRead(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "own@dev.io", "own_u", "Owner")
	liker := makeUser(t, s, "lik@dev.io", "lik_u", "Liker")
	share := publishDeck(t, s, owner, "deck-n", "Notif deck", `{"icon":"🔔"}`)

	// El dueño aún no tiene notificaciones.
	items, unread, err := s.ListNotifications(owner, 50)
	if err != nil {
		t.Fatalf("list (empty): %v", err)
	}
	if len(items) != 0 || unread != 0 {
		t.Fatalf("expected no notifications, got %d items / %d unread", len(items), unread)
	}

	// Like → el dueño recibe una notificación deck_liked sin leer.
	if _, _, err := s.ToggleDeckLike(liker, share); err != nil {
		t.Fatalf("like: %v", err)
	}
	items, unread, err = s.ListNotifications(owner, 50)
	if err != nil {
		t.Fatalf("list (after like): %v", err)
	}
	if len(items) != 1 || unread != 1 {
		t.Fatalf("expected 1 unread notification, got %d items / %d unread", len(items), unread)
	}
	if items[0].Type != "deck_liked" || items[0].Read {
		t.Errorf("expected unread deck_liked, got %+v", items[0])
	}

	// El liker no recibe nada (no se notifica a sí mismo de su propio like).
	if _, u, _ := s.ListNotifications(liker, 50); u != 0 {
		t.Errorf("liker should have 0 unread, got %d", u)
	}

	// Marcar leídas → unread vuelve a 0.
	newUnread, err := s.MarkNotificationsRead(owner, nil)
	if err != nil {
		t.Fatalf("mark read: %v", err)
	}
	if newUnread != 0 {
		t.Errorf("expected 0 unread after mark-all-read, got %d", newUnread)
	}
}

func TestRateDeckAndReviews(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "ro@dev.io", "ro_u", "Owner")
	r1 := makeUser(t, s, "r1@dev.io", "r1_u", "Rater One")
	r2 := makeUser(t, s, "r2@dev.io", "r2_u", "Rater Two")
	share := publishDeck(t, s, owner, "deck-r", "Rated deck", `{"icon":"⭐"}`)

	// Estrellas inválidas y valorar propio mazo se rechazan.
	if _, _, err := s.RateDeck(r1, share, 0, ""); err != ErrInvalidRating {
		t.Errorf("expected ErrInvalidRating, got %v", err)
	}
	if _, _, err := s.RateDeck(owner, share, 5, ""); err != ErrCannotRateOwn {
		t.Errorf("expected ErrCannotRateOwn, got %v", err)
	}

	// Dos valoraciones → promedio (4+2)/2 = 3.
	if avg, count, err := s.RateDeck(r1, share, 4, "Muy bueno"); err != nil || count != 1 || avg != 4 {
		t.Fatalf("rate r1: avg=%v count=%v err=%v", avg, count, err)
	}
	if avg, count, err := s.RateDeck(r2, share, 2, "Regular"); err != nil || count != 2 || avg != 3 {
		t.Fatalf("rate r2: avg=%v count=%v err=%v", avg, count, err)
	}

	// Re-valorar de r1 actualiza (no suma): 5+2 → avg 3.5, count sigue 2.
	if avg, count, err := s.RateDeck(r1, share, 5, "Mejoró"); err != nil || count != 2 || avg != 3.5 {
		t.Fatalf("re-rate r1: avg=%v count=%v err=%v", avg, count, err)
	}

	// El stat se adjunta al mazo comunitario, con MyRating del solicitante.
	decks, err := s.SearchCommunityDecks(r2, "Rated", "")
	if err != nil || len(decks) != 1 {
		t.Fatalf("search: %d decks, err=%v", len(decks), err)
	}
	d := decks[0]
	if d.RatingCount != 2 || d.RatingAvg != 3.5 || d.MyRating != 2 {
		t.Errorf("stats: avg=%v count=%v myRating=%v", d.RatingAvg, d.RatingCount, d.MyRating)
	}

	// Las reseñas traen el nombre del autor.
	reviews, err := s.ListDeckReviews(share)
	if err != nil || len(reviews) != 2 {
		t.Fatalf("reviews: %d, err=%v", len(reviews), err)
	}
	names := map[string]bool{}
	for _, rv := range reviews {
		names[rv.ReviewerName] = true
		if rv.Stars < 1 || rv.Stars > 5 {
			t.Errorf("bad stars in review: %+v", rv)
		}
	}
	if !names["Rater One"] || !names["Rater Two"] {
		t.Errorf("reviewer names missing: %v", names)
	}
}

func TestDeckComments(t *testing.T) {
	s := NewService(memory.NewRepository())
	owner := makeUser(t, s, "co@dev.io", "co_u", "Owner")
	c1 := makeUser(t, s, "c1@dev.io", "c1_u", "Commenter One")
	share := publishDeck(t, s, owner, "deck-c", "Commented deck", `{"icon":"💬"}`)

	// Comentario vacío se rechaza.
	if _, err := s.AddDeckComment(c1, share, "   "); err != ErrEmptyComment {
		t.Errorf("expected ErrEmptyComment, got %v", err)
	}
	// Un usuario puede dejar varios comentarios.
	if _, err := s.AddDeckComment(c1, share, "Primer comentario"); err != nil {
		t.Fatalf("comment 1: %v", err)
	}
	if _, err := s.AddDeckComment(c1, share, "Segundo comentario"); err != nil {
		t.Fatalf("comment 2: %v", err)
	}

	comments, err := s.ListDeckComments(share)
	if err != nil || len(comments) != 2 {
		t.Fatalf("list: %d comments, err=%v", len(comments), err)
	}
	if comments[0].AuthorName != "Commenter One" || comments[0].Body == "" {
		t.Errorf("comment view missing author/body: %+v", comments[0])
	}

	// El conteo se adjunta al mazo comunitario.
	decks, err := s.SearchCommunityDecks(c1, "Commented", "")
	if err != nil || len(decks) != 1 {
		t.Fatalf("search: %d, err=%v", len(decks), err)
	}
	if decks[0].CommentCount != 2 {
		t.Errorf("expected CommentCount=2, got %d", decks[0].CommentCount)
	}
}

func TestLeaderboard(t *testing.T) {
	s := NewService(memory.NewRepository())
	me := makeUser(t, s, "me@dev.io", "me_u", "Me")
	f1 := makeUser(t, s, "f1@dev.io", "f1_u", "Friend One")
	f2 := makeUser(t, s, "f2@dev.io", "f2_u", "Friend Two")
	stranger := makeUser(t, s, "st@dev.io", "st_u", "Stranger")

	// me se hace amigo de f1 y f2 (aceptados).
	for _, fr := range []string{f1, f2} {
		req, err := s.RequestFriend(me, fr)
		if err != nil {
			t.Fatalf("request: %v", err)
		}
		if _, err := s.AcceptFriend(fr, req.ID); err != nil {
			t.Fatalf("accept: %v", err)
		}
	}

	if err := s.ReportUserScore(me, 5, 100); err != nil {
		t.Fatalf("score me: %v", err)
	}
	if err := s.ReportUserScore(f1, 10, 300); err != nil {
		t.Fatalf("score f1: %v", err)
	}
	// f2 no reporta puntaje → debe aparecer en 0. stranger NO debe aparecer.
	if err := s.ReportUserScore(stranger, 99, 9999); err != nil {
		t.Fatalf("score stranger: %v", err)
	}

	board, err := s.Leaderboard(me)
	if err != nil {
		t.Fatalf("leaderboard: %v", err)
	}
	if len(board) != 3 {
		t.Fatalf("expected 3 entries (me + 2 friends), got %d", len(board))
	}
	// Orden por puntos: f1 (300) > me (100) > f2 (0).
	if board[0].Username != "f1_u" || board[0].Rank != 1 {
		t.Errorf("rank1 should be f1, got %+v", board[0])
	}
	if !board[1].IsMe || board[1].Points != 100 {
		t.Errorf("rank2 should be me with 100, got %+v", board[1])
	}
	if board[2].Username != "f2_u" || board[2].Points != 0 {
		t.Errorf("rank3 should be f2 with 0, got %+v", board[2])
	}
	for _, e := range board {
		if e.Username == "st_u" {
			t.Error("stranger leaked into leaderboard")
		}
	}
}
