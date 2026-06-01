package application

import (
	"crypto/rand"
	"encoding/hex"
	"log"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/Jeudry/memorizar/backend/internal/notify"
	"github.com/Jeudry/memorizar/backend/internal/social/domain"
	"github.com/Jeudry/memorizar/backend/internal/social/ports"
	"golang.org/x/crypto/bcrypt"
)

var (
	ErrInvalidProvider     = errors.New("invalid social provider")
	ErrMissingIdentity     = errors.New("missing social identity")
	ErrUserNotFound        = errors.New("user not found")
	ErrFriendshipExists    = errors.New("friendship already exists")
	ErrFriendshipForbidden = errors.New("friendship does not belong to user")
	ErrInvalidShareKind    = errors.New("invalid share kind")
	ErrMissingPayload      = errors.New("missing payload")
	ErrFeedEntryNotFound   = errors.New("feed entry not found")
	ErrEmailInUse          = errors.New("email already in use")
	ErrInvalidCredentials  = errors.New("invalid credentials")
	ErrWeakPassword        = errors.New("password must be at least 8 characters")
)

type Service struct {
	repo     ports.Repository
	now      func() time.Time
	notifier notify.Notifier
}

func NewService(repo ports.Repository, opts ...Option) *Service {
	service := &Service{
		repo:     repo,
		now:      time.Now,
		notifier: notify.LogNotifier{},
	}
	for _, opt := range opts {
		opt(service)
	}
	service.seed()
	return service
}

// Option lets callers swap in alternate notifiers / clocks without breaking
// existing call sites. Default notifier es LogNotifier (stdout).
type Option func(*Service)

func WithNotifier(n notify.Notifier) Option {
	return func(s *Service) {
		if n != nil {
			s.notifier = n
		}
	}
}

func WithClock(now func() time.Time) Option {
	return func(s *Service) {
		if now != nil {
			s.now = now
		}
	}
}

// notifySafe envuelve s.notifier.Notify en una guarda nil — los seeds en
// fase temprana podrían correr antes de inyectar uno.
func (s *Service) notifySafe(n notify.Notification) {
	if s.notifier == nil {
		return
	}
	s.notifier.Notify(n)
}

// userDisplay devuelve el displayName de un usuario, fallback al ID.
func (s *Service) userDisplay(userID string) string {
	user, err := s.repo.FindUserByID(userID)
	if err != nil || user == nil {
		return userID
	}
	if user.DisplayName != "" {
		return user.DisplayName
	}
	return user.Email
}

type SocialLoginInput struct {
	Provider       domain.SocialProvider `json:"provider"`
	ProviderUserID string                `json:"providerUserId"`
	Email          string                `json:"email"`
	DisplayName    string                `json:"displayName"`
	AvatarURL      string                `json:"avatarUrl"`
	AccessToken    string                `json:"accessToken,omitempty"`
	IDToken        string                `json:"idToken,omitempty"`
}

type SocialLoginOutput struct {
	User    domain.User    `json:"user"`
	Session domain.Session `json:"session"`
}

type ShareResourceInput struct {
	Kind         domain.ShareKind `json:"kind"`
	TargetUserID string           `json:"targetUserId,omitempty"`
	Title        string           `json:"title"`
	Summary      string           `json:"summary"`
	DeckID       string           `json:"deckId,omitempty"`
	PlanID       string           `json:"planId,omitempty"`
	PayloadJSON  string           `json:"payloadJson"`
	IsPublic     bool             `json:"isPublic"`
}

type ProgressSyncInput struct {
	DeviceID    string `json:"deviceId"`
	PayloadJSON string `json:"payloadJson"`
}

func (s *Service) SocialLogin(input SocialLoginInput) (*SocialLoginOutput, error) {
	if input.Provider != domain.ProviderGoogle && input.Provider != domain.ProviderApple && input.Provider != domain.ProviderFacebook {
		return nil, ErrInvalidProvider
	}
	if strings.TrimSpace(input.ProviderUserID) == "" && strings.TrimSpace(input.Email) == "" {
		return nil, ErrMissingIdentity
	}

	providerKey := strings.TrimSpace(input.ProviderUserID)
	user, _ := s.repo.FindUserByProvider(input.Provider, providerKey)
	if user == nil && strings.TrimSpace(input.Email) != "" {
		user, _ = s.repo.FindUserByEmail(strings.ToLower(strings.TrimSpace(input.Email)))
	}

	now := s.now().UTC()
	if user == nil {
		user = &domain.User{
			ID:          newID("usr"),
			Email:       strings.ToLower(strings.TrimSpace(input.Email)),
			DisplayName: fallbackDisplayName(input.DisplayName, input.Email),
			AvatarURL:   strings.TrimSpace(input.AvatarURL),
			Providers:   map[string]string{},
			CreatedAt:   now,
			UpdatedAt:   now,
		}
	}
	if user.Providers == nil {
		user.Providers = map[string]string{}
	}
	if providerKey != "" {
		user.Providers[string(input.Provider)] = providerKey
	}
	if strings.TrimSpace(input.DisplayName) != "" {
		user.DisplayName = strings.TrimSpace(input.DisplayName)
	}
	if strings.TrimSpace(input.AvatarURL) != "" {
		user.AvatarURL = strings.TrimSpace(input.AvatarURL)
	}
	if user.Email == "" {
		user.Email = strings.ToLower(strings.TrimSpace(input.Email))
	}
	user.UpdatedAt = now
	if err := s.repo.SaveUser(*user); err != nil {
		return nil, err
	}

	session, err := s.createSession(user.ID, string(input.Provider))
	if err != nil {
		return nil, err
	}

	return &SocialLoginOutput{User: user.Sanitize(), Session: *session}, nil
}

