-- =====================================================================
-- CS1DB — Tennis Tournament Database — Schema (DDL)
-- Target: PostgreSQL 14+
-- Re-runnable: drops existing objects in reverse dependency order.
-- =====================================================================

DROP TABLE IF EXISTS performance_flag CASCADE;
DROP TABLE IF EXISTS match_score      CASCADE;
DROP TABLE IF EXISTS match_player     CASCADE;
DROP TABLE IF EXISTS match            CASCADE;
DROP TABLE IF EXISTS tournament       CASCADE;
DROP TABLE IF EXISTS player_coach     CASCADE;
DROP TABLE IF EXISTS coach            CASCADE;
DROP TABLE IF EXISTS player           CASCADE;

-- ---------------------------------------------------------------------
-- Player: a professional tennis player (male or female).
-- ---------------------------------------------------------------------
CREATE TABLE player (
    id            SERIAL       PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    gender        CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F')),
    nationality   VARCHAR(60)  NOT NULL,
    date_of_birth DATE         NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- Coach: must have professional playing experience (business rule).
-- ---------------------------------------------------------------------
CREATE TABLE coach (
    id                       SERIAL       PRIMARY KEY,
    name                     VARCHAR(100) NOT NULL,
    nationality              VARCHAR(60)  NOT NULL,
    former_player_experience BOOLEAN      NOT NULL
        CHECK (former_player_experience = TRUE)
);

-- ---------------------------------------------------------------------
-- PlayerCoach: temporal many-to-many link. NULL end_date == active.
-- ---------------------------------------------------------------------
CREATE TABLE player_coach (
    id         SERIAL  PRIMARY KEY,
    player_id  INT     NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    coach_id   INT     NOT NULL REFERENCES coach(id)  ON DELETE CASCADE,
    start_date DATE    NOT NULL,
    end_date   DATE,
    CONSTRAINT chk_player_coach_dates
        CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT uq_player_coach_start
        UNIQUE (player_id, coach_id, start_date)
);

-- ---------------------------------------------------------------------
-- Tournament
-- ---------------------------------------------------------------------
CREATE TABLE tournament (
    id            SERIAL       PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    location      VARCHAR(100) NOT NULL,
    surface_type  VARCHAR(20)  NOT NULL
        CHECK (surface_type IN ('Hard', 'Clay', 'Grass')),
    start_date    DATE         NOT NULL,
    end_date      DATE         NOT NULL,
    is_grand_slam BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_tournament_dates CHECK (end_date > start_date)
);

-- ---------------------------------------------------------------------
-- Match: one match within a tournament round.
-- ---------------------------------------------------------------------
CREATE TABLE match (
    id            SERIAL      PRIMARY KEY,
    tournament_id INT         NOT NULL REFERENCES tournament(id) ON DELETE CASCADE,
    round         VARCHAR(10) NOT NULL
        CHECK (round IN ('R128','R64','R32','R16','QF','SF','F')),
    match_date    DATE        NOT NULL
);

-- ---------------------------------------------------------------------
-- MatchPlayer: which players are in a match (supports doubles via ≥2 rows).
-- ---------------------------------------------------------------------
CREATE TABLE match_player (
    id        SERIAL  PRIMARY KEY,
    match_id  INT     NOT NULL REFERENCES match(id)  ON DELETE CASCADE,
    player_id INT     NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    side      CHAR(1) NOT NULL CHECK (side IN ('A', 'B')),
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_match_player UNIQUE (match_id, player_id)
);

-- ---------------------------------------------------------------------
-- MatchScore: one row per set; max 5 sets in tennis.
-- ---------------------------------------------------------------------
CREATE TABLE match_score (
    id             SERIAL PRIMARY KEY,
    match_id       INT    NOT NULL REFERENCES match(id) ON DELETE CASCADE,
    set_number     INT    NOT NULL CHECK (set_number BETWEEN 1 AND 5),
    player_a_games INT    NOT NULL CHECK (player_a_games >= 0),
    player_b_games INT    NOT NULL CHECK (player_b_games >= 0),
    CONSTRAINT uq_match_score UNIQUE (match_id, set_number)
);

-- ---------------------------------------------------------------------
-- PerformanceFlag: a flagged anomaly for review (not a verdict).
-- ---------------------------------------------------------------------
CREATE TABLE performance_flag (
    id            SERIAL       PRIMARY KEY,
    player_id     INT          NOT NULL REFERENCES player(id)     ON DELETE CASCADE,
    tournament_id INT          NOT NULL REFERENCES tournament(id) ON DELETE CASCADE,
    flag_reason   VARCHAR(255) NOT NULL,
    flagged_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ---------------------------------------------------------------------
-- Indexes for join-heavy query paths.
-- ---------------------------------------------------------------------
CREATE INDEX idx_match_tournament    ON match(tournament_id);
CREATE INDEX idx_match_player_match  ON match_player(match_id);
CREATE INDEX idx_match_player_player ON match_player(player_id);
CREATE INDEX idx_match_score_match   ON match_score(match_id);
CREATE INDEX idx_player_coach_player ON player_coach(player_id);
CREATE INDEX idx_player_coach_coach  ON player_coach(coach_id);
CREATE INDEX idx_perf_flag_player    ON performance_flag(player_id);
CREATE INDEX idx_perf_flag_tournament ON performance_flag(tournament_id);
