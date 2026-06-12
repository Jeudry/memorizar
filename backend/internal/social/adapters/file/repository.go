package file

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

type state struct {
	Users             map[string]domain.User             `json:"users"`
	Sessions          map[string]domain.Session          `json:"sessions"`
	Friendships       map[string]domain.Friendship       `json:"friendships"`
	Achievements      map[string]domain.Achievement      `json:"achievements"`
	Activities        map[string]domain.Activity         `json:"activities"`
	SharedResources   map[string]domain.SharedResource   `json:"sharedResources"`
	ShareImports      map[string]map[string]domain.ShareImport `json:"shareImports"`
	DeckReports       map[string]domain.DeckReport       `json:"deckReports"`
	AnalyticsEvents   []domain.AnalyticsEvent            `json:"analyticsEvents"`
	PremiumSubs       map[string]domain.PremiumSubscription `json:"premiumSubs"`
	PushTokens        map[string]domain.PushToken        `json:"pushTokens"`
	Reactions         map[string]domain.FeedReaction     `json:"reactions"`
	Comments          map[string]domain.FeedComment      `json:"comments"`
	ProgressSnapshots map[string]domain.ProgressSnapshot `json:"progressSnapshots"`
}

type Repository struct {
	mu    sync.RWMutex
	path  string
	state state
}

func NewRepository(path string) (*Repository, error) {
	repo := &Repository{
		path: path,
		state: state{
			Users:             map[string]domain.User{},
			Sessions:          map[string]domain.Session{},
			Friendships:       map[string]domain.Friendship{},
			Achievements:      map[string]domain.Achievement{},
			Activities:        map[string]domain.Activity{},
			SharedResources:   map[string]domain.SharedResource{},
			ShareImports:      map[string]map[string]domain.ShareImport{},
			DeckReports:       map[string]domain.DeckReport{},
			Reactions:         map[string]domain.FeedReaction{},
			Comments:          map[string]domain.FeedComment{},
			ProgressSnapshots: map[string]domain.ProgressSnapshot{},
		},
	}
	if err := repo.load(); err != nil {
		return nil, err
	}
	return repo, nil
}

