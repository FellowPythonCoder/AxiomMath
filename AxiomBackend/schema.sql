CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    grade INTEGER DEFAULT 1,
    has_selected_grade INTEGER DEFAULT 0,
    xp INTEGER DEFAULT 0,
    coins INTEGER DEFAULT 500,
    points INTEGER DEFAULT 0,
    challenge_streak INTEGER DEFAULT 0,
    last_challenge_date TEXT,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS owned_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    item_id TEXT NOT NULL,
    acquired_at TEXT DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, item_id),
    FOREIGN KEY(user_id) REFERENCES users(id)
);