-- =====================================================================
-- CS1DB — Tennis Tournament Database — Seed Data (DML)
-- Target: PostgreSQL 14+. Run AFTER sql/ddl.sql.
--
-- Counts:
--   coaches ............ 9
--   players ............ 15  (9 male, 6 female)
--   player_coach ....... 14
--   tournaments ........ 5   (Australian Open, Indian Wells, Miami,
--                             Roland Garros, Wimbledon)
--   matches ............ 32  (SF + F per gender per tournament  = 30,
--                             plus R16 + QF for men's Roland Garros = 2.
--                             The two extra rounds give the doping-detection
--                             query Q8 enough variance to fire — with only
--                             SF+F per tournament every player tops out at
--                             2 wins so a +2 jump is impossible.)
--   match_player ....... 64  (2 per match)
--   match_score ........ 26  (full set-by-set scoring for all 10 finals)
--   performance_flag ... 2
-- =====================================================================

-- Idempotent re-run: clear all data and reset SERIAL sequences so the
-- explicit IDs referenced as foreign keys below stay stable.
TRUNCATE TABLE
    performance_flag,
    match_score,
    match_player,
    match,
    tournament,
    player_coach,
    coach,
    player
RESTART IDENTITY CASCADE;

-- ---------------------------------------------------------------------
-- COACHES (id 1..9)
-- ---------------------------------------------------------------------
INSERT INTO coach (name, nationality, former_player_experience) VALUES
    ('Ivan Lendl',          'CZE', TRUE),  -- 1
    ('Apostolos Tsitsipas', 'GRE', TRUE),  -- 2
    ('Carlos Moya',         'ESP', TRUE),  -- 3
    ('Toni Nadal',          'ESP', TRUE),  -- 4
    ('Stefan Edberg',       'SWE', TRUE),  -- 5
    ('Darren Cahill',       'AUS', TRUE),  -- 6
    ('Sven Groeneveld',     'NED', TRUE),  -- 7
    ('Paul Annacone',       'USA', TRUE),  -- 8
    ('Wim Fissette',        'BEL', TRUE);  -- 9

-- ---------------------------------------------------------------------
-- PLAYERS (id 1..15: 1..9 male, 10..15 female)
-- ---------------------------------------------------------------------
INSERT INTO player (name, gender, nationality, date_of_birth, is_active) VALUES
    ('Carlos Alcaraz',     'M', 'ESP', DATE '2003-05-05', TRUE),  -- 1
    ('Novak Djokovic',     'M', 'SRB', DATE '1987-05-22', TRUE),  -- 2
    ('Jannik Sinner',      'M', 'ITA', DATE '2001-08-16', TRUE),  -- 3
    ('Daniil Medvedev',    'M', 'RUS', DATE '1996-02-11', TRUE),  -- 4
    ('Alexander Zverev',   'M', 'GER', DATE '1997-04-20', TRUE),  -- 5
    ('Stefanos Tsitsipas', 'M', 'GRE', DATE '1998-08-12', TRUE),  -- 6
    ('Andrey Rublev',      'M', 'RUS', DATE '1997-10-20', TRUE),  -- 7
    ('Holger Rune',        'M', 'DEN', DATE '2003-04-29', TRUE),  -- 8
    ('Taylor Fritz',       'M', 'USA', DATE '1997-10-28', TRUE),  -- 9
    ('Iga Swiatek',        'F', 'POL', DATE '2001-05-31', TRUE),  -- 10
    ('Aryna Sabalenka',    'F', 'BLR', DATE '1998-05-05', TRUE),  -- 11
    ('Coco Gauff',         'F', 'USA', DATE '2004-03-13', TRUE),  -- 12
    ('Elena Rybakina',     'F', 'KAZ', DATE '1999-06-17', TRUE),  -- 13
    ('Jessica Pegula',     'F', 'USA', DATE '1994-02-24', TRUE),  -- 14
    ('Caroline Garcia',    'F', 'FRA', DATE '1993-10-16', TRUE);  -- 15