// createSession crea + persiste un Session token con TTL 30 días.
func (s *Service) createSession(userID, provider string) (*domain.Session, error) {
	now := s.now().UTC()
	session := domain.Session{
		Token:     newID("sess"),
		UserID:    userID,
		Provider:  domain.SocialProvider(provider),
		CreatedAt: now,
		ExpiresAt: now.Add(30 * 24 * time.Hour),
	}
	if err := s.repo.SaveSession(session); err != nil {
		return nil, err
	}
	return &session, nil
}

func (s *Service) Authenticate(token string) (*domain.User, error) {
	session, err := s.repo.FindSession(strings.TrimSpace(token))
	if err != nil || session == nil || session.ExpiresAt.Before(s.now().UTC()) {
		return nil, ErrUserNotFound
	}
	return s.repo.FindUserByID(session.UserID)
}

func (s *Service) GetUser(userID string) (*domain.User, error) {
	return s.repo.FindUserByID(strings.TrimSpace(userID))
}

func (s *Service) RequestFriend(requesterID, addresseeID string) (*domain.Friendship, error) {
	if requesterID == addresseeID {
		return nil, ErrFriendshipExists
	}
	existing, _ := s.repo.FindFriendship(requesterID, addresseeID)
	if existing != nil {
		return nil, ErrFriendshipExists
	}
	now := s.now().UTC()
	friendship := domain.Friendship{
		ID:          newID("fr"),
		RequesterID: requesterID,
		AddresseeID: addresseeID,
		Status:      domain.FriendshipPending,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := s.repo.SaveFriendship(friendship); err != nil {
		return nil, err
	}

	// Recuperar usuarios para la simulación de correo e información de la notificación
	requester, _ := s.repo.FindUserByID(requesterID)
	addressee, _ := s.repo.FindUserByID(addresseeID)

	requesterName := "Alguien"
	if requester != nil && requester.DisplayName != "" {
		requesterName = requester.DisplayName
	} else if requester != nil {
		requesterName = requester.Email
	}

	s.notifySafe(notify.Notification{
		Type:   notify.EventFriendRequested,
		UserID: addresseeID,
		Title:  "Nueva solicitud de amistad",
		Body:   requesterName + " quiere conectar contigo.",
		Data: map[string]string{
			"friendshipId": friendship.ID,
			"requesterId":  requesterID,
			"deeplink":     "memorizar://amigos",
		},
	})

	// Simulación de correo electrónico robusta y visible en los logs
	if requester != nil && addressee != nil {
		log.Printf("\n========================================================================\n" +
			"[EMAIL SIMULATOR] ENVIADO A: " + addressee.Email + "\n" +
			"ASUNTO: ¡" + requesterName + " quiere ser tu amigo en Memorizar! 👥\n" +
			"CUERPO:\n" +
			"  ¡Hola!\n" +
			"  " + requesterName + " (" + requester.Email + ") te ha enviado una solicitud de\n" +
			"  amistad en Memorizar.\n\n" +
			"  Para aceptarla, abre la aplicación e ingresa a la sección de amigos.\n\n" +
			"  - El Equipo de Memorizar 🎯\n" +
			"========================================================================\n")
	}

	return &friendship, nil
}

func (s *Service) AcceptInviteFriend(requesterID, addresseeID string) (*domain.Friendship, error) {
	if requesterID == addresseeID {
		return nil, ErrFriendshipExists
	}
	existing, _ := s.repo.FindFriendship(requesterID, addresseeID)
	if existing != nil {
		if existing.Status == domain.FriendshipPending {
			existing.Status = domain.FriendshipAccepted
			existing.UpdatedAt = s.now().UTC()
			if err := s.repo.SaveFriendship(*existing); err != nil {
				return nil, err
			}
			return existing, nil
		}
		return existing, nil
	}
	now := s.now().UTC()
	friendship := domain.Friendship{
		ID:          newID("fr"),
		RequesterID: requesterID,
		AddresseeID: addresseeID,
		Status:      domain.FriendshipAccepted,
		CreatedAt:   now,
		UpdatedAt:   now,
	}
	if err := s.repo.SaveFriendship(friendship); err != nil {
		return nil, err
	}
	s.notifySafe(notify.Notification{
		Type:   notify.EventFriendAccepted,
		UserID: addresseeID,
		Title:  "Enlace aceptado",
		Body:   s.userDisplay(requesterID) + " se ha conectado contigo mediante tu enlace de invitación.",
		Data: map[string]string{
			"friendshipId": friendship.ID,
			"friendId":     requesterID,
			"deeplink":     "memorizar://amigos",
		},
	})
	return &friendship, nil
}

func (s *Service) AcceptFriend(currentUserID, friendshipID string) (*domain.Friendship, error) {
	friendship, err := s.repo.FindFriendshipByID(friendshipID)
	if err != nil || friendship == nil {
		return nil, ErrUserNotFound
	}
	if friendship.AddresseeID != currentUserID {
		return nil, ErrFriendshipForbidden
	}
	friendship.Status = domain.FriendshipAccepted
	friendship.UpdatedAt = s.now().UTC()
	if err := s.repo.SaveFriendship(*friendship); err != nil {
		return nil, err
	}
	// Notificar al requester (el que envió originalmente la solicitud) que
	// fue aceptada.
	s.notifySafe(notify.Notification{
		Type:   notify.EventFriendAccepted,
		UserID: friendship.RequesterID,
		Title:  "Solicitud aceptada",
		Body:   s.userDisplay(currentUserID) + " aceptó tu solicitud de amistad.",
		Data: map[string]string{
			"friendshipId": friendship.ID,
			"friendId":     currentUserID,
			"deeplink":     "memorizar://amigos",
		},
	})
	return friendship, nil
}

func (s *Service) ListFriends(userID string) ([]domain.User, error) {
	friendships, err := s.repo.ListFriendships(userID, domain.FriendshipAccepted)
	if err != nil {
		return nil, err
	}
	friends := make([]domain.User, 0, len(friendships))
	for _, friendship := range friendships {
		friendID := friendship.RequesterID
		if friendID == userID {
			friendID = friendship.AddresseeID
		}
		user, err := s.repo.FindUserByID(friendID)
		if err == nil && user != nil {
			friends = append(friends, *user)
		}
	}
	return friends, nil
}

func (s *Service) ListPendingRequests(userID string) ([]domain.Friendship, error) {
	friendships, err := s.repo.ListFriendships(userID, domain.FriendshipPending)
	if err != nil {
		return nil, err
	}
	pending := friendships[:0]
	for _, friendship := range friendships {
		if friendship.AddresseeID == userID {
			pending = append(pending, friendship)
		}
	}
	return pending, nil
}

func (s *Service) ListSuggestedPeople(userID string) ([]domain.User, error) {
	users, err := s.repo.ListUsers()
	if err != nil {
		return nil, err
	}
	friendships, err := s.repo.ListFriendships(userID, domain.FriendshipAccepted)
	if err != nil {
		return nil, err
	}
	friendSet := map[string]struct{}{}
	for _, friendship := range friendships {
		friendID := friendship.RequesterID
		if friendID == userID {
			friendID = friendship.AddresseeID
		}
		friendSet[friendID] = struct{}{}
	}
	pending, err := s.repo.ListFriendships(userID, domain.FriendshipPending)
	if err != nil {
		return nil, err
	}
	for _, friendship := range pending {
		friendSet[friendship.RequesterID] = struct{}{}
		friendSet[friendship.AddresseeID] = struct{}{}
	}

	suggestions := make([]domain.User, 0, len(users))
	for _, user := range users {
		if user.ID == userID {
			continue
		}
		if _, exists := friendSet[user.ID]; exists {
			continue
		}
		suggestions = append(suggestions, user)
	}
	sort.Slice(suggestions, func(i, j int) bool {
		return suggestions[i].DisplayName < suggestions[j].DisplayName
	})
	return suggestions, nil
}

// SearchCommunityDecks busca SharedResources públicos cuyo título o
// summary coincidan con la query (case-insensitive). Excluye los del propio
// usuario. Devuelve hasta 25.
func (s *Service) SearchCommunityDecks(userID, rawQuery string) ([]domain.SharedResource, error) {
	q := strings.ToLower(strings.TrimSpace(rawQuery))
	users, err := s.repo.ListUsers()
	if err != nil {
		return nil, err
	}
	allUserIDs := make([]string, 0, len(users))
	for _, u := range users {
		allUserIDs = append(allUserIDs, u.ID)
	}
	resources, err := s.repo.ListPublicSharedResourcesByUserIDs(allUserIDs)
	if err != nil {
		return nil, err
	}
	matches := make([]domain.SharedResource, 0, 25)
	for _, r := range resources {
		if r.OwnerUserID == userID {
			continue
		}
		if r.Kind != domain.ShareKindDeck {
			continue
		}
		if !r.IsPublic {
			continue
		}
		if q == "" ||
			strings.Contains(strings.ToLower(r.Title), q) ||
			strings.Contains(strings.ToLower(r.Summary), q) {
			matches = append(matches, r)
		}
		if len(matches) >= 25 {
			break
		}
	}
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].CreatedAt.After(matches[j].CreatedAt)
	})
	return matches, nil
}