func (r *Repository) load() error {
	if err := os.MkdirAll(filepath.Dir(r.path), 0o755); err != nil {
		return err
	}
	data, err := os.ReadFile(r.path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if len(data) == 0 {
		return nil
	}
	return json.Unmarshal(data, &r.state)
}

func (r *Repository) persistLocked() error {
	data, err := json.MarshalIndent(r.state, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(r.path, data, 0o644)
}

func (r *Repository) FindUserByProvider(provider domain.SocialProvider, providerUserID string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, user := range r.state.Users {
		if user.Providers[string(provider)] == providerUserID {
			copy := user
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *Repository) FindUserByID(userID string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	user, ok := r.state.Users[userID]
	if !ok {
		return nil, nil
	}
	copy := user
	return &copy, nil
}

func (r *Repository) FindUserByEmail(email string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, user := range r.state.Users {
		if user.Email == email {
			copy := user
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *Repository) FindUserByUsername(username string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	target := strings.ToLower(strings.TrimSpace(username))
	for _, user := range r.state.Users {
		if strings.ToLower(user.Username) == target {
			copy := user
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *Repository) ListUsers() ([]domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]domain.User, 0, len(r.state.Users))
	for _, user := range r.state.Users {
		result = append(result, user)
	}
	return result, nil
}

func (r *Repository) SaveUser(user domain.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Users[user.ID] = user
	return r.persistLocked()
}

func (r *Repository) SaveSession(session domain.Session) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Sessions[session.Token] = session
	return r.persistLocked()
}

func (r *Repository) FindSession(token string) (*domain.Session, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	session, ok := r.state.Sessions[token]
	if !ok {
		return nil, nil
	}
	copy := session
	return &copy, nil
}

func (r *Repository) SaveFriendship(friendship domain.Friendship) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Friendships[friendship.ID] = friendship
	return r.persistLocked()
}

func (r *Repository) FindFriendship(userA, userB string) (*domain.Friendship, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, friendship := range r.state.Friendships {
		if (friendship.RequesterID == userA && friendship.AddresseeID == userB) ||
			(friendship.RequesterID == userB && friendship.AddresseeID == userA) {
			copy := friendship
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *Repository) ListFriendships(userID string, status domain.FriendshipStatus) ([]domain.Friendship, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := []domain.Friendship{}
	for _, friendship := range r.state.Friendships {
		if friendship.Status == status && (friendship.RequesterID == userID || friendship.AddresseeID == userID) {
			result = append(result, friendship)
		}
	}
	return result, nil
}

func (r *Repository) FindFriendshipByID(friendshipID string) (*domain.Friendship, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	friendship, ok := r.state.Friendships[friendshipID]
	if !ok {
		return nil, nil
	}
	copy := friendship
	return &copy, nil
}

func (r *Repository) SaveAchievement(achievement domain.Achievement) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Achievements[achievement.ID] = achievement
	return r.persistLocked()
}

func (r *Repository) ListAchievementsByUserIDs(userIDs []string) ([]domain.Achievement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.Achievement{}
	for _, achievement := range r.state.Achievements {
		if _, ok := allowed[achievement.UserID]; ok {
			result = append(result, achievement)
		}
	}
	return result, nil
}

func (r *Repository) SaveActivity(activity domain.Activity) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Activities[activity.ID] = activity
	return r.persistLocked()
}

func (r *Repository) ListActivitiesByUserIDs(userIDs []string) ([]domain.Activity, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.Activity{}
	for _, activity := range r.state.Activities {
		if _, ok := allowed[activity.UserID]; ok {
			result = append(result, activity)
		}
	}
	return result, nil
}

func (r *Repository) SaveSharedResource(resource domain.SharedResource) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.SharedResources[resource.ID] = resource
	return r.persistLocked()
}

func (r *Repository) ListSharedResourcesForUser(userID string) ([]domain.SharedResource, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := []domain.SharedResource{}
	for _, resource := range r.state.SharedResources {
		if resource.OwnerUserID == userID || resource.TargetUserID == userID {
			result = append(result, resource)
		}
	}
	return result, nil
}

func (r *Repository) ListPublicSharedResourcesByUserIDs(userIDs []string) ([]domain.SharedResource, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.SharedResource{}
	for _, resource := range r.state.SharedResources {
		if resource.IsPublic {
			if _, ok := allowed[resource.OwnerUserID]; ok {
				result = append(result, resource)
			}
		}
	}
	return result, nil
}

func (r *Repository) SaveShareImport(shareImport domain.ShareImport) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.state.ShareImports == nil {
		// Estados persistidos antes de esta versión no traen el mapa.
		r.state.ShareImports = map[string]map[string]domain.ShareImport{}
	}
	byUser, ok := r.state.ShareImports[shareImport.ShareID]
	if !ok {
		byUser = map[string]domain.ShareImport{}
		r.state.ShareImports[shareImport.ShareID] = byUser
	}
	if _, alreadyImported := byUser[shareImport.UserID]; alreadyImported {
		return nil
	}
	byUser[shareImport.UserID] = shareImport
	return r.persistLocked()
}

func (r *Repository) CountShareImports(shareIDs []string) (map[string]int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	counts := map[string]int{}
	for _, shareID := range shareIDs {
		if byUser, ok := r.state.ShareImports[shareID]; ok {
			counts[shareID] = len(byUser)
		}
	}
	return counts, nil
}

func (r *Repository) CountShareImportsSince(shareIDs []string, since time.Time) (map[string]int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	counts := map[string]int{}
	for _, shareID := range shareIDs {
		byUser, ok := r.state.ShareImports[shareID]
		if !ok {
			continue
		}
		recent := 0
		for _, shareImport := range byUser {
			if !shareImport.CreatedAt.Before(since) {
				recent++
			}
		}
		if recent > 0 {
			counts[shareID] = recent
		}
	}
	return counts, nil
}

func (r *Repository) SavePushToken(token domain.PushToken) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.state.PushTokens == nil {
		r.state.PushTokens = map[string]domain.PushToken{}
	}
	r.state.PushTokens[token.UserID+"|"+token.Token] = token
	return r.persistLocked()
}

func (r *Repository) SavePremiumSubscription(subscription domain.PremiumSubscription) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.state.PremiumSubs == nil {
		r.state.PremiumSubs = map[string]domain.PremiumSubscription{}
	}
	r.state.PremiumSubs[subscription.UserID] = subscription
	return r.persistLocked()
}

