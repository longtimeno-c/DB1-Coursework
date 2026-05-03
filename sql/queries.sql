-- =====================================================================
-- CS1DB — Tennis Tournament Database — Coursework Queries
-- Target: PostgreSQL 14+. Run AFTER sql/ddl.sql and sql/dml.sql.
--
-- 4 simple queries (Q1–Q4) and 4 complex queries (Q5–Q8) drawn from
-- the assignment brief in README.md.
-- =====================================================================


-- =====================================================================
-- Q1 (simple): Last 2 tournaments a specified player participated in.
--   - Test: with the seed for 'Carlos Alcaraz', expect Wimbledon (Grass,
--     30 Jun 2025) and Roland Garros (Clay, 25 May 2025).
--   - DISTINCT is required because each match Alcaraz played in produces
--     a separate join row; without it, LIMIT 2 would return two rows of
--     the most recent tournament.
-- =====================================================================
SELECT DISTINCT
    p.name         AS player,
    t.name         AS tournament,
    t.start_date,
    t.surface_type
FROM match_player mp
JOIN match       m ON mp.match_id     = m.id
JOIN tournament  t ON m.tournament_id = t.id
JOIN player      p ON mp.player_id    = p.id
WHERE p.name = 'Carlos Alcaraz'
ORDER BY t.start_date DESC
LIMIT 2;


-- =====================================================================
-- Q2 (simple): All Grand Slam winners from the previous calendar year.
--   - With CURRENT_DATE in 2026 and the seed dated 2025, returns the
--     four 2025 Grand Slam finalists (AO + Roland Garros, both genders).
--   - Wimbledon's is_grand_slam = FALSE in this seed, so it does not
--     appear; flip it to TRUE to include Wimbledon winners.
-- =====================================================================
SELECT
    p.name        AS player,
    t.name        AS grand_slam,
    t.start_date  AS tournament_date
FROM match_player mp
JOIN match       m ON mp.match_id     = m.id
JOIN tournament  t ON m.tournament_id = t.id
JOIN player      p ON mp.player_id    = p.id
WHERE t.is_grand_slam = TRUE
  AND m.round         = 'F'
  AND mp.is_winner    = TRUE
  AND EXTRACT(YEAR FROM t.start_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
ORDER BY t.start_date;


-- =====================================================================
-- Q3 (simple): Player ranking based on total singles match victories.
--   - ROW_NUMBER assigns a unique rank even on ties; swap to RANK() if
--     you prefer ties to share a rank.
-- =====================================================================
SELECT
    ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rank,
    p.name                                     AS player,
    p.nationality,
    COUNT(*)                                   AS total_wins
FROM match_player mp
JOIN player p ON mp.player_id = p.id
WHERE mp.is_winner = TRUE
GROUP BY p.id, p.name, p.nationality
ORDER BY total_wins DESC, p.name;


-- =====================================================================
-- Q4 (simple): Players with the most frequent coach changes in the
--             last 3 years.
--   - Filters coaching relationships whose start_date is within the
--     last 3 years of CURRENT_DATE, then counts distinct coaches per
--     player; only players with > 1 distinct coach are returned.
-- =====================================================================
SELECT
    p.name                       AS player,
    COUNT(DISTINCT pc.coach_id)  AS coach_changes
FROM player_coach pc
JOIN player p ON pc.player_id = p.id
WHERE pc.start_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY p.id, p.name
HAVING COUNT(DISTINCT pc.coach_id) > 1
ORDER BY coach_changes DESC, p.name;


-- =====================================================================
-- Q5 (complex): Sunshine Double — players who won the Indian Wells
--               Open AND Miami Open finals in the same calendar year.
-- =====================================================================
SELECT
    p.name                                AS player,
    EXTRACT(YEAR FROM t.start_date)::INT  AS year
FROM match_player mp
JOIN match      m ON mp.match_id     = m.id
JOIN tournament t ON m.tournament_id = t.id
JOIN player     p ON mp.player_id    = p.id
WHERE mp.is_winner = TRUE
  AND m.round      = 'F'
  AND t.name IN ('Indian Wells Open', 'Miami Open')
GROUP BY p.id, p.name, EXTRACT(YEAR FROM t.start_date)
HAVING COUNT(DISTINCT t.name) = 2
ORDER BY year, player;


-- =====================================================================
-- Q6 (complex): People who won championships as both player and coach.
--   - Name-based intersection. Returns empty against the current seed
--     because the player and coach tables share no names — this is an
--     acknowledged design limitation. A unified Person table would let
--     identity-based matching work without relying on string equality.
-- =====================================================================
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
    JOIN coach        c  ON pc.coach_id     = c.id
    JOIN match_player mp ON mp.player_id    = pc.player_id
    JOIN match        m  ON mp.match_id     = m.id
    JOIN tournament   t  ON m.tournament_id = t.id
    WHERE mp.is_winner = TRUE
      AND m.round = 'F'
      AND t.start_date BETWEEN pc.start_date
                           AND COALESCE(pc.end_date, CURRENT_DATE)
)
SELECT name AS person FROM player_title_names
INTERSECT
SELECT name AS person FROM coach_title_names
ORDER BY person;


-- =====================================================================
-- Q7 (complex): Coaches who won finals with more than one distinct
--               player, only counting wins inside the active coaching
--               period.
-- =====================================================================
SELECT
    c.name                                            AS coach,
    COUNT(DISTINCT mp.player_id)                      AS distinct_players_won_with,
    STRING_AGG(DISTINCT p.name, ', ' ORDER BY p.name) AS players
FROM player_coach pc
JOIN coach        c  ON pc.coach_id     = c.id
JOIN match_player mp ON mp.player_id    = pc.player_id
JOIN match        m  ON mp.match_id     = m.id
JOIN tournament   t  ON m.tournament_id = t.id
JOIN player       p  ON mp.player_id    = p.id
WHERE mp.is_winner = TRUE
  AND m.round = 'F'
  AND t.start_date BETWEEN pc.start_date
                       AND COALESCE(pc.end_date, CURRENT_DATE)
GROUP BY c.id, c.name
HAVING COUNT(DISTINCT mp.player_id) > 1
ORDER BY distinct_players_won_with DESC, coach;


-- =====================================================================
-- Q8 (complex): Players suspected of doping — flagged when match-win
--               count at a tournament jumps by ≥ 2 versus the player's
--               immediately preceding tournament.
--   - Uses LAG() partitioned per player, ordered by tournament start.
-- =====================================================================
WITH wins_per_tournament AS (
    SELECT
        mp.player_id,
        m.tournament_id,
        t.start_date,
        COUNT(*) AS wins
    FROM match_player mp
    JOIN match      m ON mp.match_id     = m.id
    JOIN tournament t ON m.tournament_id = t.id
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
ORDER BY improvement DESC, player;
