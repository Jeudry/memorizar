// Package sqlite implementa ports.Repository contra una DB SQLite.
//
// Usa modernc.org/sqlite (puro Go, sin CGo) para evitar líos de toolchain
// cuando se cross-compile el binario. Schema en schema.sql, embebido vía
// `//go:embed`.
package sqlite

import (
	"database/sql"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/Jeudry/memorizar/backend/internal/social/domain"
	_ "modernc.org/sqlite"
)

//go:embed schema.sql
var schema string

// Repository es la implementación SQLite del puerto.
type Repository struct {
	db *sql.DB
}

// Open abre/crea la base en la ruta dada y aplica migraciones idempotentes.
func Open(path string) (*Repository, error) {
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("open sqlite: %w", err)
	}
	if _, err := db.Exec("PRAGMA foreign_keys = ON;"); err != nil {
		return nil, fmt.Errorf("enable fk: %w", err)
	}
	if _, err := db.Exec(schema); err != nil {
		return nil, fmt.Errorf("apply schema: %w", err)
	}
	return &Repository{db: db}, nil
}

// Close cierra la DB. Llamarlo en shutdown del proceso.
func (r *Repository) Close() error { return r.db.Close() }

// ─── Helpers ────────────────────────────────────────────────────────────

func parseTime(s string) time.Time {
	t, _ := time.Parse(time.RFC3339Nano, s)
	return t
}

func formatTime(t time.Time) string { return t.UTC().Format(time.RFC3339Nano) }

func parseProviders(raw string) map[string]string {
	if raw == "" {
		return map[string]string{}
	}
	out := map[string]string{}
	_ = json.Unmarshal([]byte(raw), &out)
	return out
}

func encodeProviders(m map[string]string) string {
	if m == nil {
		return "{}"
	}
	b, _ := json.Marshal(m)
	return string(b)
}

// ─── Users ──────────────────────────────────────────────────────────────

func (r *Repository) scanUser(scan func(...any) error) (*domain.User, error) {
	var u domain.User
	var providersJSON, createdAt, updatedAt string
	var emailVerified int
	if err := scan(
		&u.ID, &u.Email, &u.DisplayName, &u.Username, &u.Age, &u.AvatarURL,
		&providersJSON, &u.PasswordHash, &u.Locale, &emailVerified,
		&createdAt, &updatedAt,
	); err != nil {
		return nil, err
	}
	u.Providers = parseProviders(providersJSON)
	u.EmailVerified = emailVerified == 1
	u.CreatedAt = parseTime(createdAt)
	u.UpdatedAt = parseTime(updatedAt)
	return &u, nil
}

const userCols = `id, email, display_name, username, age, avatar_url, providers_json,
    password_hash, locale, email_verified, created_at, updated_at`

func (r *Repository) FindUserByID(userID string) (*domain.User, error) {
	row := r.db.QueryRow(`SELECT `+userCols+` FROM users WHERE id = ?`, userID)
	u, err := r.scanUser(row.Scan)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return u, err
}

func (r *Repository) FindUserByEmail(email string) (*domain.User, error) {
	row := r.db.QueryRow(`SELECT `+userCols+` FROM users WHERE email = ?`, strings.ToLower(email))
	u, err := r.scanUser(row.Scan)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return u, err
}

func (r *Repository) FindUserByUsername(username string) (*domain.User, error) {
	row := r.db.QueryRow(`SELECT `+userCols+` FROM users WHERE LOWER(username) = ?`, strings.ToLower(strings.TrimSpace(username)))
	u, err := r.scanUser(row.Scan)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return u, err
}

func (r *Repository) FindUserByProvider(provider domain.SocialProvider, providerUserID string) (*domain.User, error) {
	rows, err := r.db.Query(`SELECT ` + userCols + ` FROM users`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		u, err := r.scanUser(rows.Scan)
		if err != nil {
			return nil, err
		}
		if u.Providers[string(provider)] == providerUserID {
			return u, nil
		}
	}
	return nil, nil
}

