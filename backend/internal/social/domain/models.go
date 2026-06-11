package domain

import "time"

type SocialProvider string

const (
	ProviderGoogle   SocialProvider = "google"
	ProviderApple    SocialProvider = "apple"
	ProviderFacebook SocialProvider = "facebook"
)

type FriendshipStatus string

const (
	FriendshipPending  FriendshipStatus = "pending"
	FriendshipAccepted FriendshipStatus = "accepted"
)

type FeedEntryType string

const (
	FeedEntryAchievement FeedEntryType = "achievement"
	FeedEntryActivity    FeedEntryType = "activity"
	FeedEntryShare       FeedEntryType = "share"
)

type ShareKind string

const (
	ShareKindDeck ShareKind = "deck"
	ShareKindPlan ShareKind = "plan"
)

type User struct {
	ID          string            `json:"id"`
	Email       string            `json:"email"`
	DisplayName string            `json:"displayName"`
	Username    string            `json:"username"`
	Age         int               `json:"age"`
	AvatarURL   string            `json:"avatarUrl,omitempty"`
	Providers   map[string]string `json:"providers"`
	// PasswordHash es bcrypt-encoded. Se setea solo cuando el usuario se
	// registra con email+password. Nunca se serializa en respuestas HTTP
	// (los handlers usan Sanitize() antes de devolver).
	PasswordHash  string    `json:"-"`
	Locale        string    `json:"locale,omitempty"`
	EmailVerified bool      `json:"emailVerified"`
	CreatedAt     time.Time `json:"createdAt"`
	UpdatedAt     time.Time `json:"updatedAt"`
}

// Sanitize devuelve una copia del User sin campos sensibles.
func (u User) Sanitize() User {
	u.PasswordHash = ""
	return u
}

type Session struct {
	Token     string         `json:"token"`
	UserID    string         `json:"userId"`
	Provider  SocialProvider `json:"provider"`
	CreatedAt time.Time      `json:"createdAt"`
	ExpiresAt time.Time      `json:"expiresAt"`
}

type Friendship struct {
	ID          string           `json:"id"`
	RequesterID string           `json:"requesterId"`
	AddresseeID string           `json:"addresseeId"`
	Status      FriendshipStatus `json:"status"`
	CreatedAt   time.Time        `json:"createdAt"`
	UpdatedAt   time.Time        `json:"updatedAt"`
}

type Achievement struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Code        string    `json:"code"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	DeckName    string    `json:"deckName,omitempty"`
	Emoji       string    `json:"emoji,omitempty"`
	UnlockedAt  time.Time `json:"unlockedAt"`
}

type Activity struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	Code        string    `json:"code"`
	Title       string    `json:"title"`
	Description string    `json:"description"`
	DeckName    string    `json:"deckName,omitempty"`
	CreatedAt   time.Time `json:"createdAt"`
}

type SharedResource struct {
	ID           string    `json:"id"`
	OwnerUserID  string    `json:"ownerUserId"`
	TargetUserID string    `json:"targetUserId,omitempty"`
	Kind         ShareKind `json:"kind"`
	Title        string    `json:"title"`
	Summary      string    `json:"summary"`
	DeckID       string    `json:"deckId,omitempty"`
	PlanID       string    `json:"planId,omitempty"`
	PayloadJSON  string    `json:"payloadJson"`
	IsPublic     bool      `json:"isPublic"`
	CreatedAt    time.Time `json:"createdAt"`
}

// ShareImport registra que un usuario importó un deck comunitario a su
// colección. Una fila por (share, usuario): re-importar no infla stats.
type ShareImport struct {
	ShareID   string    `json:"shareId"`
	UserID    string    `json:"userId"`
	CreatedAt time.Time `json:"createdAt"`
}

type ProgressSnapshot struct {
	ID          string    `json:"id"`
	UserID      string    `json:"userId"`
	DeviceID    string    `json:"deviceId"`
	PayloadJSON string    `json:"payloadJson"`
	CapturedAt  time.Time `json:"capturedAt"`
}

type FeedReaction struct {
	ID        string    `json:"id"`
	EntryID   string    `json:"entryId"`
	UserID    string    `json:"userId"`
	Emoji     string    `json:"emoji"`
	CreatedAt time.Time `json:"createdAt"`
}

type FeedComment struct {
	ID        string    `json:"id"`
	EntryID   string    `json:"entryId"`
	UserID    string    `json:"userId"`
	Body      string    `json:"body"`
	CreatedAt time.Time `json:"createdAt"`
}

type FeedEntry struct {
	ID               string             `json:"id"`
	Type             FeedEntryType      `json:"type"`
	User             User               `json:"user"`
	Achievement      *Achievement       `json:"achievement,omitempty"`
	Activity         *Activity          `json:"activity,omitempty"`
	Share            *SharedResource    `json:"share,omitempty"`
	Reactions        []FeedReactionView `json:"reactions"`
	Comments         []FeedCommentView  `json:"comments"`
	ViewerHasReacted bool               `json:"viewerHasReacted"`
	Friendship       string             `json:"friendship"`
	CreatedAt        time.Time          `json:"createdAt"`
}

type FeedReactionView struct {
	ID        string    `json:"id"`
	Emoji     string    `json:"emoji"`
	User      User      `json:"user"`
	CreatedAt time.Time `json:"createdAt"`
}

type FeedCommentView struct {
	ID        string    `json:"id"`
	Body      string    `json:"body"`
	User      User      `json:"user"`
	CreatedAt time.Time `json:"createdAt"`
}
