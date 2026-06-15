-- Schema SQLite para el storage social de Memorizar.
-- Mismas entidades que el repository en memoria/file. Tipos JSON para los
-- mapas (ej. providers).

CREATE TABLE IF NOT EXISTS users (
    id              TEXT PRIMARY KEY,
    email           TEXT NOT NULL DEFAULT '',
    display_name    TEXT NOT NULL DEFAULT '',
    username        TEXT NOT NULL DEFAULT '',
    age             INTEGER NOT NULL DEFAULT 0,
    avatar_url      TEXT NOT NULL DEFAULT '',
    providers_json  TEXT NOT NULL DEFAULT '{}',
    password_hash   TEXT NOT NULL DEFAULT '',
    locale          TEXT NOT NULL DEFAULT '',
    email_verified  INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL,
    updated_at      TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE username != '';

CREATE TABLE IF NOT EXISTS sessions (
    token       TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider    TEXT NOT NULL DEFAULT '',
    created_at  TEXT NOT NULL,
    expires_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);

CREATE TABLE IF NOT EXISTS friendships (
    id            TEXT PRIMARY KEY,
    requester_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status        TEXT NOT NULL,
    created_at    TEXT NOT NULL,
    updated_at    TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_friendships_req ON friendships(requester_id);
CREATE INDEX IF NOT EXISTS idx_friendships_addr ON friendships(addressee_id);

CREATE TABLE IF NOT EXISTS achievements (
    id           TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code         TEXT NOT NULL DEFAULT '',
    title        TEXT NOT NULL DEFAULT '',
    description  TEXT NOT NULL DEFAULT '',
    deck_name    TEXT NOT NULL DEFAULT '',
    emoji        TEXT NOT NULL DEFAULT '',
    unlocked_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_achievements_user ON achievements(user_id);

CREATE TABLE IF NOT EXISTS activities (
    id           TEXT PRIMARY KEY,
    user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code         TEXT NOT NULL DEFAULT '',
    title        TEXT NOT NULL DEFAULT '',
    description  TEXT NOT NULL DEFAULT '',
    deck_name    TEXT NOT NULL DEFAULT '',
    created_at   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_activities_user ON activities(user_id);

CREATE TABLE IF NOT EXISTS shared_resources (
    id              TEXT PRIMARY KEY,
    owner_user_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_user_id  TEXT NOT NULL DEFAULT '',
    kind            TEXT NOT NULL,
    title           TEXT NOT NULL DEFAULT '',
    summary         TEXT NOT NULL DEFAULT '',
    deck_id         TEXT NOT NULL DEFAULT '',
    plan_id         TEXT NOT NULL DEFAULT '',
    payload_json    TEXT NOT NULL DEFAULT '',
    is_public       INTEGER NOT NULL DEFAULT 0,
    created_at      TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_shares_owner ON shared_resources(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_shares_target ON shared_resources(target_user_id);

CREATE TABLE IF NOT EXISTS share_imports (
    share_id    TEXT NOT NULL REFERENCES shared_resources(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TEXT NOT NULL,
    PRIMARY KEY (share_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_share_imports_share ON share_imports(share_id);

CREATE TABLE IF NOT EXISTS deck_likes (
    share_id    TEXT NOT NULL REFERENCES shared_resources(id) ON DELETE CASCADE,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TEXT NOT NULL,
    PRIMARY KEY (share_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_deck_likes_share ON deck_likes(share_id);

CREATE TABLE IF NOT EXISTS follows (
    follower_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    creator_id   TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at   TEXT NOT NULL,
    PRIMARY KEY (follower_id, creator_id)
);
CREATE INDEX IF NOT EXISTS idx_follows_creator ON follows(creator_id);

CREATE TABLE IF NOT EXISTS deck_reports (
    id           TEXT PRIMARY KEY,
    deck_id      TEXT NOT NULL,
    deck_title   TEXT NOT NULL DEFAULT '',
    reporter_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason       TEXT NOT NULL,
    note         TEXT NOT NULL DEFAULT '',
    status       TEXT NOT NULL DEFAULT 'pending',
    created_at   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_deck_reports_status ON deck_reports(status);

CREATE TABLE IF NOT EXISTS analytics_events (
    id          TEXT PRIMARY KEY,
    user_id     TEXT NOT NULL DEFAULT '',
    event       TEXT NOT NULL,
    props_json  TEXT NOT NULL DEFAULT '',
    created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_analytics_event ON analytics_events(event);

CREATE TABLE IF NOT EXISTS premium_subscriptions (
    user_id       TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    plan          TEXT NOT NULL,
    activated_at  TEXT NOT NULL,
    expires_at    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS push_tokens (
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token       TEXT NOT NULL,
    platform    TEXT NOT NULL DEFAULT '',
    updated_at  TEXT NOT NULL,
    PRIMARY KEY (user_id, token)
);

CREATE TABLE IF NOT EXISTS feed_reactions (
    id          TEXT PRIMARY KEY,
    entry_id    TEXT NOT NULL,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji       TEXT NOT NULL DEFAULT '',
    created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_reactions_entry ON feed_reactions(entry_id);

CREATE TABLE IF NOT EXISTS feed_comments (
    id          TEXT PRIMARY KEY,
    entry_id    TEXT NOT NULL,
    user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    body        TEXT NOT NULL DEFAULT '',
    created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_comments_entry ON feed_comments(entry_id);

CREATE TABLE IF NOT EXISTS progress_snapshots (
    id            TEXT PRIMARY KEY,
    user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id     TEXT NOT NULL DEFAULT '',
    payload_json  TEXT NOT NULL DEFAULT '',
    captured_at   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_snapshots_user ON progress_snapshots(user_id);