// SearchPeople busca usuarios por coincidencia parcial de email o
// displayName (case-insensitive). Excluye al propio usuario y a los que ya
// están conectados (amigos o request pendiente). Devuelve hasta 25 matches.
func (s *Service) SearchPeople(userID, rawQuery string) ([]domain.User, error) {
	query := strings.TrimSpace(strings.ToLower(rawQuery))
	if query == "" {
		return []domain.User{}, nil
	}

	users, err := s.repo.ListUsers()
	if err != nil {
		return nil, err
	}
	accepted, err := s.repo.ListFriendships(userID, domain.FriendshipAccepted)
	if err != nil {
		return nil, err
	}
	pending, err := s.repo.ListFriendships(userID, domain.FriendshipPending)
	if err != nil {
		return nil, err
	}
	connected := map[string]struct{}{}
	for _, f := range accepted {
		connected[f.RequesterID] = struct{}{}
		connected[f.AddresseeID] = struct{}{}
	}
	for _, f := range pending {
		connected[f.RequesterID] = struct{}{}
		connected[f.AddresseeID] = struct{}{}
	}

	matches := make([]domain.User, 0, 25)
	for _, u := range users {
		if u.ID == userID {
			continue
		}
		if _, exists := connected[u.ID]; exists {
			continue
		}
		email := strings.ToLower(u.Email)
		name := strings.ToLower(u.DisplayName)
		if strings.Contains(email, query) || strings.Contains(name, query) {
			matches = append(matches, u)
		}
		if len(matches) >= 25 {
			break
		}
	}
	sort.Slice(matches, func(i, j int) bool {
		return matches[i].DisplayName < matches[j].DisplayName
	})
	return matches, nil
}

