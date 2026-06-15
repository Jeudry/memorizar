package ports

import (
	"time"

	"github.com/Jeudry/memorizar/backend/internal/social/domain"
)

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
	FindSharedResource(id string) (*domain.SharedResource, error)
	DeleteSharedResource(id string) error

	SaveShareImport(shareImport domain.ShareImport) error
	CountShareImports(shareIDs []string) (map[string]int, error)
	CountShareImportsSince(shareIDs []string, since time.Time) (map[string]int, error)

	SaveDeckLike(shareID, userID string, createdAt time.Time) error
	DeleteDeckLike(shareID, userID string) error
	CountDeckLikes(shareIDs []string) (map[string]int, error)
	ListLikedShareIDsByUser(userID string) ([]string, error)

	SaveDeckReport(report domain.DeckReport) error
	FindDeckReportByID(reportID string) (*domain.DeckReport, error)
	ListDeckReports() ([]domain.DeckReport, error)

	SaveAnalyticsEvents(events []domain.AnalyticsEvent) error
	CountAnalyticsEventsByName() (map[string]int, error)

	SavePremiumSubscription(subscription domain.PremiumSubscription) error
	FindPremiumSubscription(userID string) (*domain.PremiumSubscription, error)

	SavePushToken(token domain.PushToken) error

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