func (r *Repository) ListUsers() ([]domain.User, error) {
	rows, err := r.db.Query(`SELECT ` + userCols + ` FROM users ORDER BY created_at`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.User{}
	for rows.Next() {
		u, err := r.scanUser(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, *u)
	}
	return out, nil
}

func (r *Repository) SaveUser(u domain.User) error {
	emailVerified := 0
	if u.EmailVerified {
		emailVerified = 1
	}
	_, err := r.db.Exec(`
		INSERT INTO users (`+userCols+`)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
		    email = excluded.email,
		    display_name = excluded.display_name,
		    username = excluded.username,
		    age = excluded.age,
		    avatar_url = excluded.avatar_url,
		    providers_json = excluded.providers_json,
		    password_hash = excluded.password_hash,
		    locale = excluded.locale,
		    email_verified = excluded.email_verified,
		    updated_at = excluded.updated_at`,
		u.ID, strings.ToLower(u.Email), u.DisplayName, u.Username, u.Age, u.AvatarURL,
		encodeProviders(u.Providers), u.PasswordHash, u.Locale, emailVerified,
		formatTime(u.CreatedAt), formatTime(u.UpdatedAt),
	)
	return err
}

// ─── Sessions ───────────────────────────────────────────────────────────

func (r *Repository) SaveSession(s domain.Session) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO sessions (token, user_id, provider, created_at, expires_at)
		VALUES (?, ?, ?, ?, ?)`,
		s.Token, s.UserID, string(s.Provider),
		formatTime(s.CreatedAt), formatTime(s.ExpiresAt),
	)
	return err
}

func (r *Repository) FindSession(token string) (*domain.Session, error) {
	var s domain.Session
	var providerStr, createdAt, expiresAt string
	err := r.db.QueryRow(`
		SELECT token, user_id, provider, created_at, expires_at
		FROM sessions WHERE token = ?`,
		token,
	).Scan(&s.Token, &s.UserID, &providerStr, &createdAt, &expiresAt)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	s.Provider = domain.SocialProvider(providerStr)
	s.CreatedAt = parseTime(createdAt)
	s.ExpiresAt = parseTime(expiresAt)
	return &s, nil
}

// ─── Friendships ────────────────────────────────────────────────────────

func (r *Repository) scanFriendship(scan func(...any) error) (*domain.Friendship, error) {
	var f domain.Friendship
	var status, createdAt, updatedAt string
	if err := scan(&f.ID, &f.RequesterID, &f.AddresseeID, &status, &createdAt, &updatedAt); err != nil {
		return nil, err
	}
	f.Status = domain.FriendshipStatus(status)
	f.CreatedAt = parseTime(createdAt)
	f.UpdatedAt = parseTime(updatedAt)
	return &f, nil
}

func (r *Repository) SaveFriendship(f domain.Friendship) error {
	_, err := r.db.Exec(`
		INSERT INTO friendships (id, requester_id, addressee_id, status, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(id) DO UPDATE SET
		    status = excluded.status,
		    updated_at = excluded.updated_at`,
		f.ID, f.RequesterID, f.AddresseeID, string(f.Status),
		formatTime(f.CreatedAt), formatTime(f.UpdatedAt),
	)
	return err
}

func (r *Repository) FindFriendship(userA, userB string) (*domain.Friendship, error) {
	row := r.db.QueryRow(`
		SELECT id, requester_id, addressee_id, status, created_at, updated_at
		FROM friendships
		WHERE (requester_id = ? AND addressee_id = ?) OR (requester_id = ? AND addressee_id = ?)
		LIMIT 1`,
		userA, userB, userB, userA,
	)
	f, err := r.scanFriendship(row.Scan)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return f, err
}

func (r *Repository) FindFriendshipByID(id string) (*domain.Friendship, error) {
	row := r.db.QueryRow(`
		SELECT id, requester_id, addressee_id, status, created_at, updated_at
		FROM friendships WHERE id = ?`,
		id,
	)
	f, err := r.scanFriendship(row.Scan)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return f, err
}

func (r *Repository) ListFriendships(userID string, status domain.FriendshipStatus) ([]domain.Friendship, error) {
	rows, err := r.db.Query(`
		SELECT id, requester_id, addressee_id, status, created_at, updated_at
		FROM friendships
		WHERE (requester_id = ? OR addressee_id = ?) AND status = ?
		ORDER BY created_at DESC`,
		userID, userID, string(status),
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Friendship{}
	for rows.Next() {
		f, err := r.scanFriendship(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, *f)
	}
	return out, nil
}

// ─── Achievements & Activities ──────────────────────────────────────────

func (r *Repository) SaveAchievement(a domain.Achievement) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO achievements (id, user_id, code, title, description, deck_name, emoji, unlocked_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		a.ID, a.UserID, a.Code, a.Title, a.Description, a.DeckName, a.Emoji,
		formatTime(a.UnlockedAt),
	)
	return err
}

func (r *Repository) ListAchievementsByUserIDs(userIDs []string) ([]domain.Achievement, error) {
	if len(userIDs) == 0 {
		return []domain.Achievement{}, nil
	}
	placeholders := strings.Repeat("?,", len(userIDs)-1) + "?"
	args := make([]any, len(userIDs))
	for i, v := range userIDs {
		args[i] = v
	}
	rows, err := r.db.Query(`
		SELECT id, user_id, code, title, description, deck_name, emoji, unlocked_at
		FROM achievements WHERE user_id IN (`+placeholders+`)
		ORDER BY unlocked_at DESC`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Achievement{}
	for rows.Next() {
		var a domain.Achievement
		var ts string
		if err := rows.Scan(&a.ID, &a.UserID, &a.Code, &a.Title, &a.Description, &a.DeckName, &a.Emoji, &ts); err != nil {
			return nil, err
		}
		a.UnlockedAt = parseTime(ts)
		out = append(out, a)
	}
	return out, nil
}

func (r *Repository) SaveActivity(a domain.Activity) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO activities (id, user_id, code, title, description, deck_name, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?)`,
		a.ID, a.UserID, a.Code, a.Title, a.Description, a.DeckName,
		formatTime(a.CreatedAt),
	)
	return err
}

