CREATE TABLE IF NOT EXISTS teams (
    id SERIAL PRIMARY KEY,
    code VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) UNIQUE NOT NULL,
    short_name VARCHAR(50),
    logo_url VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stadiums (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(100),
    address VARCHAR(300),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    nickname VARCHAR(50),
    my_team_id INTEGER REFERENCES teams(id),
    device_login_key VARCHAR(200) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS devices (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    platform VARCHAR(20) NOT NULL,
    fcm_token VARCHAR(500),
    app_version VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS games (
    id SERIAL PRIMARY KEY,
    season_year INTEGER NOT NULL,
    game_date DATE NOT NULL,
    game_time TIME,
    home_team_id INTEGER NOT NULL REFERENCES teams(id),
    away_team_id INTEGER NOT NULL REFERENCES teams(id),
    stadium_id INTEGER REFERENCES stadiums(id),
    status VARCHAR(30) NOT NULL DEFAULT 'scheduled',
    home_score INTEGER,
    away_score INTEGER,
    external_source VARCHAR(50),
    external_game_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (external_source, external_game_id)
);

CREATE TABLE IF NOT EXISTS game_live_states (
    id SERIAL PRIMARY KEY,
    game_id INTEGER UNIQUE NOT NULL REFERENCES games(id),
    inning INTEGER,
    inning_half VARCHAR(10),
    outs INTEGER,
    base_state VARCHAR(10),
    description VARCHAR(500),
    last_source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS game_scores_by_inning (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id),
    inning INTEGER NOT NULL,
    home_score INTEGER,
    away_score INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    birth_date DATE,
    throwing_hand VARCHAR(10),
    batting_hand VARCHAR(10),
    external_player_id VARCHAR(100),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS attendance_records (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    game_id INTEGER NOT NULL REFERENCES games(id),
    attend_type VARCHAR(20) NOT NULL DEFAULT 'stadium',
    my_team_id INTEGER REFERENCES teams(id),
    result_for_my_team VARCHAR(10),
    seat_section VARCHAR(100),
    seat_row VARCHAR(100),
    seat_number VARCHAR(100),
    memo TEXT,
    rating INTEGER,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS batting_game_stats (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id),
    player_id INTEGER NOT NULL REFERENCES players(id),
    team_id INTEGER NOT NULL REFERENCES teams(id),
    batting_order INTEGER,
    position VARCHAR(20),
    ab INTEGER DEFAULT 0,
    r INTEGER DEFAULT 0,
    h INTEGER DEFAULT 0,
    hr INTEGER DEFAULT 0,
    rbi INTEGER DEFAULT 0,
    bb INTEGER DEFAULT 0,
    so INTEGER DEFAULT 0,
    avg_after_game NUMERIC(5, 3),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS pitching_game_stats (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id),
    player_id INTEGER NOT NULL REFERENCES players(id),
    team_id INTEGER NOT NULL REFERENCES teams(id),
    innings_pitched NUMERIC(4, 1),
    hits INTEGER DEFAULT 0,
    runs INTEGER DEFAULT 0,
    earned_runs INTEGER DEFAULT 0,
    walks INTEGER DEFAULT 0,
    strikeouts INTEGER DEFAULT 0,
    pitches INTEGER,
    era_after_game NUMERIC(5, 2),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS game_events (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id),
    sequence_no INTEGER NOT NULL,
    inning INTEGER NOT NULL,
    inning_half VARCHAR(10) NOT NULL,
    batting_team_id INTEGER REFERENCES teams(id),
    fielding_team_id INTEGER REFERENCES teams(id),
    batter_id INTEGER REFERENCES players(id),
    pitcher_id INTEGER REFERENCES players(id),
    outs_before INTEGER NOT NULL,
    base_state_before VARCHAR(3) NOT NULL DEFAULT '000',
    score_diff_before INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    description TEXT,
    runs_scored INTEGER NOT NULL DEFAULT 0,
    outs_after INTEGER NOT NULL,
    base_state_after VARCHAR(3) NOT NULL DEFAULT '000',
    score_diff_after INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS win_expectancy_table (
    id SERIAL PRIMARY KEY,
    season_year INTEGER NOT NULL,
    inning INTEGER NOT NULL,
    inning_half VARCHAR(10) NOT NULL,
    outs INTEGER NOT NULL,
    base_state VARCHAR(3) NOT NULL,
    score_diff INTEGER NOT NULL,
    win_expectancy NUMERIC(6, 5) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wpa_events (
    id SERIAL PRIMARY KEY,
    game_event_id INTEGER UNIQUE NOT NULL REFERENCES game_events(id),
    batter_id INTEGER REFERENCES players(id),
    pitcher_id INTEGER REFERENCES players(id),
    we_before NUMERIC(6, 5) NOT NULL,
    we_after NUMERIC(6, 5) NOT NULL,
    wpa NUMERIC(7, 5) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_game_wpa (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id),
    player_id INTEGER NOT NULL REFERENCES players(id),
    team_id INTEGER REFERENCES teams(id),
    batting_wpa NUMERIC(7, 5) DEFAULT 0,
    pitching_wpa NUMERIC(7, 5) DEFAULT 0,
    total_wpa NUMERIC(7, 5) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS sync_jobs (
    id SERIAL PRIMARY KEY,
    job_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'pending',
    target_date VARCHAR(20),
    message TEXT,
    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS source_mappings (
    id SERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL,
    source_type VARCHAR(50) NOT NULL,
    external_id VARCHAR(100) NOT NULL,
    internal_type VARCHAR(50) NOT NULL,
    internal_id INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE (source, source_type, external_id)
);

CREATE INDEX IF NOT EXISTS idx_games_date ON games(game_date);
CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance_records(user_id);
CREATE INDEX IF NOT EXISTS idx_game_events_game ON game_events(game_id);
CREATE INDEX IF NOT EXISTS idx_player_game_wpa_game ON player_game_wpa(game_id);