// ─── Email verification + password reset ──────────────────────────────
//
// Mecánica simple sin SMTP real: generamos tokens en memoria + TTL. Cuando
// el front llama a /verify/request, devolvemos el token *en la respuesta*
// para uso en dev. En producción ese token solo se manda por email vía
// SMTP (TODO: integrar SendGrid o Resend).

type verifyToken struct {
	UserID    string
	Email     string
	ExpiresAt time.Time
}

type resetToken struct {
	UserID    string
	Email     string
	ExpiresAt time.Time
}

var (
	verifyTokens   = map[string]verifyToken{}
	resetTokens    = map[string]resetToken{}
	tokensMu       sync.Mutex
)

func (s *Service) RequestEmailVerify(userID string) (string, error) {
	user, _ := s.repo.FindUserByID(userID)
	if user == nil {
		return "", ErrUserNotFound
	}
	if user.EmailVerified {
		return "", nil
	}
	token := newID("vrf")
	tokensMu.Lock()
	verifyTokens[token] = verifyToken{
		UserID:    user.ID,
		Email:     user.Email,
		ExpiresAt: s.now().UTC().Add(24 * time.Hour),
	}
	tokensMu.Unlock()
	// TODO(smtp): mandar email con link memorizar://verify?token={token}.
	return token, nil
}

func (s *Service) ConfirmEmailVerify(token string) error {
	tokensMu.Lock()
	v, ok := verifyTokens[token]
	if ok {
		delete(verifyTokens, token)
	}
	tokensMu.Unlock()
	if !ok || v.ExpiresAt.Before(s.now().UTC()) {
		return errors.New("token inválido o expirado")
	}
	user, _ := s.repo.FindUserByID(v.UserID)
	if user == nil {
		return ErrUserNotFound
	}
	user.EmailVerified = true
	user.UpdatedAt = s.now().UTC()
	return s.repo.SaveUser(*user)
}

func (s *Service) RequestPasswordReset(email string) (string, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" {
		return "", ErrMissingIdentity
	}
	user, _ := s.repo.FindUserByEmail(email)
	if user == nil {
		// No revelar si el email existe — devolver token vacío silenciosamente.
		return "", nil
	}
	token := newID("pwr")
	tokensMu.Lock()
	resetTokens[token] = resetToken{
		UserID:    user.ID,
		Email:     user.Email,
		ExpiresAt: s.now().UTC().Add(1 * time.Hour),
	}
	tokensMu.Unlock()
	// TODO(smtp): enviar a user.Email.
	return token, nil
}