func (r *Repository) ListActivitiesByUserIDs(userIDs []string) ([]domain.Activity, error) {
	if len(userIDs) == 0 {
		return []domain.Activity{}, nil
	}
	placeholders := strings.Repeat("?,", len(userIDs)-1) + "?"
	args := make([]any, len(userIDs))
	for i, v := range userIDs {
		args[i] = v
	}
	rows, err := r.db.Query(`
		SELECT id, user_id, code, title, description, deck_name, created_at
		FROM activities WHERE user_id IN (`+placeholders+`)
		ORDER BY created_at DESC`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.Activity{}
	for rows.Next() {
		var a domain.Activity
		var ts string
		if err := rows.Scan(&a.ID, &a.UserID, &a.Code, &a.Title, &a.Description, &a.DeckName, &ts); err != nil {
			return nil, err
		}
		a.CreatedAt = parseTime(ts)
		out = append(out, a)
	}
	return out, nil
}

// ─── Shared Resources ───────────────────────────────────────────────────

func (r *Repository) SaveSharedResource(s domain.SharedResource) error {
	isPublic := 0
	if s.IsPublic {
		isPublic = 1
	}
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO shared_resources
		    (id, owner_user_id, target_user_id, kind, title, summary,
		     deck_id, plan_id, payload_json, is_public, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		s.ID, s.OwnerUserID, s.TargetUserID, string(s.Kind), s.Title, s.Summary,
		s.DeckID, s.PlanID, s.PayloadJSON, isPublic, formatTime(s.CreatedAt),
	)
	return err
}

func (r *Repository) scanShare(scan func(...any) error) (*domain.SharedResource, error) {
	var s domain.SharedResource
	var kind, ts string
	var isPublic int
	if err := scan(
		&s.ID, &s.OwnerUserID, &s.TargetUserID, &kind, &s.Title, &s.Summary,
		&s.DeckID, &s.PlanID, &s.PayloadJSON, &isPublic, &ts,
	); err != nil {
		return nil, err
	}
	s.Kind = domain.ShareKind(kind)
	s.IsPublic = isPublic == 1
	s.CreatedAt = parseTime(ts)
	return &s, nil
}

func (r *Repository) ListSharedResourcesForUser(userID string) ([]domain.SharedResource, error) {
	rows, err := r.db.Query(`
		SELECT id, owner_user_id, target_user_id, kind, title, summary,
		       deck_id, plan_id, payload_json, is_public, created_at
		FROM shared_resources
		WHERE owner_user_id = ? OR target_user_id = ?
		ORDER BY created_at DESC`,
		userID, userID,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.SharedResource{}
	for rows.Next() {
		s, err := r.scanShare(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, *s)
	}
	return out, nil
}

func (r *Repository) ListPublicSharedResourcesByUserIDs(userIDs []string) ([]domain.SharedResource, error) {
	if len(userIDs) == 0 {
		return []domain.SharedResource{}, nil
	}
	placeholders := strings.Repeat("?,", len(userIDs)-1) + "?"
	args := make([]any, len(userIDs))
	for i, v := range userIDs {
		args[i] = v
	}
	rows, err := r.db.Query(`
		SELECT id, owner_user_id, target_user_id, kind, title, summary,
		       deck_id, plan_id, payload_json, is_public, created_at
		FROM shared_resources
		WHERE is_public = 1 AND owner_user_id IN (`+placeholders+`)
		ORDER BY created_at DESC`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.SharedResource{}
	for rows.Next() {
		s, err := r.scanShare(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, *s)
	}
	return out, nil
}

func (r *Repository) SaveShareImport(shareImport domain.ShareImport) error {
	_, err := r.db.Exec(`
		INSERT OR IGNORE INTO share_imports (share_id, user_id, created_at)
		VALUES (?, ?, ?)`,
		shareImport.ShareID, shareImport.UserID, formatTime(shareImport.CreatedAt),
	)
	return err
}

func (r *Repository) CountShareImports(shareIDs []string) (map[string]int, error) {
	return r.countShareImportsWhere(shareIDs, "", nil)
}

func (r *Repository) CountShareImportsSince(shareIDs []string, since time.Time) (map[string]int, error) {
	return r.countShareImportsWhere(shareIDs, " AND created_at >= ?", []any{formatTime(since)})
}

func (r *Repository) countShareImportsWhere(shareIDs []string, extraWhere string, extraArgs []any) (map[string]int, error) {
	counts := map[string]int{}
	if len(shareIDs) == 0 {
		return counts, nil
	}
	placeholders := strings.Repeat("?,", len(shareIDs)-1) + "?"
	args := make([]any, 0, len(shareIDs)+len(extraArgs))
	for _, v := range shareIDs {
		args = append(args, v)
	}
	args = append(args, extraArgs...)
	rows, err := r.db.Query(`
		SELECT share_id, COUNT(*)
		FROM share_imports
		WHERE share_id IN (`+placeholders+`)`+extraWhere+`
		GROUP BY share_id`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	for rows.Next() {
		var shareID string
		var count int
		if err := rows.Scan(&shareID, &count); err != nil {
			return nil, err
		}
		counts[shareID] = count
	}
	return counts, nil
}

// ─── Deck reports (moderación) ───────────────────────────────────────────

func (r *Repository) SaveDeckReport(report domain.DeckReport) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO deck_reports
		    (id, deck_id, deck_title, reporter_id, reason, note, status, created_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
		report.ID, report.DeckID, report.DeckTitle, report.ReporterID,
		report.Reason, report.Note, string(report.Status), formatTime(report.CreatedAt),
	)
	return err
}

func (r *Repository) scanDeckReport(scan func(...any) error) (*domain.DeckReport, error) {
	var report domain.DeckReport
	var status, ts string
	if err := scan(
		&report.ID, &report.DeckID, &report.DeckTitle, &report.ReporterID,
		&report.Reason, &report.Note, &status, &ts,
	); err != nil {
		return nil, err
	}
	report.Status = domain.DeckReportStatus(status)
	report.CreatedAt = parseTime(ts)
	return &report, nil
}

func (r *Repository) FindDeckReportByID(reportID string) (*domain.DeckReport, error) {
	row := r.db.QueryRow(`
		SELECT id, deck_id, deck_title, reporter_id, reason, note, status, created_at
		FROM deck_reports WHERE id = ?`, reportID)
	report, err := r.scanDeckReport(row.Scan)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return report, err
}

func (r *Repository) ListDeckReports() ([]domain.DeckReport, error) {
	rows, err := r.db.Query(`
		SELECT id, deck_id, deck_title, reporter_id, reason, note, status, created_at
		FROM deck_reports ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.DeckReport{}
	for rows.Next() {
		report, err := r.scanDeckReport(rows.Scan)
		if err != nil {
			return nil, err
		}
		out = append(out, *report)
	}
	return out, nil
}

// ─── Premium ─────────────────────────────────────────────────────────────

func (r *Repository) SavePremiumSubscription(subscription domain.PremiumSubscription) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO premium_subscriptions (user_id, plan, activated_at, expires_at)
		VALUES (?, ?, ?, ?)`,
		subscription.UserID, subscription.Plan,
		formatTime(subscription.ActivatedAt), formatTime(subscription.ExpiresAt),
	)
	return err
}

func (r *Repository) FindPremiumSubscription(userID string) (*domain.PremiumSubscription, error) {
	row := r.db.QueryRow(`
		SELECT user_id, plan, activated_at, expires_at
		FROM premium_subscriptions WHERE user_id = ?`, userID)
	var subscription domain.PremiumSubscription
	var activatedAt, expiresAt string
	err := row.Scan(&subscription.UserID, &subscription.Plan, &activatedAt, &expiresAt)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	subscription.ActivatedAt = parseTime(activatedAt)
	subscription.ExpiresAt = parseTime(expiresAt)
	return &subscription, nil
}

// ─── Analytics ────────────────────────────────────────────────────────────

func (r *Repository) SaveAnalyticsEvents(events []domain.AnalyticsEvent) error {
	if len(events) == 0 {
		return nil
	}
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	stmt, err := tx.Prepare(`
		INSERT OR IGNORE INTO analytics_events (id, user_id, event, props_json, created_at)
		VALUES (?, ?, ?, ?, ?)`)
	if err != nil {
		return err
	}
	defer stmt.Close()
	for _, event := range events {
		if _, err := stmt.Exec(event.ID, event.UserID, event.Event, event.PropsJSON, formatTime(event.CreatedAt)); err != nil {
			return err
		}
	}
	return tx.Commit()
}

func (r *Repository) CountAnalyticsEventsByName() (map[string]int, error) {
	rows, err := r.db.Query(`SELECT event, COUNT(*) FROM analytics_events GROUP BY event`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	counts := map[string]int{}
	for rows.Next() {
		var event string
		var count int
		if err := rows.Scan(&event, &count); err != nil {
			return nil, err
		}
		counts[event] = count
	}
	return counts, nil
}

// ─── Reactions & Comments ───────────────────────────────────────────────

func (r *Repository) SaveReaction(x domain.FeedReaction) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO feed_reactions (id, entry_id, user_id, emoji, created_at)
		VALUES (?, ?, ?, ?, ?)`,
		x.ID, x.EntryID, x.UserID, x.Emoji, formatTime(x.CreatedAt),
	)
	return err
}

func (r *Repository) ListReactionsByEntryIDs(entryIDs []string) ([]domain.FeedReaction, error) {
	if len(entryIDs) == 0 {
		return []domain.FeedReaction{}, nil
	}
	placeholders := strings.Repeat("?,", len(entryIDs)-1) + "?"
	args := make([]any, len(entryIDs))
	for i, v := range entryIDs {
		args[i] = v
	}
	rows, err := r.db.Query(`
		SELECT id, entry_id, user_id, emoji, created_at
		FROM feed_reactions WHERE entry_id IN (`+placeholders+`)`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.FeedReaction{}
	for rows.Next() {
		var x domain.FeedReaction
		var ts string
		if err := rows.Scan(&x.ID, &x.EntryID, &x.UserID, &x.Emoji, &ts); err != nil {
			return nil, err
		}
		x.CreatedAt = parseTime(ts)
		out = append(out, x)
	}
	return out, nil
}

func (r *Repository) SaveComment(c domain.FeedComment) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO feed_comments (id, entry_id, user_id, body, created_at)
		VALUES (?, ?, ?, ?, ?)`,
		c.ID, c.EntryID, c.UserID, c.Body, formatTime(c.CreatedAt),
	)
	return err
}

func (r *Repository) ListCommentsByEntryIDs(entryIDs []string) ([]domain.FeedComment, error) {
	if len(entryIDs) == 0 {
		return []domain.FeedComment{}, nil
	}
	placeholders := strings.Repeat("?,", len(entryIDs)-1) + "?"
	args := make([]any, len(entryIDs))
	for i, v := range entryIDs {
		args[i] = v
	}
	rows, err := r.db.Query(`
		SELECT id, entry_id, user_id, body, created_at
		FROM feed_comments WHERE entry_id IN (`+placeholders+`)
		ORDER BY created_at`, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	out := []domain.FeedComment{}
	for rows.Next() {
		var c domain.FeedComment
		var ts string
		if err := rows.Scan(&c.ID, &c.EntryID, &c.UserID, &c.Body, &ts); err != nil {
			return nil, err
		}
		c.CreatedAt = parseTime(ts)
		out = append(out, c)
	}
	return out, nil
}

// ─── Progress Snapshots ─────────────────────────────────────────────────

func (r *Repository) SaveProgressSnapshot(s domain.ProgressSnapshot) error {
	_, err := r.db.Exec(`
		INSERT OR REPLACE INTO progress_snapshots (id, user_id, device_id, payload_json, captured_at)
		VALUES (?, ?, ?, ?, ?)`,
		s.ID, s.UserID, s.DeviceID, s.PayloadJSON, formatTime(s.CapturedAt),
	)
	return err
}

func (r *Repository) FindLatestProgressSnapshot(userID string) (*domain.ProgressSnapshot, error) {
	var s domain.ProgressSnapshot
	var ts string
	err := r.db.QueryRow(`
		SELECT id, user_id, device_id, payload_json, captured_at
		FROM progress_snapshots
		WHERE user_id = ?
		ORDER BY captured_at DESC LIMIT 1`,
		userID,
	).Scan(&s.ID, &s.UserID, &s.DeviceID, &s.PayloadJSON, &ts)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	s.CapturedAt = parseTime(ts)
	return &s, nil
}

// ─── Cascade delete ─────────────────────────────────────────────────────

func (r *Repository) DeleteUserCascade(userID string) error {
	// Foreign keys con ON DELETE CASCADE hacen el trabajo, pero algunas
	// columnas (target_user_id en shares) son TEXT sin FK formal —
	// limpiamos a mano.
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	if _, err := tx.Exec(`UPDATE shared_resources SET target_user_id = '' WHERE target_user_id = ?`, userID); err != nil {
		return err
	}
	if _, err := tx.Exec(`DELETE FROM friendships WHERE requester_id = ? OR addressee_id = ?`, userID, userID); err != nil {
		return err
	}
	if _, err := tx.Exec(`DELETE FROM users WHERE id = ?`, userID); err != nil {
		return err
	}
	return tx.Commit()
}
