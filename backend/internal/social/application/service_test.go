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
