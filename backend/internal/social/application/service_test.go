package application

import (
	"testing"

	"github.com/Jeudry/memorizar/backend/internal/social/adapters/memory"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

func TestSocialLoginCreatesUserAndSession(t *testing.T) {
	service := NewService(memory.NewRepository())

	out, err := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "google-123",
		Email:          "test@example.com",
		DisplayName:    "Test User",
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if out.User.ID == "" {
		t.Fatal("expected user id")
	}
	if out.Session.Token == "" {
		t.Fatal("expected session token")
	}
}

func TestFriendFeedReturnsMixedEntriesAndAllowsReactions(t *testing.T) {
	service := NewService(memory.NewRepository())

	me, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "me-google",
		Email:          "me@example.com",
		DisplayName:    "Me",
	})
	friend, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderApple,
		ProviderUserID: "friend-apple",
		Email:          "friend@example.com",
		DisplayName:    "Friend",
	})
	request, err := service.RequestFriend(friend.User.ID, me.User.ID)
	if err != nil {
		t.Fatalf("request friend: %v", err)
	}
	if _, err := service.AcceptFriend(me.User.ID, request.ID); err != nil {
		t.Fatalf("accept friend: %v", err)
	}
	if _, err := service.RecordAchievement(friend.User.ID, "clean_finish", "Terminó limpio", "Cerró sin errores.", "Salmo 23", "✨"); err != nil {
		t.Fatalf("record achievement: %v", err)
	}
	if _, err := service.RecordActivity(friend.User.ID, "studying_now", "Está memorizando", "Sigue memorizando Salmo 23.", "Salmo 23"); err != nil {
		t.Fatalf("record activity: %v", err)
	}

	share, err := service.ShareResource(friend.User.ID, ShareResourceInput{
		Kind:        domain.ShareKindPlan,
		Title:       "Plan público",
		Summary:     "Plan suave",
		PayloadJSON: `{"hello":"world"}`,
		IsPublic:    true,
	})
	if err != nil {
		t.Fatalf("share resource: %v", err)
	}

	feed, err := service.BuildFeed(me.User.ID)
	if err != nil {
		t.Fatalf("build feed: %v", err)
	}
	if len(feed) < 3 {
		t.Fatalf("expected mixed feed entries, got %d", len(feed))
	}
	if _, err := service.AddReaction(me.User.ID, share.ID, "👏"); err != nil {
		t.Fatalf("add reaction: %v", err)
	}
	if _, err := service.AddComment(me.User.ID, share.ID, "Qué bonito plan."); err != nil {
		t.Fatalf("add comment: %v", err)
	}

	updatedFeed, err := service.BuildFeed(me.User.ID)
	if err != nil {
		t.Fatalf("build updated feed: %v", err)
	}
	for _, entry := range updatedFeed {
		if entry.ID == share.ID {
			if len(entry.Reactions) != 1 {
				t.Fatalf("expected reaction on share entry, got %d", len(entry.Reactions))
			}
			if len(entry.Comments) != 1 {
				t.Fatalf("expected comment on share entry, got %d", len(entry.Comments))
			}
			return
		}
	}
	t.Fatal("expected share entry in updated feed")
}

func TestProgressSnapshotRoundTrip(t *testing.T) {
	service := NewService(memory.NewRepository())

	me, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "progress-google",
		Email:          "progress@example.com",
		DisplayName:    "Progress",
	})
	saved, err := service.SaveProgressSnapshot(me.User.ID, ProgressSyncInput{
		DeviceID:    "device-a",
		PayloadJSON: `{"decks":[{"id":"deck-1"}],"goals":[{"id":"goal-1"}],"journeys":[]}`,
	})
	if err != nil {
		t.Fatalf("save progress snapshot: %v", err)
	}
	if saved.ID == "" {
		t.Fatal("expected snapshot id")
	}
	loaded, err := service.GetLatestProgressSnapshot(me.User.ID)
	if err != nil {
		t.Fatalf("get latest snapshot: %v", err)
	}
	if loaded == nil || loaded.PayloadJSON == "" {
		t.Fatal("expected saved snapshot")
	}
}