func (s *Service) ConfirmPasswordReset(token, newPassword string) error {
	if len(newPassword) < 8 {
		return ErrWeakPassword
	}
	tokensMu.Lock()
	r, ok := resetTokens[token]
	if ok {
		delete(resetTokens, token)
	}
	tokensMu.Unlock()
	if !ok || r.ExpiresAt.Before(s.now().UTC()) {
		return errors.New("token inválido o expirado")
	}
	user, _ := s.repo.FindUserByID(r.UserID)
	if user == nil {
		return ErrUserNotFound
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	user.PasswordHash = string(hash)
	user.UpdatedAt = s.now().UTC()
	return s.repo.SaveUser(*user)
}

// SetAvatarURL helper que también llama a UpdateProfile pero recibe la
// URL ya resuelta (path local /avatars/{id}.png o URL externa).
func (s *Service) SetAvatarURL(userID, url string) error {
	user, _ := s.repo.FindUserByID(userID)
	if user == nil {
		return ErrUserNotFound
	}
	user.AvatarURL = url
	user.UpdatedAt = s.now().UTC()
	return s.repo.SaveUser(*user)
}

// FindShareByID busca un SharedResource por su ID. Para uso desde
// deeplinks — una persona abre un link `memorizar://deck/{shareId}`, la app
// hace fetch a /v1/community/decks/{id} y muestra preview + botón importar.
// Solo devuelve si IsPublic = true (no exponer compartidos privados via link).
func (s *Service) FindShareByID(shareID string) (*domain.SharedResource, error) {
	users, err := s.repo.ListUsers()
	if err != nil {
		return nil, err
	}
	allUserIDs := make([]string, 0, len(users))
	for _, u := range users {
		allUserIDs = append(allUserIDs, u.ID)
	}
	resources, err := s.repo.ListPublicSharedResourcesByUserIDs(allUserIDs)
	if err != nil {
		return nil, err
	}
	for _, r := range resources {
		if r.ID == shareID && r.IsPublic {
			return &r, nil
		}
	}
	return nil, nil
}

func (s *Service) RecordAchievement(userID, code, title, description, deckName, emoji string) (*domain.Achievement, error) {
	achievement := domain.Achievement{
		ID:          newID("ach"),
		UserID:      userID,
		Code:        code,
		Title:       title,
		Description: description,
		DeckName:    deckName,
		Emoji:       emoji,
		UnlockedAt:  s.now().UTC(),
	}
	if err := s.repo.SaveAchievement(achievement); err != nil {
		return nil, err
	}
	return &achievement, nil
}

func (s *Service) RecordActivity(userID, code, title, description, deckName string) (*domain.Activity, error) {
	activity := domain.Activity{
		ID:          newID("act"),
		UserID:      userID,
		Code:        code,
		Title:       title,
		Description: description,
		DeckName:    deckName,
		CreatedAt:   s.now().UTC(),
	}
	if err := s.repo.SaveActivity(activity); err != nil {
		return nil, err
	}
	return &activity, nil
}

func (s *Service) ShareResource(userID string, input ShareResourceInput) (*domain.SharedResource, error) {
	if input.Kind != domain.ShareKindDeck && input.Kind != domain.ShareKindPlan {
		return nil, ErrInvalidShareKind
	}
	if strings.TrimSpace(input.PayloadJSON) == "" {
		return nil, ErrMissingPayload
	}
	resource := domain.SharedResource{
		ID:           newID("shr"),
		OwnerUserID:  userID,
		TargetUserID: strings.TrimSpace(input.TargetUserID),
		Kind:         input.Kind,
		Title:        strings.TrimSpace(input.Title),
		Summary:      strings.TrimSpace(input.Summary),
		DeckID:       strings.TrimSpace(input.DeckID),
		PlanID:       strings.TrimSpace(input.PlanID),
		PayloadJSON:  input.PayloadJSON,
		IsPublic:     input.IsPublic,
		CreatedAt:    s.now().UTC(),
	}
	if err := s.repo.SaveSharedResource(resource); err != nil {
		return nil, err
	}
	// Solo notificamos compartidos privados (1:1). Los públicos van al feed
	// y no generan push individual.
	if resource.TargetUserID != "" {
		s.notifySafe(notify.Notification{
			Type:   notify.EventDeckShared,
			UserID: resource.TargetUserID,
			Title:  s.userDisplay(userID) + " te compartió un deck",
			Body:   resource.Title,
			Data: map[string]string{
				"shareId":  resource.ID,
				"kind":     string(resource.Kind),
				"deeplink": "memorizar://inbox",
			},
		})
	}
	return &resource, nil
}

func (s *Service) ListSharedResources(userID string) ([]domain.SharedResource, error) {
	friends, err := s.ListFriends(userID)
	if err != nil {
		return nil, err
	}
	friendIDs := make([]string, 0, len(friends))
	for _, friend := range friends {
		friendIDs = append(friendIDs, friend.ID)
	}
	publicResources, err := s.repo.ListPublicSharedResourcesByUserIDs(friendIDs)
	if err != nil {
		return nil, err
	}
	privateResources, err := s.repo.ListSharedResourcesForUser(userID)
	if err != nil {
		return nil, err
	}
	byID := map[string]domain.SharedResource{}
	for _, resource := range publicResources {
		byID[resource.ID] = resource
	}
	for _, resource := range privateResources {
		byID[resource.ID] = resource
	}
	result := make([]domain.SharedResource, 0, len(byID))
	for _, resource := range byID {
		result = append(result, resource)
	}
	sort.Slice(result, func(i, j int) bool {
		return result[i].CreatedAt.After(result[j].CreatedAt)
	})
	return result, nil
}

func (s *Service) SaveProgressSnapshot(userID string, input ProgressSyncInput) (*domain.ProgressSnapshot, error) {
	if strings.TrimSpace(input.PayloadJSON) == "" {
		return nil, ErrMissingPayload
	}
	snapshot := domain.ProgressSnapshot{
		ID:          newID("sync"),
		UserID:      userID,
		DeviceID:    strings.TrimSpace(input.DeviceID),
		PayloadJSON: input.PayloadJSON,
		CapturedAt:  s.now().UTC(),
	}
	if err := s.repo.SaveProgressSnapshot(snapshot); err != nil {
		return nil, err
	}
	summary := summarizeSnapshot(input.PayloadJSON)
	_, _ = s.RecordActivity(
		userID,
		"sync_progress",
		"Sincronizó su progreso",
		summary,
		"",
	)
	return &snapshot, nil
}

func (s *Service) GetLatestProgressSnapshot(userID string) (*domain.ProgressSnapshot, error) {
	return s.repo.FindLatestProgressSnapshot(userID)
}

func (s *Service) AddReaction(userID, entryID, emoji string) (*domain.FeedReaction, error) {
	feed, err := s.BuildFeed(userID)
	if err != nil {
		return nil, err
	}
	entry, ok := findFeedEntry(feed, entryID)
	if !ok {
		return nil, ErrFeedEntryNotFound
	}
	reaction := domain.FeedReaction{
		ID:        newID("rct"),
		EntryID:   entryID,
		UserID:    userID,
		Emoji:     strings.TrimSpace(emoji),
		CreatedAt: s.now().UTC(),
	}
	if err := s.repo.SaveReaction(reaction); err != nil {
		return nil, err
	}
	// Notificar al dueño del entry, salvo que se reaccione a uno mismo.
	if entry.User.ID != "" && entry.User.ID != userID {
		s.notifySafe(notify.Notification{
			Type:   notify.EventReactionAdded,
			UserID: entry.User.ID,
			Title:  s.userDisplay(userID) + " reaccionó a tu actividad",
			Body:   reaction.Emoji,
			Data: map[string]string{
				"entryId":  entryID,
				"emoji":    reaction.Emoji,
				"deeplink": "memorizar://comunidad",
			},
		})
	}
	return &reaction, nil
}

func (s *Service) AddComment(userID, entryID, body string) (*domain.FeedComment, error) {
	feed, err := s.BuildFeed(userID)
	if err != nil {
		return nil, err
	}
	entry, ok := findFeedEntry(feed, entryID)
	if !ok {
		return nil, ErrFeedEntryNotFound
	}
	comment := domain.FeedComment{
		ID:        newID("cmt"),
		EntryID:   entryID,
		UserID:    userID,
		Body:      strings.TrimSpace(body),
		CreatedAt: s.now().UTC(),
	}
	if err := s.repo.SaveComment(comment); err != nil {
		return nil, err
	}
	if entry.User.ID != "" && entry.User.ID != userID {
		preview := comment.Body
		if len(preview) > 80 {
			preview = preview[:77] + "…"
		}
		s.notifySafe(notify.Notification{
			Type:   notify.EventCommentAdded,
			UserID: entry.User.ID,
			Title:  s.userDisplay(userID) + " comentó tu actividad",
			Body:   preview,
			Data: map[string]string{
				"entryId":  entryID,
				"deeplink": "memorizar://comunidad",
			},
		})
	}
	return &comment, nil
}

func (s *Service) BuildFeed(userID string) ([]domain.FeedEntry, error) {
	friends, err := s.ListFriends(userID)
	if err != nil {
		return nil, err
	}
	friendIDs := make([]string, 0, len(friends))
	friendByID := make(map[string]domain.User, len(friends))
	for _, friend := range friends {
		friendIDs = append(friendIDs, friend.ID)
		friendByID[friend.ID] = friend
	}

	achievements, err := s.repo.ListAchievementsByUserIDs(friendIDs)
	if err != nil {
		return nil, err
	}
	activities, err := s.repo.ListActivitiesByUserIDs(friendIDs)
	if err != nil {
		return nil, err
	}
	shares, err := s.repo.ListPublicSharedResourcesByUserIDs(friendIDs)
	if err != nil {
		return nil, err
	}

	feed := make([]domain.FeedEntry, 0, len(achievements)+len(activities)+len(shares))
	for _, achievement := range achievements {
		user, ok := friendByID[achievement.UserID]
		if !ok {
			continue
		}
		feed = append(feed, domain.FeedEntry{
			ID:          achievement.ID,
			Type:        domain.FeedEntryAchievement,
			Achievement: &achievement,
			User:        user,
			Friendship:  "friend",
			CreatedAt:   achievement.UnlockedAt,
		})
	}
	for _, activity := range activities {
		user, ok := friendByID[activity.UserID]
		if !ok {
			continue
		}
		feed = append(feed, domain.FeedEntry{
			ID:         activity.ID,
			Type:       domain.FeedEntryActivity,
			Activity:   &activity,
			User:       user,
			Friendship: "friend",
			CreatedAt:  activity.CreatedAt,
		})
	}
	for _, share := range shares {
		user, ok := friendByID[share.OwnerUserID]
		if !ok {
			continue
		}
		shareCopy := share
		feed = append(feed, domain.FeedEntry{
			ID:         share.ID,
			Type:       domain.FeedEntryShare,
			Share:      &shareCopy,
			User:       user,
			Friendship: "friend",
			CreatedAt:  share.CreatedAt,
		})
	}

	sort.Slice(feed, func(i, j int) bool {
		return feed[i].CreatedAt.After(feed[j].CreatedAt)
	})

	entryIDs := make([]string, 0, len(feed))
	for _, entry := range feed {
		entryIDs = append(entryIDs, entry.ID)
	}
	reactions, _ := s.repo.ListReactionsByEntryIDs(entryIDs)
	comments, _ := s.repo.ListCommentsByEntryIDs(entryIDs)
	reactionMap := groupReactionsByEntry(reactions)
	commentMap := groupCommentsByEntry(comments)

	for i := range feed {
		feed[i].Reactions = s.buildReactionViews(reactionMap[feed[i].ID], friendByID, userID)
		feed[i].Comments = s.buildCommentViews(commentMap[feed[i].ID], friendByID)
		feed[i].ViewerHasReacted = hasReactionFromUser(reactionMap[feed[i].ID], userID)
	}

	return feed, nil
}

func (s *Service) buildReactionViews(reactions []domain.FeedReaction, friendByID map[string]domain.User, viewerID string) []domain.FeedReactionView {
	views := make([]domain.FeedReactionView, 0, len(reactions))
	for _, reaction := range reactions {
		user, ok := friendByID[reaction.UserID]
		if !ok && reaction.UserID != viewerID {
			continue
		}
		if reaction.UserID == viewerID {
			if self, err := s.repo.FindUserByID(viewerID); err == nil && self != nil {
				user = *self
			}
		}
		views = append(views, domain.FeedReactionView{
			ID:        reaction.ID,
			Emoji:     reaction.Emoji,
			User:      user,
			CreatedAt: reaction.CreatedAt,
		})
	}
	sort.Slice(views, func(i, j int) bool {
		return views[i].CreatedAt.Before(views[j].CreatedAt)
	})
	return views
}

func (s *Service) buildCommentViews(comments []domain.FeedComment, friendByID map[string]domain.User) []domain.FeedCommentView {
	views := make([]domain.FeedCommentView, 0, len(comments))
	for _, comment := range comments {
		user, err := s.repo.FindUserByID(comment.UserID)
		if err != nil || user == nil {
			if friend, ok := friendByID[comment.UserID]; ok {
				user = &friend
			} else {
				continue
			}
		}
		views = append(views, domain.FeedCommentView{
			ID:        comment.ID,
			Body:      comment.Body,
			User:      *user,
			CreatedAt: comment.CreatedAt,
		})
	}
	sort.Slice(views, func(i, j int) bool {
		return views[i].CreatedAt.Before(views[j].CreatedAt)
	})
	return views
}

// EmailRegisterInput / EmailLoginInput cubren el flujo email+password como
// alternativa a los providers sociales. EmailVerified queda en false hasta
// que el usuario confirme via link (a implementar con SMTP).
type EmailRegisterInput struct {
	Email       string `json:"email"`
	Password    string `json:"password"`
	DisplayName string `json:"displayName"`
}

type EmailLoginInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (s *Service) RegisterEmail(input EmailRegisterInput) (*SocialLoginOutput, error) {
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if email == "" {
		return nil, ErrMissingIdentity
	}
	if len(input.Password) < 8 {
		return nil, ErrWeakPassword
	}
	existing, _ := s.repo.FindUserByEmail(email)
	if existing != nil {
		return nil, ErrEmailInUse
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}
	now := s.now().UTC()
	user := domain.User{
		ID:           newID("usr"),
		Email:        email,
		DisplayName:  fallbackDisplayName(input.DisplayName, email),
		Providers:    map[string]string{},
		PasswordHash: string(hash),
		CreatedAt:    now,
		UpdatedAt:    now,
	}
	if err := s.repo.SaveUser(user); err != nil {
		return nil, err
	}
	session, err := s.createSession(user.ID, "email")
	if err != nil {
		return nil, err
	}
	return &SocialLoginOutput{User: user.Sanitize(), Session: *session}, nil
}

func (s *Service) LoginEmail(input EmailLoginInput) (*SocialLoginOutput, error) {
	email := strings.ToLower(strings.TrimSpace(input.Email))
	if email == "" {
		return nil, ErrMissingIdentity
	}
	user, _ := s.repo.FindUserByEmail(email)
	if user == nil || user.PasswordHash == "" {
		return nil, ErrInvalidCredentials
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(input.Password)); err != nil {
		return nil, ErrInvalidCredentials
	}
	session, err := s.createSession(user.ID, "email")
	if err != nil {
		return nil, err
	}
	return &SocialLoginOutput{User: user.Sanitize(), Session: *session}, nil
}

// UpdateProfileInput permite editar nombre, avatar y locale del usuario
// activo. Cualquier campo vacío deja el valor previo.
type UpdateProfileInput struct {
	DisplayName *string `json:"displayName,omitempty"`
	AvatarURL   *string `json:"avatarUrl,omitempty"`
	Locale      *string `json:"locale,omitempty"`
}

func (s *Service) UpdateProfile(userID string, input UpdateProfileInput) (*domain.User, error) {
	user, err := s.repo.FindUserByID(userID)
	if err != nil || user == nil {
		return nil, ErrUserNotFound
	}
	if input.DisplayName != nil && strings.TrimSpace(*input.DisplayName) != "" {
		user.DisplayName = strings.TrimSpace(*input.DisplayName)
	}
	if input.AvatarURL != nil {
		user.AvatarURL = strings.TrimSpace(*input.AvatarURL)
	}
	if input.Locale != nil {
		loc := strings.TrimSpace(*input.Locale)
		if loc == "es" || loc == "en" || loc == "pt" || loc == "" {
			user.Locale = loc
		}
	}
	user.UpdatedAt = s.now().UTC()
	if err := s.repo.SaveUser(*user); err != nil {
		return nil, err
	}
	sanitized := user.Sanitize()
	return &sanitized, nil
}

// DeleteAccount marca y borra al usuario y sus datos asociados. Para Fase 1
// hace borrado físico — en producción debería ser soft-delete con período
// de gracia (GDPR / LATAM data retention).
func (s *Service) DeleteAccount(userID string) error {
	user, _ := s.repo.FindUserByID(userID)
	if user == nil {
		return nil
	}
	return s.repo.DeleteUserCascade(userID)
}

func (s *Service) seed() {
	out1, _ := s.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderGoogle,
		ProviderUserID: "seed-jeudry-google",
		Email:          "jeudry@example.com",
		DisplayName:    "Jeudry",
		AvatarURL:      "https://example.com/avatar/jeudry.png",
	})
	out2, _ := s.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderApple,
		ProviderUserID: "seed-sara-apple",
		Email:          "sara@example.com",
		DisplayName:    "Sara",
		AvatarURL:      "https://example.com/avatar/sara.png",
	})
	out3, _ := s.SocialLogin(SocialLoginInput{
		Provider:       domain.ProviderFacebook,
		ProviderUserID: "seed-luis-fb",
		Email:          "luis@example.com",
		DisplayName:    "Luis",
		AvatarURL:      "https://example.com/avatar/luis.png",
	})
	if out1 == nil || out2 == nil || out3 == nil {
		return
	}
	hash, _ := bcrypt.GenerateFromPassword([]byte("12345678"), bcrypt.DefaultCost)
	if u1, _ := s.repo.FindUserByID(out1.User.ID); u1 != nil {
		u1.PasswordHash = string(hash)
		_ = s.repo.SaveUser(*u1)
	}
	if u2, _ := s.repo.FindUserByID(out2.User.ID); u2 != nil {
		u2.PasswordHash = string(hash)
		_ = s.repo.SaveUser(*u2)
	}
	if u3, _ := s.repo.FindUserByID(out3.User.ID); u3 != nil {
		u3.PasswordHash = string(hash)
		_ = s.repo.SaveUser(*u3)
	}
	friendship1, _ := s.RequestFriend(out2.User.ID, out1.User.ID)
	if friendship1 != nil {
		_, _ = s.AcceptFriend(out1.User.ID, friendship1.ID)
	}
	friendship2, _ := s.RequestFriend(out3.User.ID, out1.User.ID)
	if friendship2 != nil {
		_, _ = s.AcceptFriend(out1.User.ID, friendship2.ID)
	}
	_, _ = s.RecordAchievement(out2.User.ID, "weekly_streak_7", "Llevó 7 días seguidos", "Mantuvo viva su racha esta semana.", "Génesis 1", "🔥")
	_, _ = s.RecordActivity(out3.User.ID, "studying_now", "Está memorizando Romanos 8", "Siguió practicando un bloque difícil con constancia.", "Romanos 8")
	sharePayload, _ := json.Marshal(map[string]any{
		"title":     "Romanos 8 profundo",
		"objective": "memorizar profundo",
	})
	_, _ = s.ShareResource(out2.User.ID, ShareResourceInput{
		Kind:        domain.ShareKindPlan,
		Title:       "Plan público de Romanos 8",
		Summary:     "Un plan corto para cerrar el capítulo con ritmo.",
		PlanID:      "seed-plan-romanos-8",
		PayloadJSON: string(sharePayload),
		IsPublic:    true,
	})
}