-- ---------------------------------------------------------------------
-- PLAYER_COACH relationships (14 rows)
-- Notes that drive query results:
--   * Alcaraz: Lendl (former) → Moya (current)  →  2 distinct coaches in
--     the last 3 years, satisfying Q4.
--   * Gauff: Groeneveld (former) → Annacone (current)  →  same.
--   * Cahill currently coaches BOTH Sinner AND Swiatek, so Q7 returns
--     Cahill as "won titles with multiple players".
-- ---------------------------------------------------------------------
INSERT INTO player_coach (player_id, coach_id, start_date, end_date) VALUES
    (1,  1, DATE '2023-06-01', DATE '2024-06-30'),  -- Alcaraz   ← Lendl  (ended)
    (1,  3, DATE '2024-07-01', NULL),               -- Alcaraz   ← Moya   (active)
    (2,  5, DATE '2014-01-01', DATE '2016-12-31'),  -- Djokovic  ← Edberg
    (3,  6, DATE '2022-01-01', NULL),               -- Sinner    ← Cahill (active)
    (6,  2, DATE '2015-01-01', NULL),               -- Tsitsipas ← Apostolos Tsitsipas
    (8,  1, DATE '2024-09-01', NULL),               -- Rune      ← Lendl
    (9,  8, DATE '2023-01-01', NULL),               -- Fritz     ← Annacone
    (5,  4, DATE '2024-01-01', NULL),               -- Zverev    ← Toni Nadal
    (10, 6, DATE '2024-10-01', NULL),               -- Swiatek   ← Cahill (active)
    (11, 9, DATE '2023-01-01', NULL),               -- Sabalenka ← Fissette
    (12, 7, DATE '2023-06-01', DATE '2024-09-30'),  -- Gauff     ← Groeneveld (ended)
    (12, 8, DATE '2024-10-01', NULL),               -- Gauff     ← Annacone (active)
    (13, 7, DATE '2024-10-01', NULL),               -- Rybakina  ← Groeneveld
    (14, 8, DATE '2024-01-01', DATE '2024-12-31');  -- Pegula    ← Annacone

-- ---------------------------------------------------------------------
-- TOURNAMENTS (id 1..5)
-- Note: Wimbledon's is_grand_slam is set FALSE deliberately so Q2
-- (previous-year Grand Slam winners) returns only AO + Roland Garros
-- — i.e., a manageable 4-row demonstration. Adjust to TRUE for realism.
-- ---------------------------------------------------------------------
INSERT INTO tournament (name, location, surface_type, start_date, end_date, is_grand_slam) VALUES
    ('Australian Open',   'Melbourne, Australia',  'Hard',  DATE '2025-01-13', DATE '2025-01-26', TRUE),   -- 1
    ('Indian Wells Open', 'Indian Wells, USA',     'Hard',  DATE '2025-03-05', DATE '2025-03-16', FALSE),  -- 2
    ('Miami Open',        'Miami, USA',            'Hard',  DATE '2025-03-19', DATE '2025-03-30', FALSE),  -- 3
    ('Roland Garros',     'Paris, France',         'Clay',  DATE '2025-05-25', DATE '2025-06-08', TRUE),   -- 4
    ('Wimbledon',         'London, United Kingdom','Grass', DATE '2025-06-30', DATE '2025-07-13', FALSE);  -- 5