func (r *Repository) FindPremiumSubscription(userID string) (*domain.PremiumSubscription, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if subscription, ok := r.state.PremiumSubs[userID]; ok {
		copy := subscription
		return &copy, nil
	}
	return nil, nil
}

func (r *Repository) SaveAnalyticsEvents(events []domain.AnalyticsEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.AnalyticsEvents = append(r.state.AnalyticsEvents, events...)
	return r.persistLocked()
}

func (r *Repository) CountAnalyticsEventsByName() (map[string]int, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	counts := map[string]int{}
	for _, event := range r.state.AnalyticsEvents {
		counts[event.Event]++
	}
	return counts, nil
}

func (r *Repository) SaveDeckReport(report domain.DeckReport) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.state.DeckReports == nil {
		// Estados persistidos antes de esta versión no traen el mapa.
		r.state.DeckReports = map[string]domain.DeckReport{}
	}
	r.state.DeckReports[report.ID] = report
	return r.persistLocked()
}

func (r *Repository) FindDeckReportByID(reportID string) (*domain.DeckReport, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if report, ok := r.state.DeckReports[reportID]; ok {
		copy := report
		return &copy, nil
	}
	return nil, nil
}

func (r *Repository) ListDeckReports() ([]domain.DeckReport, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]domain.DeckReport, 0, len(r.state.DeckReports))
	for _, report := range r.state.DeckReports {
		out = append(out, report)
	}
	return out, nil
}

func (r *Repository) SaveReaction(reaction domain.FeedReaction) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Reactions[reaction.ID] = reaction
	return r.persistLocked()
}

func (r *Repository) ListReactionsByEntryIDs(entryIDs []string) ([]domain.FeedReaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	allowed := make(map[string]struct{}, len(entryIDs))
	for _, id := range entryIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.FeedReaction{}
	for _, reaction := range r.state.Reactions {
		if _, ok := allowed[reaction.EntryID]; ok {
			result = append(result, reaction)
		}
	}
	return result, nil
}

func (r *Repository) SaveComment(comment domain.FeedComment) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.state.Comments[comment.ID] = comment
	return r.persistLocked()
}

func (r *Repository) ListCommentsByEntryIDs(entryIDs []string) ([]domain.FeedComment, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	allowed := make(map[string]struct{}, len(entryIDs))
	for _, id := range entryIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.FeedComment{}
	for _, comment := range r.state.Comments {
		if _, ok := allowed[comment.EntryID]; ok {
			result = append(result, comment)
		}
	}
	return result, nil
}

func (r *Repository) SaveProgressSnapshot(snapshot domain.ProgressSnapshot) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	current, ok := r.state.ProgressSnapshots[snapshot.UserID]
	if !ok || snapshot.CapturedAt.After(current.CapturedAt) {
		r.state.ProgressSnapshots[snapshot.UserID] = snapshot
	}
	return r.persistLocked()
}

func (r *Repository) FindLatestProgressSnapshot(userID string) (*domain.ProgressSnapshot, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	snapshot, ok := r.state.ProgressSnapshots[userID]
	if !ok {
		return nil, nil
	}
	copy := snapshot
	return &copy, nil
}

func (r *Repository) DeleteUserCascade(userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.state.Users, userID)
	for token, sess := range r.state.Sessions {
		if sess.UserID == userID {
			delete(r.state.Sessions, token)
		}
	}
	for id, f := range r.state.Friendships {
		if f.RequesterID == userID || f.AddresseeID == userID {
			delete(r.state.Friendships, id)
		}
	}
	for id, a := range r.state.Achievements {
		if a.UserID == userID {
			delete(r.state.Achievements, id)
		}
	}
	for id, a := range r.state.Activities {
		if a.UserID == userID {
			delete(r.state.Activities, id)
		}
	}
	for id, s := range r.state.SharedResources {
		if s.OwnerUserID == userID || s.TargetUserID == userID {
			delete(r.state.SharedResources, id)
		}
	}
	for id, x := range r.state.Reactions {
		if x.UserID == userID {
			delete(r.state.Reactions, id)
		}
	}
	for id, c := range r.state.Comments {
		if c.UserID == userID {
			delete(r.state.Comments, id)
		}
	}
	delete(r.state.ProgressSnapshots, userID)
	return r.persistLocked()
}
