package memory

import (
	"sync"

	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

type Repository struct {
	mu                sync.RWMutex
	users             map[string]domain.User
	sessions          map[string]domain.Session
	friendships       map[string]domain.Friendship
	achievements      map[string]domain.Achievement
	activities        map[string]domain.Activity
	sharedResources   map[string]domain.SharedResource
	reactions         map[string]domain.FeedReaction
	comments          map[string]domain.FeedComment
	progressSnapshots map[string]domain.ProgressSnapshot
}

func NewRepository() *Repository {
	return &Repository{
		users:             map[string]domain.User{},
		sessions:          map[string]domain.Session{},
		friendships:       map[string]domain.Friendship{},
		achievements:      map[string]domain.Achievement{},
		activities:        map[string]domain.Activity{},
		sharedResources:   map[string]domain.SharedResource{},
		reactions:         map[string]domain.FeedReaction{},
		comments:          map[string]domain.FeedComment{},
		progressSnapshots: map[string]domain.ProgressSnapshot{},
	}
}

func (r *Repository) FindUserByProvider(provider domain.SocialProvider, providerUserID string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, user := range r.users {
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
	user, ok := r.users[userID]
	if !ok {
		return nil, nil
	}
	copy := user
	return &copy, nil
}

func (r *Repository) FindUserByEmail(email string) (*domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, user := range r.users {
		if user.Email == email {
			copy := user
			return &copy, nil
		}
	}
	return nil, nil
}

func (r *Repository) ListUsers() ([]domain.User, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := make([]domain.User, 0, len(r.users))
	for _, user := range r.users {
		result = append(result, user)
	}
	return result, nil
}

func (r *Repository) SaveUser(user domain.User) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.users[user.ID] = user
	return nil
}

func (r *Repository) SaveSession(session domain.Session) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sessions[session.Token] = session
	return nil
}

func (r *Repository) FindSession(token string) (*domain.Session, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	session, ok := r.sessions[token]
	if !ok {
		return nil, nil
	}
	copy := session
	return &copy, nil
}

func (r *Repository) SaveFriendship(friendship domain.Friendship) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.friendships[friendship.ID] = friendship
	return nil
}

func (r *Repository) FindFriendship(userA, userB string) (*domain.Friendship, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	for _, friendship := range r.friendships {
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
	for _, friendship := range r.friendships {
		if friendship.Status == status && (friendship.RequesterID == userID || friendship.AddresseeID == userID) {
			result = append(result, friendship)
		}
	}
	return result, nil
}

func (r *Repository) FindFriendshipByID(friendshipID string) (*domain.Friendship, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	friendship, ok := r.friendships[friendshipID]
	if !ok {
		return nil, nil
	}
	copy := friendship
	return &copy, nil
}

func (r *Repository) SaveAchievement(achievement domain.Achievement) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.achievements[achievement.ID] = achievement
	return nil
}

func (r *Repository) ListAchievementsByUserIDs(userIDs []string) ([]domain.Achievement, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(userIDs) == 0 {
		return []domain.Achievement{}, nil
	}
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.Achievement{}
	for _, achievement := range r.achievements {
		if _, ok := allowed[achievement.UserID]; ok {
			result = append(result, achievement)
		}
	}
	return result, nil
}

func (r *Repository) SaveActivity(activity domain.Activity) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.activities[activity.ID] = activity
	return nil
}

func (r *Repository) ListActivitiesByUserIDs(userIDs []string) ([]domain.Activity, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(userIDs) == 0 {
		return []domain.Activity{}, nil
	}
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.Activity{}
	for _, activity := range r.activities {
		if _, ok := allowed[activity.UserID]; ok {
			result = append(result, activity)
		}
	}
	return result, nil
}

func (r *Repository) SaveSharedResource(resource domain.SharedResource) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.sharedResources[resource.ID] = resource
	return nil
}

func (r *Repository) ListSharedResourcesForUser(userID string) ([]domain.SharedResource, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	result := []domain.SharedResource{}
	for _, resource := range r.sharedResources {
		if resource.OwnerUserID == userID || resource.TargetUserID == userID {
			result = append(result, resource)
		}
	}
	return result, nil
}

func (r *Repository) ListPublicSharedResourcesByUserIDs(userIDs []string) ([]domain.SharedResource, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(userIDs) == 0 {
		return []domain.SharedResource{}, nil
	}
	allowed := make(map[string]struct{}, len(userIDs))
	for _, id := range userIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.SharedResource{}
	for _, resource := range r.sharedResources {
		if !resource.IsPublic {
			continue
		}
		if _, ok := allowed[resource.OwnerUserID]; ok {
			result = append(result, resource)
		}
	}
	return result, nil
}

func (r *Repository) SaveReaction(reaction domain.FeedReaction) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.reactions[reaction.ID] = reaction
	return nil
}

func (r *Repository) ListReactionsByEntryIDs(entryIDs []string) ([]domain.FeedReaction, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(entryIDs) == 0 {
		return []domain.FeedReaction{}, nil
	}
	allowed := make(map[string]struct{}, len(entryIDs))
	for _, id := range entryIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.FeedReaction{}
	for _, reaction := range r.reactions {
		if _, ok := allowed[reaction.EntryID]; ok {
			result = append(result, reaction)
		}
	}
	return result, nil
}

func (r *Repository) SaveComment(comment domain.FeedComment) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.comments[comment.ID] = comment
	return nil
}

func (r *Repository) ListCommentsByEntryIDs(entryIDs []string) ([]domain.FeedComment, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if len(entryIDs) == 0 {
		return []domain.FeedComment{}, nil
	}
	allowed := make(map[string]struct{}, len(entryIDs))
	for _, id := range entryIDs {
		allowed[id] = struct{}{}
	}
	result := []domain.FeedComment{}
	for _, comment := range r.comments {
		if _, ok := allowed[comment.EntryID]; ok {
			result = append(result, comment)
		}
	}
	return result, nil
}

func (r *Repository) SaveProgressSnapshot(snapshot domain.ProgressSnapshot) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	current, ok := r.progressSnapshots[snapshot.UserID]
	if !ok || snapshot.CapturedAt.After(current.CapturedAt) {
		r.progressSnapshots[snapshot.UserID] = snapshot
	}
	return nil
}

func (r *Repository) FindLatestProgressSnapshot(userID string) (*domain.ProgressSnapshot, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	snapshot, ok := r.progressSnapshots[userID]
	if !ok {
		return nil, nil
	}
	copy := snapshot
	return &copy, nil
}

func (r *Repository) DeleteUserCascade(userID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	delete(r.users, userID)
	for token, sess := range r.sessions {
		if sess.UserID == userID {
			delete(r.sessions, token)
		}
	}
	for id, f := range r.friendships {
		if f.RequesterID == userID || f.AddresseeID == userID {
			delete(r.friendships, id)
		}
	}
	for id, a := range r.achievements {
		if a.UserID == userID {
			delete(r.achievements, id)
		}
	}
	for id, a := range r.activities {
		if a.UserID == userID {
			delete(r.activities, id)
		}
	}
	for id, s := range r.sharedResources {
		if s.OwnerUserID == userID || s.TargetUserID == userID {
			delete(r.sharedResources, id)
		}
	}
	for id, x := range r.reactions {
		if x.UserID == userID {
			delete(r.reactions, id)
		}
	}
	for id, c := range r.comments {
		if c.UserID == userID {
			delete(r.comments, id)
		}
	}
	delete(r.progressSnapshots, userID)
	return nil
}