-- ---------------------------------------------------------------------
-- MATCHES (32 rows: ids 1..32)
-- Layout per tournament:  SF1, SF2, F  for men, then  SF1, SF2, F  for women.
-- Roland Garros men's draw is extended with R16 + QF for Alcaraz so Q8 fires.
-- ---------------------------------------------------------------------
INSERT INTO match (tournament_id, round, match_date) VALUES
    -- Australian Open (men): SF1, SF2, F
    (1, 'SF', DATE '2025-01-23'),  -- 1  Sinner    d. Zverev
    (1, 'SF', DATE '2025-01-24'),  -- 2  Alcaraz   d. Djokovic
    (1, 'F',  DATE '2025-01-26'),  -- 3  Sinner    d. Alcaraz
    -- Australian Open (women)
    (1, 'SF', DATE '2025-01-23'),  -- 4  Sabalenka d. Pegula
    (1, 'SF', DATE '2025-01-24'),  -- 5  Gauff     d. Rybakina
    (1, 'F',  DATE '2025-01-25'),  -- 6  Sabalenka d. Gauff
    -- Indian Wells (men)
    (2, 'SF', DATE '2025-03-14'),  -- 7  Alcaraz   d. Sinner
    (2, 'SF', DATE '2025-03-14'),  -- 8  Medvedev  d. Tsitsipas
    (2, 'F',  DATE '2025-03-16'),  -- 9  Alcaraz   d. Medvedev
    -- Indian Wells (women)
    (2, 'SF', DATE '2025-03-13'),  -- 10 Swiatek   d. Rybakina
    (2, 'SF', DATE '2025-03-14'),  -- 11 Sabalenka d. Garcia
    (2, 'F',  DATE '2025-03-15'),  -- 12 Swiatek   d. Sabalenka
    -- Miami (men)
    (3, 'SF', DATE '2025-03-28'),  -- 13 Alcaraz   d. Rublev
    (3, 'SF', DATE '2025-03-28'),  -- 14 Sinner    d. Rune
    (3, 'F',  DATE '2025-03-30'),  -- 15 Alcaraz   d. Sinner
    -- Miami (women)
    (3, 'SF', DATE '2025-03-27'),  -- 16 Swiatek   d. Pegula
    (3, 'SF', DATE '2025-03-27'),  -- 17 Gauff     d. Rybakina
    (3, 'F',  DATE '2025-03-29'),  -- 18 Swiatek   d. Gauff
    -- Roland Garros (men, extended): R16, QF, SF1, SF2, F
    (4, 'R16',DATE '2025-06-02'),  -- 19 Alcaraz   d. Rune
    (4, 'QF', DATE '2025-06-04'),  -- 20 Alcaraz   d. Rublev
    (4, 'SF', DATE '2025-06-06'),  -- 21 Alcaraz   d. Sinner
    (4, 'SF', DATE '2025-06-06'),  -- 22 Zverev    d. Tsitsipas
    (4, 'F',  DATE '2025-06-08'),  -- 23 Alcaraz   d. Zverev
    -- Roland Garros (women)
    (4, 'SF', DATE '2025-06-05'),  -- 24 Swiatek   d. Rybakina
    (4, 'SF', DATE '2025-06-05'),  -- 25 Gauff     d. Sabalenka
    (4, 'F',  DATE '2025-06-07'),  -- 26 Swiatek   d. Gauff
    -- Wimbledon (men)
    (5, 'SF', DATE '2025-07-11'),  -- 27 Alcaraz   d. Sinner
    (5, 'SF', DATE '2025-07-11'),  -- 28 Djokovic  d. Fritz
    (5, 'F',  DATE '2025-07-13'),  -- 29 Alcaraz   d. Djokovic
    -- Wimbledon (women)
    (5, 'SF', DATE '2025-07-10'),  -- 30 Sabalenka d. Rybakina
    (5, 'SF', DATE '2025-07-10'),  -- 31 Swiatek   d. Pegula
    (5, 'F',  DATE '2025-07-12');  -- 32 Sabalenka d. Swiatek

-- ---------------------------------------------------------------------
-- MATCH_PLAYER: 2 rows per match.  side='A' is the winner in this seed.
-- ---------------------------------------------------------------------
INSERT INTO match_player (match_id, player_id, side, is_winner) VALUES
    -- Australian Open (men)
    (1,  3, 'A', TRUE),  (1,  5, 'B', FALSE),
    (2,  1, 'A', TRUE),  (2,  2, 'B', FALSE),
    (3,  3, 'A', TRUE),  (3,  1, 'B', FALSE),
    -- Australian Open (women)
    (4, 11, 'A', TRUE),  (4, 14, 'B', FALSE),
    (5, 12, 'A', TRUE),  (5, 13, 'B', FALSE),
    (6, 11, 'A', TRUE),  (6, 12, 'B', FALSE),
    -- Indian Wells (men)
    (7,  1, 'A', TRUE),  (7,  3, 'B', FALSE),
    (8,  4, 'A', TRUE),  (8,  6, 'B', FALSE),
    (9,  1, 'A', TRUE),  (9,  4, 'B', FALSE),
    -- Indian Wells (women)
    (10, 10, 'A', TRUE), (10, 13, 'B', FALSE),
    (11, 11, 'A', TRUE), (11, 15, 'B', FALSE),
    (12, 10, 'A', TRUE), (12, 11, 'B', FALSE),
    -- Miami (men)
    (13, 1,  'A', TRUE), (13, 7,  'B', FALSE),
    (14, 3,  'A', TRUE), (14, 8,  'B', FALSE),
    (15, 1,  'A', TRUE), (15, 3,  'B', FALSE),
    -- Miami (women)
    (16, 10, 'A', TRUE), (16, 14, 'B', FALSE),
    (17, 12, 'A', TRUE), (17, 13, 'B', FALSE),
    (18, 10, 'A', TRUE), (18, 12, 'B', FALSE),
    -- Roland Garros (men)
    (19, 1,  'A', TRUE), (19, 8,  'B', FALSE),
    (20, 1,  'A', TRUE), (20, 7,  'B', FALSE),
    (21, 1,  'A', TRUE), (21, 3,  'B', FALSE),
    (22, 5,  'A', TRUE), (22, 6,  'B', FALSE),
    (23, 1,  'A', TRUE), (23, 5,  'B', FALSE),
    -- Roland Garros (women)
    (24, 10, 'A', TRUE), (24, 13, 'B', FALSE),
    (25, 12, 'A', TRUE), (25, 11, 'B', FALSE),
    (26, 10, 'A', TRUE), (26, 12, 'B', FALSE),
    -- Wimbledon (men)
    (27, 1,  'A', TRUE), (27, 3,  'B', FALSE),
    (28, 2,  'A', TRUE), (28, 9,  'B', FALSE),
    (29, 1,  'A', TRUE), (29, 2,  'B', FALSE),
    -- Wimbledon (women)
    (30, 11, 'A', TRUE), (30, 13, 'B', FALSE),
    (31, 10, 'A', TRUE), (31, 14, 'B', FALSE),
    (32, 11, 'A', TRUE), (32, 10, 'B', FALSE);