func fallbackDisplayName(name, email string) string {
	name = strings.TrimSpace(name)
	if name != "" {
		return name
	}
	if email == "" {
		return "Memorizar User"
	}
	if index := strings.Index(email, "@"); index > 0 {
		name := email[:index]
		return strings.ToUpper(name[:1]) + name[1:]
	}
	return email
}

func newID(prefix string) string {
	buffer := make([]byte, 8)
	if _, err := rand.Read(buffer); err != nil {
		return fmt.Sprintf("%s_%d", prefix, time.Now().UnixNano())
	}
	return prefix + "_" + hex.EncodeToString(buffer)
}

func findFeedEntry(feed []domain.FeedEntry, entryID string) (domain.FeedEntry, bool) {
	for _, entry := range feed {
		if entry.ID == entryID {
			return entry, true
		}
	}
	return domain.FeedEntry{}, false
}

func summarizeSnapshot(payload string) string {
	var decoded map[string]any
	if err := json.Unmarshal([]byte(payload), &decoded); err != nil {
		return "Guardó una copia reciente de su progreso."
	}
	deckCount := len(asList(decoded["decks"]))
	goalCount := len(asList(decoded["goals"]))
	journeyCount := len(asList(decoded["journeys"]))
	return fmt.Sprintf(
		"Puso al día %d decks, %d metas y %d journeys.",
		deckCount,
		goalCount,
		journeyCount,
	)
}

func asList(value any) []any {
	list, _ := value.([]any)
	return list
}

func groupReactionsByEntry(reactions []domain.FeedReaction) map[string][]domain.FeedReaction {
	result := map[string][]domain.FeedReaction{}
	for _, reaction := range reactions {
		result[reaction.EntryID] = append(result[reaction.EntryID], reaction)
	}
	return result
}

func groupCommentsByEntry(comments []domain.FeedComment) map[string][]domain.FeedComment {
	result := map[string][]domain.FeedComment{}
	for _, comment := range comments {
		result[comment.EntryID] = append(result[comment.EntryID], comment)
	}
	return result
}

func hasReactionFromUser(reactions []domain.FeedReaction, userID string) bool {
	for _, reaction := range reactions {
		if reaction.UserID == userID {
			return true
		}
	}
	return false
}

func (s *Service) ListAchievementsByUserIDs(userIDs []string) ([]domain.Achievement, error) {
	return s.repo.ListAchievementsByUserIDs(userIDs)
}

func (s *Service) ListPublicSharedResourcesByUserIDs(userIDs []string) ([]domain.SharedResource, error) {
	return s.repo.ListPublicSharedResourcesByUserIDs(userIDs)
}