func TestCommunityPublishImportAndStats(t *testing.T) {
	service := NewService(memory.NewRepository())

	owner, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "owner-google",
		Email:          "owner@example.com",
		DisplayName:    "Owner",
	})
	importer, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderApple,
		ProviderUserID: "importer-apple",
		Email:          "importer@example.com",
		DisplayName:    "Importer",
	})

	share, err := service.ShareResource(owner.User.ID, ShareResourceInput{
		Kind:        domain.ShareKindDeck,
		DeckID:      "deck-1",
		Title:       "Versículos de fe",
		Summary:     "Mis favoritos",
		PayloadJSON: `{"cards":[{"front":"a","back":"b"}]}`,
		IsPublic:    true,
	})
	if err != nil {
		t.Fatalf("share resource: %v", err)
	}

	// Republicar el mismo deck no debe duplicar la publicación.
	republished, err := service.ShareResource(owner.User.ID, ShareResourceInput{
		Kind:        domain.ShareKindDeck,
		DeckID:      "deck-1",
		Title:       "Versículos de fe v2",
		Summary:     "Actualizado",
		PayloadJSON: `{"cards":[{"front":"a","back":"b"},{"front":"c","back":"d"}]}`,
		IsPublic:    true,
	})
	if err != nil {
		t.Fatalf("republish: %v", err)
	}
	if republished.ID != share.ID {
		t.Fatalf("expected republish to reuse share id %s, got %s", share.ID, republished.ID)
	}

	// Importaciones: idempotentes por usuario y el dueño no cuenta.
	if err := service.RegisterCommunityImport(importer.User.ID, share.ID); err != nil {
		t.Fatalf("register import: %v", err)
	}
	if err := service.RegisterCommunityImport(importer.User.ID, share.ID); err != nil {
		t.Fatalf("repeat import: %v", err)
	}
	if err := service.RegisterCommunityImport(owner.User.ID, share.ID); err != nil {
		t.Fatalf("owner import should be a no-op: %v", err)
	}

	mine, err := service.ListOwnedCommunityDecks(owner.User.ID)
	if err != nil {
		t.Fatalf("list owned: %v", err)
	}
	if len(mine) != 1 {
		t.Fatalf("expected 1 owned community deck, got %d", len(mine))
	}
	if mine[0].Title != "Versículos de fe v2" {
		t.Fatalf("expected updated title, got %q", mine[0].Title)
	}
	if mine[0].ImportCount != 1 {
		t.Fatalf("expected 1 import, got %d", mine[0].ImportCount)
	}

	if _, err := service.ShareResource(owner.User.ID, ShareResourceInput{
		Kind:        domain.ShareKindDeck,
		DeckID:      "deck-2",
		Title:       "   ",
		PayloadJSON: `{"cards":[]}`,
		IsPublic:    true,
	}); err != ErrMissingTitle {
		t.Fatalf("expected ErrMissingTitle for blank public title, got %v", err)
	}
}

func TestCommunityOverviewAggregatesRealData(t *testing.T) {
	service := NewService(memory.NewRepository())

	owner, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "ov-owner",
		Email:          "ov-owner@example.com",
		DisplayName:    "Creadora",
	})
	importer, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderApple,
		ProviderUserID: "ov-importer",
		Email:          "ov-importer@example.com",
		DisplayName:    "Lectora",
	})

	bible, _ := service.ShareResource(owner.User.ID, ShareResourceInput{
		Kind: domain.ShareKindDeck, DeckID: "d1", Title: "Salmos",
		PayloadJSON: `{"icon":"✝️","cards":[{"front":"a","back":"b"}]}`, IsPublic: true,
	})
	_, _ = service.ShareResource(owner.User.ID, ShareResourceInput{
		Kind: domain.ShareKindDeck, DeckID: "d2", Title: "Inglés",
		PayloadJSON: `{"icon":"🌍","cards":[{"front":"a","back":"b"}]}`, IsPublic: true,
	})

	if err := service.RegisterCommunityImport(importer.User.ID, bible.ID); err != nil {
		t.Fatalf("import: %v", err)
	}

	overview, err := service.CommunityOverview(importer.User.ID)
	if err != nil {
		t.Fatalf("overview: %v", err)
	}
	if overview.TotalDecks != 2 {
		t.Fatalf("expected 2 public decks, got %d", overview.TotalDecks)
	}
	if len(overview.Featured) == 0 || overview.Featured[0].ID != bible.ID {
		t.Fatalf("expected the imported deck first in featured, got %+v", overview.Featured)
	}
	if overview.Popular[0].ImportCount != 1 {
		t.Fatalf("expected popular leader with 1 import, got %d", overview.Popular[0].ImportCount)
	}
	if len(overview.Creators) != 1 || overview.Creators[0].DisplayName != "Creadora" ||
		overview.Creators[0].DeckCount != 2 || overview.Creators[0].ImportCount != 1 {
		t.Fatalf("unexpected creators: %+v", overview.Creators)
	}
	foundBibleIcon := false
	for _, category := range overview.Categories {
		if category.Icon == "✝️" && category.Count == 1 {
			foundBibleIcon = true
		}
	}
	if !foundBibleIcon {
		t.Fatalf("expected real category count for ✝️, got %+v", overview.Categories)
	}
}

func TestDeckReportLifecycle(t *testing.T) {
	service := NewService(memory.NewRepository())
	reporter, _ := service.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "rep-user",
		Email:          "rep@example.com",
		DisplayName:    "Reporter",
	})

	report, err := service.FileDeckReport(reporter.User.ID, FileDeckReportInput{
		DeckID:    "deck-x",
		DeckTitle: "Mazo dudoso",
		Reason:    "copyright",
		Note:      "Usa la NVI completa",
	})
	if err != nil {
		t.Fatalf("file report: %v", err)
	}
	if report.Status != domain.ReportStatusPending {
		t.Fatalf("expected pending, got %s", report.Status)
	}

	if _, err := service.FileDeckReport(reporter.User.ID, FileDeckReportInput{
		DeckID: "deck-x", Reason: "nonsense",
	}); err != ErrInvalidReportReason {
		t.Fatalf("expected ErrInvalidReportReason, got %v", err)
	}

	resolved, err := service.ResolveDeckReport(report.ID, "hidden")
	if err != nil {
		t.Fatalf("resolve: %v", err)
	}
	if resolved.Status != domain.ReportStatusResolvedHidden {
		t.Fatalf("expected resolved_hidden, got %s", resolved.Status)
	}

	reports, err := service.ListDeckReports()
	if err != nil || len(reports) != 1 {
		t.Fatalf("expected 1 report, got %d (%v)", len(reports), err)
	}
}