-- ---------------------------------------------------------------------
-- MATCH_SCORE: full set-by-set scoring for all 10 finals (26 rows).
-- player_a_games / player_b_games correspond to side A / side B above.
-- ---------------------------------------------------------------------
INSERT INTO match_score (match_id, set_number, player_a_games, player_b_games) VALUES
    -- Match 3:  AO M Final  — Sinner d. Alcaraz 7-6 6-3 6-4
    (3,  1, 7, 6), (3,  2, 6, 3), (3,  3, 6, 4),
    -- Match 6:  AO F Final  — Sabalenka d. Gauff 6-3 6-2
    (6,  1, 6, 3), (6,  2, 6, 2),
    -- Match 9:  IW M Final  — Alcaraz d. Medvedev 7-6 6-3 6-4
    (9,  1, 7, 6), (9,  2, 6, 3), (9,  3, 6, 4),
    -- Match 12: IW F Final  — Swiatek d. Sabalenka 6-4 6-2
    (12, 1, 6, 4), (12, 2, 6, 2),
    -- Match 15: Miami M Final — Alcaraz d. Sinner 6-4 6-3
    (15, 1, 6, 4), (15, 2, 6, 3),
    -- Match 18: Miami F Final — Swiatek d. Gauff 7-5 6-4
    (18, 1, 7, 5), (18, 2, 6, 4),
    -- Match 23: RG M Final — Alcaraz d. Zverev 6-3 2-6 5-7 6-1 7-6 (5-set classic)
    (23, 1, 6, 3), (23, 2, 2, 6), (23, 3, 5, 7), (23, 4, 6, 1), (23, 5, 7, 6),
    -- Match 26: RG F Final — Swiatek d. Gauff 6-4 6-3
    (26, 1, 6, 4), (26, 2, 6, 3),
    -- Match 29: W  M Final — Alcaraz d. Djokovic 6-2 6-2 7-6
    (29, 1, 6, 2), (29, 2, 6, 2), (29, 3, 7, 6),
    -- Match 32: W  F Final — Sabalenka d. Swiatek 6-3 6-4
    (32, 1, 6, 3), (32, 2, 6, 4);

-- ---------------------------------------------------------------------
-- PERFORMANCE_FLAG (2 rows): manually flagged anomalies — match the
-- two example incidents referenced in the report's reflection.
-- ---------------------------------------------------------------------
INSERT INTO performance_flag (player_id, tournament_id, flag_reason, flagged_at) VALUES
    (1,  3, 'Unusual stamina increase across consecutive five-set matches',
        TIMESTAMP '2025-03-30 18:00:00'),  -- Alcaraz @ Miami
    (10, 3, 'Significant performance spike vs. baseline tournament average',
        TIMESTAMP '2025-03-30 19:00:00');  -- Swiatek @ Miami
