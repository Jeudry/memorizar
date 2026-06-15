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
	// IsModerator habilita la cola de moderación de comunidad. Se concede
	// vía allowlist de correos (MEMORIZAR_MODERATOR_EMAILS) o seteando el
	// campo persistido; el gate vive en application.Service.IsModerator.
	IsModerator bool      `json:"isModerator"`
	CreatedAt   time.Time `json:"createdAt"`
	UpdatedAt   time.Time `json:"updatedAt"`
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

// PushToken es el token FCM/APNs de un dispositivo del usuario. Se persiste
// aunque el envío remoto aún no esté configurado (LogNotifier) para que el
// switch a FCM no requiera re-registrar dispositivos.
type PushToken struct {
	UserID    string    `json:"userId"`
	Token     string    `json:"token"`
	Platform  string    `json:"platform"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// PremiumSubscription es el estado premium de un usuario, persistido del
// lado servidor para sobrevivir reinstalaciones. Sin pasarela de pago aún:
// el único plan activable hoy es el trial.
type PremiumSubscription struct {
	UserID      string    `json:"userId"`
	Plan        string    `json:"plan"`
	ActivatedAt time.Time `json:"activatedAt"`
	ExpiresAt   time.Time `json:"expiresAt"`
}

// AnalyticsEvent es un evento de producto registrado por la app. UserID
// queda vacío para invitados.
type AnalyticsEvent struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId,omitempty"`
	Event     string    `json:"event"`
	PropsJSON string    `json:"propsJson,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
}

// DeckReportStatus es el estado de un reporte en la cola de moderación.
type DeckReportStatus string

const (
	ReportStatusPending         DeckReportStatus = "pending"
	ReportStatusResolvedKept    DeckReportStatus = "resolved_kept"
	ReportStatusResolvedHidden  DeckReportStatus = "resolved_hidden"
	ReportStatusResolvedRemoved DeckReportStatus = "resolved_removed"
)

// DeckReport es la denuncia de un usuario sobre un mazo comunitario.
type DeckReport struct {
	ID         string           `json:"id"`
	DeckID     string           `json:"deckId"`
	DeckTitle  string           `json:"deckTitle"`
	ReporterID string           `json:"reporterId"`
	Reason     string           `json:"reason"`
	Note       string           `json:"note"`
	Status     DeckReportStatus `json:"status"`
	CreatedAt  time.Time        `json:"createdAt"`
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
