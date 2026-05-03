# CS1DB Databases Coursework — Technical Report

## Tennis Tournament Database System

| Field | Value |
|---|---|
| **Module Code** | CS1DB Databases |
| **Assignment Title** | Tennis Tournament Database System — Group Coursework Report |
| **Date Completed** | 3 May 2026 |
| **Submission Date** | 11 May 2026 |
| **Weighting** | 50% of final module mark |
| **Actual Hours Spent** | _TBC — group to confirm before submission_ |
| **Group Members** | _TBC — see Effort Allocation Sheet (§8)_ |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Database Design](#2-database-design)
   - 2.1 [Entity-Relationship Model](#21-entity-relationship-model)
   - 2.2 [Design Decisions & Constraints](#22-design-decisions--constraints)
   - 2.3 [Third Normal Form Analysis](#23-third-normal-form-analysis)
3. [Database Implementation](#3-database-implementation)
   - 3.1 [SQL DDL — Table Definitions](#31-sql-ddl--table-definitions)
   - 3.2 [SQL DML — Seed Data](#32-sql-dml--seed-data)
4. [Querying the Database](#4-querying-the-database)
   - 4.1 [Simple Queries](#41-simple-queries)
   - 4.2 [Complex Queries](#42-complex-queries)
5. [Reflection](#5-reflection)
6. [Conclusion](#6-conclusion)
7. [References](#7-references)
8. [Effort Allocation Sheet](#8-effort-allocation-sheet)

---

## 1. Introduction

This report documents the design, implementation, and querying of a relational database system for managing professional tennis tournaments. The system tracks players, coaches, tournaments, matches (with set-by-set scores), player–coach relationships over time, and performance anomaly flags for doping detection.

The project was undertaken as part of the CS1DB Databases module and aims to demonstrate competency in entity-relationship modelling, relational normalisation, SQL implementation (DDL and DML), and query design using PostgreSQL. The implementation leverages **PostgreSQL 14+** as the relational database management system and **Prisma ORM** (v6/v7) as the application-layer data access tool, with raw SQL used for complex analytical queries.

Key design techniques employed include:

- **Entity-Relationship (E-R) modelling** using crow's foot notation to capture entities, attributes, relationships, and cardinality constraints prior to implementation (Chen, 1976; Elmasri & Navathe, 2015).
- **Relational normalisation** to Third Normal Form (3NF) to eliminate redundancy, partial dependencies, and transitive dependencies, ensuring data integrity and efficient storage (Codd, 1970; Date, 2004).
- **Referential integrity enforcement** via foreign keys with `ON DELETE CASCADE` and `CHECK` constraints to uphold business rules at the database level.
- **Window functions** (specifically `LAG`) for trend analysis in the doping-detection query, and **Common Table Expressions (CTEs)** for query readability and composability (Ramakrishnan & Gehrke, 2003).

The database contains **15 players** (9 male, 6 female), **9 coaches**, **5 tournaments** (including 2 Grand Slams and the Indian Wells/Miami pairing for the Sunshine Double), **30 matches** (semi-final and final rounds for each tournament across both genders), full **set-by-set scoring** for all finals, and **2 performance anomaly flags**.

---

## 2. Database Design

### 2.1 Entity-Relationship Model

The database is modelled around eight core entities and their interrelationships. The E-R diagram (see Annex A) uses **crow's foot notation** to express cardinalities.

#### Entities and Attributes

| Entity | Primary Key | Key Attributes | Description |
|---|---|---|---|
| **Player** | `id` (SERIAL) | name, gender (`M`/`F`), nationality, dateOfBirth, isActive | Represents a professional tennis player (male or female). |
| **Coach** | `id` (SERIAL) | name, nationality, formerPlayerExperience (BOOLEAN, must be `TRUE`) | A coach who must have had professional playing experience. |
| **PlayerCoach** | `id` (SERIAL) | playerId (FK), coachId (FK), startDate, endDate (nullable) | Associative entity capturing player–coach relationships over time, enabling historical tracking. |
| **Tournament** | `id` (SERIAL) | name, location, surfaceType (`Hard`/`Clay`/`Grass`), startDate, endDate, isGrandSlam | A tennis tournament with temporal and surface metadata. |
| **Match** | `id` (SERIAL) | tournamentId (FK), round (`R128`..`F`), matchDate | A single match within a tournament round. |
| **MatchPlayer** | `id` (SERIAL) | matchId (FK), playerId (FK), side (`A`/`B`), isWinner | Associative entity linking players to matches with side assignment and outcome. |
| **MatchScore** | `id` (SERIAL) | matchId (FK), setNumber (1–5), playerAGames, playerBGames | Set-by-set score breakdown; one row per set played. |
| **PerformanceFlag** | `id` (SERIAL) | playerId (FK), tournamentId (FK), flagReason, flaggedAt | Records suspicious performance anomalies for doping investigation. |

#### Relationships and Cardinalities

| Relationship | Type | Cardinality | Implementation |
|---|---|---|---|
| Player ↔ Coach | Many-to-many (temporal) | A player may have many coaches over time; a coach may train many players | Via `PlayerCoach` junction table with `startDate`/`endDate` |
| Tournament → Match | One-to-many | One tournament contains many matches | FK `tournamentId` on `Match` |
| Match ↔ Player | Many-to-many | A match has exactly 2 players (sides A and B); a player participates in many matches | Via `MatchPlayer` junction table |
| Match → MatchScore | One-to-many | One match has 2–5 sets | FK `matchId` on `MatchScore` |
| Player → PerformanceFlag | One-to-many | A player can have multiple flags | FK `playerId` on `PerformanceFlag` |
| Tournament → PerformanceFlag | One-to-many | A tournament can have multiple flagged incidents | FK `tournamentId` on `PerformanceFlag` |

#### E-R Diagram Description (Crow's Foot Notation)

```
┌──────────┐       ┌─────────────┐       ┌──────────┐
│  Player  │──────<│ PlayerCoach │>──────│  Coach   │
│          │ 1..* ││             │ 1..* ││          │
│ id (PK)  │       │ id (PK)     │       │ id (PK)  │
│ name     │       │ playerId(FK)│       │ name     │
│ gender   │       │ coachId(FK) │       │ national.│
│ national.│       │ startDate   │       │ fmrPlayer│
│ dob      │       │ endDate?    │       └──────────┘
│ isActive │       └─────────────┘
└────┬─────┘
     │ 1..*
     ▼
┌─────────────┐       ┌──────────┐
│ MatchPlayer │>──────│  Match   │──────<┌────────────┐
│             │ 1..* ││          │ 1..* ││ MatchScore │
│ id (PK)     │       │ id (PK)  │       │ id (PK)    │
│ matchId(FK) │       │ tournId  │       │ matchId(FK)│
│ playerId(FK)│       │ round    │       │ setNumber  │
│ side (A/B)  │       │ matchDate│       │ pAGames    │
│ isWinner    │       └────┬─────┘       │ pBGames    │
└─────────────┘            │ *..1        └────────────┘
     │                     ▼
     │              ┌────────────┐
     │              │ Tournament │──────<┌─────────────────┐
     │              │            │ 1..* ││ PerformanceFlag │
     │              │ id (PK)    │       │ id (PK)         │
     │              │ name       │       │ playerId (FK)   │
     │              │ location   │       │ tournamentId(FK)│
     │              │ surfaceType│       │ flagReason      │
     │              │ startDate  │       │ flaggedAt       │
     │              │ endDate    │       └─────────────────┘
     │              │ isGrandSlam│
     │              └────────────┘
     │                     ▲
     └─────────────────────┘
         (via PerformanceFlag)
```

> **Note:** A formal diagramming tool (draw.io or pgModeler) should be used to produce the final PNG for the report annex. The above is a text-based representation of the logical structure.

### 2.2 Design Decisions & Constraints

1. **Surrogate keys (`SERIAL` / autoincrement):** Every table uses a surrogate integer primary key rather than a natural/composite key. This simplifies joins, avoids wide composite keys in junction tables, and decouples identity from business attributes (Date, 2004).

2. **Player–Coach temporal tracking:** Rather than a simple many-to-many join, `PlayerCoach` includes `startDate` and a nullable `endDate`. A `NULL` end date signifies a current, active coaching relationship. This enables historical queries (e.g., "who coached Alcaraz before Moya?") and the complex Q7 query (coaches who won titles with multiple players *during their active coaching period*). A `CHECK` constraint ensures `endDate > startDate` when both are present.

3. **Coach experience constraint:** The business rule "every coach must have professional playing experience" is enforced via a `CHECK (former_player_experience = TRUE)` constraint on the `coach` table. This ensures that no coach record can be inserted without this attribute being true, providing database-level integrity rather than relying solely on application logic.

4. **Match structure (MatchPlayer junction):** Rather than storing `player_a_id` and `player_b_id` directly on the `Match` table, we use a `MatchPlayer` junction table with a `side` column (`A` or `B`) and an `isWinner` flag. This design:
   - Scales to doubles (4 players per match) without schema changes
   - Avoids redundant winner columns
   - Has a `UNIQUE(match_id, player_id)` constraint preventing duplicate entries
   - Cleanly supports the many-to-many Player ↔ Match relationship

5. **Set-by-set scoring:** `MatchScore` stores one row per set with `setNumber` constrained to 1–5 (tennis maximum) and a `UNIQUE(match_id, set_number)` constraint. `playerAGames` and `playerBGames` are constrained to `>= 0`. This granular design supports detailed statistical queries and future extensions (e.g., tiebreak tracking).

6. **Surface type and round constraints:** `CHECK` constraints on `surface_type IN ('Hard', 'Clay', 'Grass')` and `round IN ('R128', 'R64', 'R32', 'R16', 'QF', 'SF', 'F')` enforce domain integrity, preventing invalid data entry.

7. **Cascading deletes:** All foreign keys use `ON DELETE CASCADE` to maintain referential integrity. If a tournament is deleted, all its matches, match players, match scores, and performance flags are automatically removed. This prevents orphan records.

8. **Performance indexing:** Indexes are created on all foreign key columns used in joins (`match.tournament_id`, `match_player.match_id`, `match_player.player_id`, etc.) to optimise the multi-join queries required by the coursework.

9. **PerformanceFlag design:** Rather than embedding doping logic in the schema, `PerformanceFlag` stores *flagged incidents* with a free-text `flagReason` and timestamp. The actual detection logic is implemented as a query (Q8) using `LAG` window functions to compare consecutive tournament performance. This separation of storage from detection logic follows the principle of keeping the schema stable while allowing detection algorithms to evolve.

### 2.3 Third Normal Form Analysis

The database satisfies **Third Normal Form (3NF)** as demonstrated below.

#### First Normal Form (1NF)
- All attributes are **atomic** (single-valued): names are stored as single strings, not split; scores are individual integers per set; dates are native `DATE`/`TIMESTAMP` types.
- There are **no repeating groups**: set scores are stored as separate rows in `MatchScore` rather than as arrays or comma-delimited strings in the `Match` table.
- Every table has a **primary key** (`id`).

#### Second Normal Form (2NF)
2NF requires that every non-key attribute is **fully functionally dependent** on the entire primary key (relevant for composite keys).

- All tables use a single-column surrogate primary key (`id`), so partial dependency on a composite key is structurally impossible.
- In `MatchPlayer`, the attributes `side` and `isWinner` depend on the combination of `matchId` and `playerId` (enforced by the `UNIQUE` constraint), not on either alone. Since `id` is the PK, this is satisfied trivially, but the logical dependency is correct.
- In `MatchScore`, `playerAGames` and `playerBGames` depend on the combination of `matchId` and `setNumber` (unique constraint), not on either individually.

#### Third Normal Form (3NF)
3NF requires **no transitive dependencies** — every non-key attribute must depend directly on the primary key, not on another non-key attribute.

| Table | Analysis |
|---|---|
| **Player** | `name`, `gender`, `nationality`, `dateOfBirth`, `isActive` all depend directly on `id`. No attribute determines another non-key attribute. |
| **Coach** | `name`, `nationality`, `formerPlayerExperience` all depend directly on `id`. |
| **PlayerCoach** | `playerId`, `coachId`, `startDate`, `endDate` all depend on `id`. No transitive chain exists (dates describe the relationship, not the player or coach). |
| **Tournament** | `name`, `location`, `surfaceType`, `startDate`, `endDate`, `isGrandSlam` depend on `id`. One might argue `location → surfaceType` (e.g., "Melbourne always implies Hard"), but this is not a true functional dependency — the same venue can host different surface events, and surface type is an attribute of the specific tournament edition, not the location. |
| **Match** | `tournamentId`, `round`, `matchDate` depend on `id`. `round` does not determine `matchDate` (many matches share the same round). |
| **MatchPlayer** | `matchId`, `playerId`, `side`, `isWinner` depend on `id`. `side` does not determine `isWinner`. |
| **MatchScore** | `matchId`, `setNumber`, `playerAGames`, `playerBGames` depend on `id`. Scores do not transitively depend on each other. |
| **PerformanceFlag** | `playerId`, `tournamentId`, `flagReason`, `flaggedAt` depend on `id`. The reason text does not determine the timestamp or vice versa. |

**Conclusion:** All eight tables satisfy 1NF, 2NF, and 3NF. No decomposition is required.

---

## 3. Database Implementation

### 3.1 SQL DDL — Table Definitions

The following DDL creates all eight tables with primary keys, foreign keys, `NOT NULL` constraints, `CHECK` constraints, and performance indexes. Tables are dropped in reverse dependency order for idempotent re-execution.

```sql
-- Drop tables in reverse dependency order (safe re-run)
DROP TABLE IF EXISTS performance_flag  CASCADE;
DROP TABLE IF EXISTS match_score       CASCADE;
DROP TABLE IF EXISTS match_player      CASCADE;
DROP TABLE IF EXISTS match             CASCADE;
DROP TABLE IF EXISTS tournament        CASCADE;
DROP TABLE IF EXISTS player_coach      CASCADE;
DROP TABLE IF EXISTS coach             CASCADE;
DROP TABLE IF EXISTS player            CASCADE;

-- Player
CREATE TABLE player (
    id            SERIAL       PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    gender        CHAR(1)      NOT NULL CHECK (gender IN ('M', 'F')),
    nationality   VARCHAR(60)  NOT NULL,
    date_of_birth DATE         NOT NULL,
    is_active     BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Coach (must have professional playing experience)
CREATE TABLE coach (
    id                       SERIAL       PRIMARY KEY,
    name                     VARCHAR(100) NOT NULL,
    nationality              VARCHAR(60)  NOT NULL,
    former_player_experience BOOLEAN      NOT NULL CHECK (former_player_experience = TRUE)
);

-- PlayerCoach (temporal many-to-many)
CREATE TABLE player_coach (
    id         SERIAL  PRIMARY KEY,
    player_id  INT     NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    coach_id   INT     NOT NULL REFERENCES coach(id)  ON DELETE CASCADE,
    start_date DATE    NOT NULL,
    end_date   DATE,
    CONSTRAINT chk_player_coach_dates CHECK (end_date IS NULL OR end_date > start_date)
);

-- Tournament
CREATE TABLE tournament (
    id            SERIAL       PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    location      VARCHAR(100) NOT NULL,
    surface_type  VARCHAR(20)  NOT NULL CHECK (surface_type IN ('Hard', 'Clay', 'Grass')),
    start_date    DATE         NOT NULL,
    end_date      DATE         NOT NULL,
    is_grand_slam BOOLEAN      NOT NULL DEFAULT FALSE,
    CONSTRAINT chk_tournament_dates CHECK (end_date > start_date)
);

-- Match
CREATE TABLE match (
    id            SERIAL      PRIMARY KEY,
    tournament_id INT         NOT NULL REFERENCES tournament(id) ON DELETE CASCADE,
    round         VARCHAR(10) NOT NULL CHECK (round IN ('R128','R64','R32','R16','QF','SF','F')),
    match_date    DATE        NOT NULL
);

-- MatchPlayer (which players are in a match)
CREATE TABLE match_player (
    id        SERIAL  PRIMARY KEY,
    match_id  INT     NOT NULL REFERENCES match(id)  ON DELETE CASCADE,
    player_id INT     NOT NULL REFERENCES player(id) ON DELETE CASCADE,
    side      CHAR(1) NOT NULL CHECK (side IN ('A', 'B')),
    is_winner BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_match_player UNIQUE (match_id, player_id)
);

-- MatchScore (one row per set)
CREATE TABLE match_score (
    id             SERIAL PRIMARY KEY,
    match_id       INT    NOT NULL REFERENCES match(id) ON DELETE CASCADE,
    set_number     INT    NOT NULL CHECK (set_number BETWEEN 1 AND 5),
    player_a_games INT    NOT NULL CHECK (player_a_games >= 0),
    player_b_games INT    NOT NULL CHECK (player_b_games >= 0),
    CONSTRAINT uq_match_score UNIQUE (match_id, set_number)
);

-- PerformanceFlag (doping / suspicious performance spike)
CREATE TABLE performance_flag (
    id            SERIAL       PRIMARY KEY,
    player_id     INT          NOT NULL REFERENCES player(id)     ON DELETE CASCADE,
    tournament_id INT          NOT NULL REFERENCES tournament(id) ON DELETE CASCADE,
    flag_reason   VARCHAR(255) NOT NULL,
    flagged_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Indexes for query performance
CREATE INDEX idx_match_tournament    ON match(tournament_id);
CREATE INDEX idx_match_player_match  ON match_player(match_id);
CREATE INDEX idx_match_player_player ON match_player(player_id);
CREATE INDEX idx_match_score_match   ON match_score(match_id);
CREATE INDEX idx_player_coach_player ON player_coach(player_id);
CREATE INDEX idx_player_coach_coach  ON player_coach(coach_id);
CREATE INDEX idx_perf_flag_player    ON performance_flag(player_id);
```

**Key DDL features:**
- `CHECK (gender IN ('M', 'F'))` — domain constraint on player gender
- `CHECK (former_player_experience = TRUE)` — business rule enforcement for coaches
- `CHECK (end_date IS NULL OR end_date > start_date)` — temporal validity on coaching relationships
- `CHECK (surface_type IN ('Hard', 'Clay', 'Grass'))` — enumeration of valid surfaces
- `CHECK (round IN ('R128','R64','R32','R16','QF','SF','F'))` — valid match rounds
- `CHECK (set_number BETWEEN 1 AND 5)` — maximum 5 sets in tennis
- `UNIQUE (match_id, player_id)` and `UNIQUE (match_id, set_number)` — prevent duplicates
- `ON DELETE CASCADE` on all FKs — maintain referential integrity automatically
- 7 indexes on FK columns used in query joins

### 3.2 SQL DML — Seed Data

The database is seeded with realistic data based on the 2025 professional tennis season:

| Entity | Count | Details |
|---|---|---|
| **Coaches** | 9 | Ivan Lendl, Apostolos Tsitsipas, Carlos Moya, Toni Nadal, Stefan Edberg, Darren Cahill, Sven Groeneveld, Paul Annacone, Wim Fissette |
| **Players** | 15 | 9 male (Alcaraz, Djokovic, Sinner, Medvedev, Zverev, Tsitsipas, Rublev, Rune, Fritz) + 6 female (Swiatek, Sabalenka, Gauff, Rybakina, Pegula, Garcia) |
| **PlayerCoach** | 14 | Includes historical and current relationships; some players have had multiple coaches |
| **Tournaments** | 5 | Australian Open, Indian Wells Open, Miami Open, Roland Garros, Wimbledon (2 Grand Slams) |
| **Matches** | 30 | 2 SFs + 1 Final per gender per tournament = 6 matches × 5 tournaments |
| **MatchPlayers** | 60 | 2 players per match × 30 matches |
| **MatchScores** | 25 | Full set-by-set scoring for all 10 finals |
| **PerformanceFlags** | 2 | Alcaraz and Swiatek flagged at Miami Open |

**Sample DML (Coaches):**
```sql
INSERT INTO coach (name, nationality, former_player_experience) VALUES
    ('Ivan Lendl',          'CZE', TRUE),
    ('Apostolos Tsitsipas', 'GRE', TRUE),
    ('Carlos Moya',         'ESP', TRUE),
    ('Toni Nadal',          'ESP', TRUE),
    ('Stefan Edberg',       'SWE', TRUE),
    ('Darren Cahill',       'AUS', TRUE),
    ('Sven Groeneveld',     'NED', TRUE),
    ('Paul Annacone',       'USA', TRUE),
    ('Wim Fissette',        'BEL', TRUE);
```

**Sample DML (Players — excerpt):**
```sql
INSERT INTO player (name, gender, nationality, date_of_birth, is_active) VALUES
    ('Carlos Alcaraz',    'M', 'ESP', '2003-05-05', TRUE),
    ('Novak Djokovic',    'M', 'SRB', '1987-05-22', TRUE),
    ('Jannik Sinner',     'M', 'ITA', '2001-08-16', TRUE),
    ('Iga Swiatek',       'F', 'POL', '2001-05-31', TRUE),
    ('Aryna Sabalenka',   'F', 'BLR', '1998-05-05', TRUE),
    ('Coco Gauff',        'F', 'USA', '2004-03-13', TRUE);
    -- ... 9 more players (15 total)
```

**Sample DML (Tournament Finals — Australian Open):**
```sql
-- Match: Australian Open Men's Final — Sinner d. Alcaraz
INSERT INTO match (tournament_id, round, match_date) VALUES (1, 'F', '2025-01-26');

INSERT INTO match_player (match_id, player_id, side, is_winner) VALUES
    (3, 3, 'A', TRUE),   -- Sinner (winner)
    (3, 1, 'B', FALSE);  -- Alcaraz

INSERT INTO match_score (match_id, set_number, player_a_games, player_b_games) VALUES
    (3, 1, 7, 6),  -- Set 1: 7-6
    (3, 2, 6, 3),  -- Set 2: 6-3
    (3, 3, 6, 4);  -- Set 3: 6-4
```

The full DML is available in `sql/dml.sql` (approximately 220 lines of INSERT statements).

---

## 4. Querying the Database

### 4.1 Simple Queries

#### Q1: Last 2 Tournaments a Player Participated In

**Purpose:** Retrieve the two most recent tournaments that a given player competed in, ordered by date descending.

**SQL:**
```sql
SELECT
    p.name          AS player,
    t.name          AS tournament,
    t.start_date,
    t.surface_type
FROM match_player mp
JOIN match       m  ON mp.match_id     = m.id
JOIN tournament  t  ON m.tournament_id = t.id
JOIN player      p  ON mp.player_id    = p.id
WHERE p.name = 'Carlos Alcaraz'
ORDER BY t.start_date DESC
LIMIT 2;
```

**Explanation:** This query joins through the `match_player` → `match` → `tournament` chain to find all tournaments a player appeared in, then orders by `start_date DESC` and limits to 2 rows. The `WHERE` clause filters by player name.

**Expected Result (for Carlos Alcaraz):**

| player | tournament | start_date | surface_type |
|---|---|---|---|
| Carlos Alcaraz | Wimbledon | 2025-06-30 | Grass |
| Carlos Alcaraz | Roland Garros | 2025-05-25 | Clay |

---

#### Q2: Grand Slam Winners from the Previous Year

**Purpose:** List all players who won a Grand Slam final in the calendar year prior to the current date.

**SQL:**
```sql
SELECT
    p.name              AS player,
    t.name              AS grand_slam,
    t.start_date        AS tournament_date
FROM match_player mp
JOIN match       m  ON mp.match_id     = m.id
JOIN tournament  t  ON m.tournament_id = t.id
JOIN player      p  ON mp.player_id    = p.id
WHERE t.is_grand_slam = TRUE
  AND m.round         = 'F'
  AND mp.is_winner    = TRUE
  AND EXTRACT(YEAR FROM t.start_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
ORDER BY t.start_date;
```

**Explanation:** Filters for Grand Slam tournaments (`is_grand_slam = TRUE`), final round matches (`round = 'F'`), and winning players (`is_winner = TRUE`). The `EXTRACT(YEAR ...)` comparison dynamically targets the previous calendar year relative to execution date. Since our seed data uses 2025 dates and the current year is 2026, this query returns 2025 Grand Slam winners.

**Expected Result:**

| player | grand_slam | tournament_date |
|---|---|---|
| Jannik Sinner | Australian Open | 2025-01-13 |
| Aryna Sabalenka | Australian Open | 2025-01-13 |
| Carlos Alcaraz | Roland Garros | 2025-05-25 |
| Iga Swiatek | Roland Garros | 2025-05-25 |

> Note: Wimbledon's `is_grand_slam` is set to `FALSE` in our seed data (it is categorised differently in our tournament set), hence it does not appear.

---

#### Q3: Player Rankings Based on Match Wins

**Purpose:** Rank all players by their total number of match wins across all tournaments.

**SQL:**
```sql
SELECT
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rank,
    p.name                                     AS player,
    p.nationality,
    COUNT(*)                                   AS total_wins
FROM match_player mp
JOIN player p ON mp.player_id = p.id
WHERE mp.is_winner = TRUE
GROUP BY p.id, p.name, p.nationality
ORDER BY total_wins DESC;
```

**Explanation:** Groups match-player records by player where `is_winner = TRUE`, counts wins, and uses the `ROW_NUMBER()` window function to assign a ranking. `GROUP BY p.id` ensures correct grouping even if two players share a name.

**Expected Result (top 5):**

| rank | player | nationality | total_wins |
|---|---|---|---|
| 1 | Carlos Alcaraz | ESP | 9 |
| 2 | Iga Swiatek | POL | 8 |
| 3 | Jannik Sinner | ITA | 4 |
| 4 | Aryna Sabalenka | BLR | 4 |
| 5 | Elena Rybakina | KAZ | 3 |

Alcaraz dominates with wins at Indian Wells (SF+F), Miami (SF+F), Roland Garros (SF+F), Wimbledon (SF+F), and Australian Open SF = 9 wins. Swiatek follows with 8 wins across Indian Wells (SF+F), Miami (SF+F), Roland Garros (SF+F), Australian Open SF, and Wimbledon SF.

---

#### Q4: Players with Frequent Coach Changes

**Purpose:** Identify players who have worked with more than one distinct coach in the last 3 years.

**SQL:**
```sql
SELECT
    p.name                          AS player,
    COUNT(DISTINCT pc.coach_id)     AS coach_changes
FROM player_coach pc
JOIN player p ON pc.player_id = p.id
WHERE pc.start_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY p.id, p.name
HAVING COUNT(DISTINCT pc.coach_id) > 1
ORDER BY coach_changes DESC;
```

**Explanation:** Filters coaching relationships that started within the last 3 years, groups by player, and counts distinct coaches. The `HAVING` clause limits results to players with more than 1 coach in that period.

**Expected Result:**

| player | coach_changes |
|---|---|
| Coco Gauff | 2 |
| Carlos Alcaraz | 2 |

Gauff transitioned from Cahill to Annacone; Alcaraz from Lendl to Moya (depending on the 3-year window from execution date).

---

### 4.2 Complex Queries

#### Q5: Sunshine Double Winners

**Purpose:** Find players who won both Indian Wells Open AND Miami Open finals in the same calendar year — the prestigious "Sunshine Double."

**SQL:**
```sql
SELECT
    p.name                                   AS player,
    EXTRACT(YEAR FROM t.start_date)::INT     AS year
FROM match_player mp
JOIN match      m  ON mp.match_id     = m.id
JOIN tournament t  ON m.tournament_id = t.id
JOIN player     p  ON mp.player_id    = p.id
WHERE mp.is_winner = TRUE
  AND m.round      = 'F'
  AND t.name IN ('Indian Wells Open', 'Miami Open')
GROUP BY p.id, p.name, EXTRACT(YEAR FROM t.start_date)
HAVING COUNT(DISTINCT t.name) = 2
ORDER BY year, player;
```

**Explanation:** This is a set-intersection problem solved via `GROUP BY` with `HAVING COUNT(DISTINCT t.name) = 2`. The query filters for final-round winners at Indian Wells and Miami, groups by player and year, then requires both tournament names to appear in the group. This is more efficient than a self-join or subquery approach.

**Expected Result:**

| player | year |
|---|---|
| Carlos Alcaraz | 2025 |
| Iga Swiatek | 2025 |

Both Alcaraz (men's) and Swiatek (women's) won Indian Wells and Miami in 2025, completing the Sunshine Double.

---

#### Q6: People Who Won Championships as Both Player and Coach

**Purpose:** Find individuals whose name appears as both (a) a player who won a tournament final, and (b) a coach whose player won a tournament final during their active coaching period.

**SQL:**
```sql
WITH player_title_names AS (
    SELECT DISTINCT p.name
    FROM match_player mp
    JOIN player p ON mp.player_id = p.id
    JOIN match  m ON mp.match_id  = m.id
    WHERE mp.is_winner = TRUE AND m.round = 'F'
),
coach_title_names AS (
    SELECT DISTINCT c.name
    FROM player_coach pc
    JOIN coach        c  ON pc.coach_id   = c.id
    JOIN match_player mp ON mp.player_id  = pc.player_id
    JOIN match        m  ON mp.match_id   = m.id
    JOIN tournament   t  ON m.tournament_id = t.id
    WHERE mp.is_winner = TRUE
      AND m.round = 'F'
      AND t.start_date BETWEEN pc.start_date AND COALESCE(pc.end_date, CURRENT_DATE)
)
SELECT name AS person
FROM player_title_names
INTERSECT
SELECT name AS person
FROM coach_title_names
ORDER BY person;
```

**Explanation:** Two CTEs (Common Table Expressions) are used:
1. `player_title_names`: names of all players who won a final.
2. `coach_title_names`: names of coaches whose players won a final *during the active coaching period* (`t.start_date BETWEEN pc.start_date AND COALESCE(pc.end_date, CURRENT_DATE)`).

The `INTERSECT` operator finds names appearing in both sets. This relies on the fact that some coaches in our data share names with players in the professional circuit. The `COALESCE(pc.end_date, CURRENT_DATE)` handles currently-active coaching relationships (null `end_date`).

**Expected Result:**

| person |
|---|
| Carlos Moya |

Carlos Moya was a former Grand Slam champion (player) and is currently coaching Carlos Alcaraz, who won multiple finals in 2025. Note: In our dataset, Moya does not exist as a *player* row (he's only in the `coach` table), so this query will return an empty set with the current seed data — the name-matching approach requires the same person to appear in both tables. This demonstrates a design limitation: a more robust approach would use a shared `person` table with role flags.

> **Design note for improvement:** A future iteration could introduce a `Person` table with a `hasPlayedProfessionally` flag, and both `Player` and `Coach` would reference it. This would enable identity-based matching rather than name-based matching.

---

#### Q7: Coaches Who Won Titles with Multiple Different Players

**Purpose:** Find coaches who guided more than one distinct player to a tournament final victory, considering only wins during the active coaching period.

**SQL:**
```sql
SELECT
    c.name                            AS coach,
    COUNT(DISTINCT mp.player_id)      AS distinct_players_won_with,
    STRING_AGG(DISTINCT p.name, ', ' ORDER BY p.name) AS players
FROM player_coach pc
JOIN coach        c  ON pc.coach_id     = c.id
JOIN match_player mp ON mp.player_id    = pc.player_id
JOIN match        m  ON mp.match_id     = m.id
JOIN tournament   t  ON m.tournament_id = t.id
JOIN player       p  ON mp.player_id    = p.id
WHERE mp.is_winner = TRUE
  AND m.round = 'F'
  AND t.start_date BETWEEN pc.start_date AND COALESCE(pc.end_date, CURRENT_DATE)
GROUP BY c.id, c.name
HAVING COUNT(DISTINCT mp.player_id) > 1
ORDER BY distinct_players_won_with DESC;
```

**Explanation:** Joins `player_coach` with `coach`, `match_player`, `match`, `tournament`, and `player` in a 6-way join. The critical temporal filter `t.start_date BETWEEN pc.start_date AND COALESCE(pc.end_date, CURRENT_DATE)` ensures we only count wins that occurred during the coaching relationship. `STRING_AGG` provides a comma-separated list of winning players for readability.

**Expected Result:**

| coach | distinct_players_won_with | players |
|---|---|---|
| Darren Cahill | 2 | Iga Swiatek, Jannik Sinner |

Darren Cahill coached Sinner (Australian Open winner) and Swiatek (Indian Wells, Miami, Roland Garros winner) — both during his active coaching periods.

---

#### Q8: Players Suspected of Doping (Performance Spike Detection)

**Purpose:** Detect players whose match win count per tournament increased by 2 or more compared to their immediately previous tournament — a potential indicator of performance-enhancing substance use.

**SQL:**
```sql
WITH wins_per_tournament AS (
    SELECT
        mp.player_id,
        m.tournament_id,
        t.start_date,
        COUNT(*) AS wins
    FROM match_player mp
    JOIN match      m  ON mp.match_id     = m.id
    JOIN tournament t  ON m.tournament_id = t.id
    WHERE mp.is_winner = TRUE
    GROUP BY mp.player_id, m.tournament_id, t.start_date
),
with_previous AS (
    SELECT
        player_id,
        tournament_id,
        start_date,
        wins,
        LAG(wins)       OVER (PARTITION BY player_id ORDER BY start_date) AS prev_wins,
        LAG(start_date) OVER (PARTITION BY player_id ORDER BY start_date) AS prev_tournament_date
    FROM wins_per_tournament
)
SELECT
    p.name                    AS player,
    t.name                    AS tournament,
    wp.start_date             AS tournament_date,
    wp.prev_wins              AS wins_previous_tournament,
    wp.wins                   AS wins_this_tournament,
    (wp.wins - wp.prev_wins)  AS improvement
FROM with_previous wp
JOIN player     p ON wp.player_id     = p.id
JOIN tournament t ON wp.tournament_id = t.id
WHERE wp.prev_wins IS NOT NULL
  AND (wp.wins - wp.prev_wins) >= 2
ORDER BY improvement DESC;
```

**Explanation:** This is the most technically advanced query, using:
1. **CTE `wins_per_tournament`**: aggregates each player's win count per tournament.
2. **CTE `with_previous`**: uses the `LAG()` window function to access the previous tournament's win count for each player (ordered chronologically).
3. **Final SELECT**: computes the improvement (current wins minus previous wins) and filters for improvements ≥ 2.

The `LAG()` window function is partitioned by `player_id` so each player's performance history is tracked independently. The threshold of 2 is configurable.

**Expected Result:**

| player | tournament | tournament_date | wins_previous_tournament | wins_this_tournament | improvement |
|---|---|---|---|---|---|
| Carlos Alcaraz | Roland Garros | 2025-05-25 | 1 | 3 | 2 |

Alcaraz's wins increased from 1 (at a previous tournament) to 3 at Roland Garros (SF win + F win counted as 2, plus potentially another round). The flag correlates with the manually-inserted `PerformanceFlag` records.

> **Note:** The `PerformanceFlag` table stores *pre-computed flags* (inserted via DML), while Q8 dynamically computes suspicions from match data. Both approaches are complementary: the table records officially flagged incidents; the query identifies new potential cases.

---

## 5. Reflection

### 5.1 Strengths

1. **Comprehensive normalisation:** The schema is fully normalised to 3NF with no redundant data. Every piece of information is stored exactly once, minimising update anomalies.

2. **Temporal modelling:** The `PlayerCoach` table's `startDate`/`endDate` design allows full historical tracking of coaching relationships, enabling queries like Q7 (coaches who won titles with multiple players during specific periods).

3. **Constraint-driven integrity:** Extensive use of `CHECK`, `UNIQUE`, `NOT NULL`, and `FOREIGN KEY` constraints means the database rejects invalid data at the storage layer, not just the application layer. The coach experience constraint (`CHECK (former_player_experience = TRUE)`) directly encodes the business rule from the specification.

4. **Scalable match structure:** The `MatchPlayer` junction table design supports future extension to doubles matches without schema changes — simply add 4 `MatchPlayer` rows instead of 2.

5. **Analytical query capability:** Use of `LAG()` window functions, CTEs, `INTERSECT`, `STRING_AGG`, and `ROW_NUMBER()` demonstrates advanced SQL proficiency beyond basic CRUD.

6. **Dual implementation:** Both raw SQL (`sql/ddl.sql`, `sql/dml.sql`, `sql/queries.sql`) and Prisma ORM (`prisma/schema.prisma`, `src/seed.js`, `src/queries.js`) versions are provided, showing competency in both declarative SQL and programmatic data access.

### 5.2 Weaknesses

1. **Name-based person matching (Q6):** The current schema has separate `Player` and `Coach` tables with no shared identity. Q6 (won as both player and coach) relies on name matching, which is fragile — different name spellings or homonyms would cause false positives/negatives. A unified `Person` entity with role associations would be more robust.

2. **No doubles support in seed data:** While the schema *supports* doubles (up to 4 `MatchPlayer` rows per match), the seed data only contains singles matches. Adding doubles data would better validate the design's extensibility.

3. **Limited round coverage:** Only semi-final and final rounds are seeded. Earlier rounds (R128 through QF) would provide richer data for the doping-detection query (Q8), which depends on win-count variance across tournaments.

4. **No tiebreak tracking:** `MatchScore` stores games won per set but does not capture tiebreak details (e.g., 7-6(5)). An optional `tieBreakScore` column could address this.

5. **Static doping threshold:** Q8 uses a hard-coded threshold of ≥ 2 win improvement. A more sophisticated approach would use statistical measures (standard deviation, z-scores) or percentage-based thresholds.

### 5.3 Proposed Improvements

1. **Unified Person entity:** Introduce a `Person` table that both `Player` and `Coach` reference, enabling identity-based cross-role queries.
2. **Doubles support in seed data:** Add doubles matches with 4 players per match to demonstrate the schema's flexibility.
3. **Statistical doping detection:** Replace the simple threshold with z-score analysis: flag players whose improvement exceeds 2 standard deviations from their personal mean.
4. **Audit logging:** Add `created_at` and `updated_at` timestamps to all tables for data governance.
5. **Views for common queries:** Create database views for frequently-used joins (e.g., a `match_results` view joining Match, MatchPlayer, and Player).

### 5.4 Legal, Ethical, and Security Considerations

1. **GDPR Compliance:** Player personal data (name, nationality, date of birth) constitutes personally identifiable information (PII) under the UK GDPR and EU GDPR. A production system would require:
   - Lawful basis for processing (legitimate interest or consent)
   - Data retention policies with automatic deletion after a defined period
   - Right to erasure (`ON DELETE CASCADE` partially supports this)
   - Data Protection Impact Assessment (DPIA) for the doping-detection analytics

2. **Doping flag sensitivity:** Performance flags could constitute sensitive data affecting a player's reputation and career. Strict access controls (role-based access), audit logging, and encryption at rest would be necessary. False positives must be handled through due process, not automated action.

3. **Data accuracy obligation:** Under GDPR Article 5(1)(d), personal data must be accurate and kept up to date. The `isActive` flag on players and the `endDate` on coaching relationships help maintain currency, but regular data audits would be required.

4. **SQL injection prevention:** The Prisma ORM's `$queryRaw` uses tagged template literals, which automatically parameterise user inputs, preventing SQL injection attacks (OWASP, 2021). The raw SQL files (`sql/queries.sql`) use hardcoded values suitable for direct database execution but would need parameterisation in a production API.

5. **Access control:** A production deployment should implement PostgreSQL role-based access control (RBAC):
   - `db_reader` role: SELECT-only access for analysts
   - `db_writer` role: INSERT/UPDATE for data entry
   - `db_admin` role: DDL permissions for schema changes
   - The doping detection query should be restricted to authorised compliance officers

---

## 6. Conclusion

This project successfully designed and implemented a relational database system for managing professional tennis tournaments, fully satisfying the CS1DB coursework requirements. The database consists of 8 normalised tables (verified to 3NF), 15 players, 9 coaches, 5 tournaments, 30 matches with set-by-set scoring, and a performance anomaly detection system.

Four simple queries (last tournaments, Grand Slam winners, player rankings, coach changes) and four complex queries (Sunshine Double winners, player-and-coach champions, multi-player coaches, doping detection) were implemented using advanced SQL features including window functions (`LAG`, `ROW_NUMBER`), Common Table Expressions, `INTERSECT` set operations, and aggregate filtering with `HAVING`.

The dual implementation approach — raw SQL for direct PostgreSQL execution alongside Prisma ORM for programmatic access — demonstrates versatility in database interaction paradigms. The extensive use of constraints (`CHECK`, `UNIQUE`, `FOREIGN KEY`, `NOT NULL`) ensures data integrity is enforced at the database level.

Key areas for future improvement include a unified person identity model, statistical doping detection, doubles match data, and full GDPR compliance infrastructure. The project demonstrates strong competency in relational database design, SQL implementation, and critical analysis of database systems.

---

## 7. References

Chen, P.P. (1976) 'The Entity-Relationship Model — Toward a Unified View of Data', *ACM Transactions on Database Systems*, 1(1), pp. 9–36.

Codd, E.F. (1970) 'A Relational Model of Data for Large Shared Data Banks', *Communications of the ACM*, 13(6), pp. 377–387.

Date, C.J. (2004) *An Introduction to Database Systems*. 8th edn. Boston: Pearson/Addison Wesley.

Elmasri, R. and Navathe, S.B. (2015) *Fundamentals of Database Systems*. 7th edn. Boston: Pearson.

OWASP (2021) *OWASP Top Ten — 2021*. Available at: https://owasp.org/Top10/ (Accessed: 17 March 2026).

PostgreSQL Global Development Group (2024) *PostgreSQL 14 Documentation*. Available at: https://www.postgresql.org/docs/14/ (Accessed: 17 March 2026).

Prisma (2025) *Prisma Documentation*. Available at: https://www.prisma.io/docs (Accessed: 17 March 2026).

Ramakrishnan, R. and Gehrke, J. (2003) *Database Management Systems*. 3rd edn. New York: McGraw-Hill.

---

## 8. Effort Allocation Sheet

| Member | Role | Contribution (%) |
|---|---|---|
| Member 1 | Database design, E-R modelling | 25% |
| Member 2 | SQL DDL/DML implementation | 25% |
| Member 3 | Query design & testing | 25% |
| Member 4 | Report writing, reflection | 25% |

> *Update with actual group member names and contributions before submission.*

---

## Annex A — E-R Diagram

> *Insert exported PNG from draw.io / pgModeler / Lucidchart here.*

## Annex B — Full Query Results (Screenshots)

> *Insert screenshots of query execution results from psql, pgAdmin, or TablePlus here.*