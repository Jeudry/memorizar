package ports

import "github.com/Jeudry/memorizar/backend/internal/social/domain"

type Repository interface {
	FindUserByProvider(provider domain.SocialProvider, providerUserID string) (*domain.User, error)
	FindUserByID(userID string) (*domain.User, error)
	FindUserByEmail(email string) (*domain.User, error)
	FindUserByUsername(username string) (*domain.User, error)
	ListUsers() ([]domain.User, error)
	SaveUser(user domain.User) error

	SaveSession(session domain.Session) error
	FindSession(token string) (*domain.Session, error)

	SaveFriendship(friendship domain.Friendship) error
	FindFriendship(userA, userB string) (*domain.Friendship, error)
	ListFriendships(userID string, status domain.FriendshipStatus) ([]domain.Friendship, error)
	FindFriendshipByID(friendshipID string) (*domain.Friendship, error)

	SaveAchievement(achievement domain.Achievement) error
	ListAchievementsByUserIDs(userIDs []string) ([]domain.Achievement, error)

	SaveActivity(activity domain.Activity) error
	ListActivitiesByUserIDs(userIDs []string) ([]domain.Activity, error)

	SaveSharedResource(resource domain.SharedResource) error
	ListSharedResourcesForUser(userID string) ([]domain.SharedResource, error)
	ListPublicSharedResourcesByUserIDs(userIDs []string) ([]domain.SharedResource, error)

	SaveReaction(reaction domain.FeedReaction) error
	ListReactionsByEntryIDs(entryIDs []string) ([]domain.FeedReaction, error)

	SaveComment(comment domain.FeedComment) error
	ListCommentsByEntryIDs(entryIDs []string) ([]domain.FeedComment, error)

	SaveProgressSnapshot(snapshot domain.ProgressSnapshot) error
	FindLatestProgressSnapshot(userID string) (*domain.ProgressSnapshot, error)

	// DeleteUserCascade borra al usuario y todos sus datos asociados.
	// Implementaciones de archivo / memoria pueden hacerlo físico; en
	// producción debería ser soft-delete con grace period.
	DeleteUserCascade(userID string) error
}
