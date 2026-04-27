# CS1DB Tennis Tournament Database

A relational database system for managing professional tennis tournaments, built for the **CS1DB Databases** module coursework (50% of final mark). Due **11 May 2026**.

---

## Overview

This project implements a fully normalised (3NF) PostgreSQL database that tracks:

- **15 players** (9 male, 6 female) — top ATP/WTA professionals
- **9 coaches** — all with verified professional playing experience
- **5 tournaments** — including 2 Grand Slams + Indian Wells & Miami (Sunshine Double)
- **30 matches** — semi-finals and finals for both genders across all tournaments
- **Set-by-set scoring** — granular `MatchScore` records for all finals
- **Coaching history** — temporal player–coach relationships with start/end dates
- **Performance anomaly detection** — doping flags based on statistical spikes

## Tech Stack

| Component | Technology |
|---|---|
| Database | PostgreSQL 14+ |
| ORM | Prisma (v6/v7) |
| Runtime | Node.js 18+ |
| Language | JavaScript (CommonJS) |
| Config | dotenv for environment variables |

## Project Structure

```
DB1-Coursework/
├── prisma/
│   └── schema.prisma          # Prisma schema (8 models)
├── prisma.config.ts            # Prisma configuration
├── sql/
│   ├── ddl.sql                 # CREATE TABLE statements with constraints
│   ├── dml.sql                 # INSERT statements (seed data)
│   └── queries.sql             # All 8 queries in raw PostgreSQL SQL
├── src/
│   ├── db.js                   # Prisma client singleton
│   ├── seed.js                 # Programmatic seeding via Prisma
│   └── queries.js              # All 8 queries via Prisma $queryRaw
├── REPORT.md                   # Full coursework report
├── plan.md                     # Execution plan & checklist
├── package.json                # Dependencies and scripts
└── README.md                   # This file
```

## Database Schema

Eight tables in Third Normal Form:

| Table | Description | Key Constraints |
|---|---|---|
| `Player` | Tennis players (M/F) | `CHECK (gender IN ('M','F'))`, PK `id` |
| `Coach` | Coaches with playing experience | `CHECK (former_player_experience = TRUE)` |
| `PlayerCoach` | Temporal player–coach relationships | FK → Player, Coach; `CHECK (end_date > start_date)` |
| `Tournament` | Tournament events | `CHECK (surface_type IN ('Hard','Clay','Grass'))` |
| `Match` | Individual matches within tournaments | FK → Tournament; `CHECK (round IN ('R128'...'F'))` |
| `MatchPlayer` | Players in each match + outcome | FK → Match, Player; `UNIQUE(match_id, player_id)` |
| `MatchScore` | Set-by-set scoring | FK → Match; `UNIQUE(match_id, set_number)` |
| `PerformanceFlag` | Doping/anomaly flags | FK → Player, Tournament |

### E-R Relationships

```
Player ←──M:N──→ Coach        (via PlayerCoach, temporal)
Player ←──M:N──→ Match        (via MatchPlayer)
Tournament ──1:N──→ Match
Match ──1:N──→ MatchScore
Player ──1:N──→ PerformanceFlag
Tournament ──1:N──→ PerformanceFlag
```

## Queries Implemented

### Simple
| # | Query | Technique |
|---|---|---|
| Q1 | Last 2 tournaments a player participated in | Multi-join + `ORDER BY ... LIMIT 2` |
| Q2 | Grand Slam winners from previous year | `EXTRACT(YEAR)` + dynamic date filter |
| Q3 | Player rankings by total match wins | `ROW_NUMBER()` window function + `GROUP BY` |
| Q4 | Players with frequent coach changes (3 yrs) | `COUNT(DISTINCT)` + `HAVING` + `INTERVAL` |

### Complex
| # | Query | Technique |
|---|---|---|
| Q5 | Sunshine Double winners (IW + Miami same year) | `GROUP BY` + `HAVING COUNT(DISTINCT) = 2` |
| Q6 | Won championships as both player and coach | CTEs + `INTERSECT` set operation |
| Q7 | Coaches who won titles with multiple players | 6-way join + temporal `BETWEEN` filter + `STRING_AGG` |
| Q8 | Doping suspects (performance spike detection) | `LAG()` window function + CTEs + threshold filter |

## Setup & Usage

### Prerequisites
- Node.js >= 18
- PostgreSQL >= 14 running locally (or hosted)
- npm

### 1. Install dependencies
```bash
npm install
```

### 2. Configure database connection
Create a `.env` file in the project root:
```env
DATABASE_URL="postgresql://<user>:<password>@localhost:5432/tennis_db"
```

### 3. Run Prisma migration
```bash
npx prisma migrate dev --name init
```

### 4. Seed the database

**Option A — Via Prisma ORM (recommended):**
```bash
npm run seed
```

**Option B — Via raw SQL (direct PostgreSQL):**
```bash
psql -d tennis_db -f sql/ddl.sql
psql -d tennis_db -f sql/dml.sql
```

### 5. Run queries

**Option A — Via Prisma ORM:**
```bash
npm run queries
```

**Option B — Via raw SQL:**
```bash
psql -d tennis_db -f sql/queries.sql
```

### 6. Browse data visually
```bash
npx prisma studio
```

### Reset (destructive — wipes all data)
```bash
npx prisma migrate reset
```

## npm Scripts

| Script | Command | Description |
|---|---|---|
| `npm run seed` | `node src/seed.js` | Seed the database with all test data |
| `npm run queries` | `node src/queries.js` | Execute all 8 queries and print results |
| `npm test` | — | Placeholder (no tests configured) |

## Seed Data Summary

| Entity | Count | Notes |
|---|---|---|
| Coaches | 9 | Lendl, Apostolos, Moya, Nadal, Edberg, Cahill, Groeneveld, Annacone, Fissette |
| Players | 15 | Alcaraz, Djokovic, Sinner, Medvedev, Zverev, Tsitsipas, Rublev, Rune, Fritz, Swiatek, Sabalenka, Gauff, Rybakina, Pegula, Garcia |
| Player–Coach links | 14 | Includes historical + current relationships |
| Tournaments | 5 | Australian Open, Indian Wells, Miami, Roland Garros, Wimbledon |
| Matches | 30 | 2 SFs + 1 Final per gender × 5 tournaments |
| Match Scores | 25 | Full set-by-set for all 10 finals |
| Performance Flags | 2 | Alcaraz + Swiatek flagged at Miami Open |

## Normalisation

The schema satisfies **Third Normal Form (3NF)**:
- **1NF:** All attributes atomic, no repeating groups, every table has a PK
- **2NF:** No partial dependencies (single-column surrogate keys)
- **3NF:** No transitive dependencies (verified for all 8 tables)

See [REPORT.md](REPORT.md) for the full normalisation analysis.

## Key Design Decisions

1. **Surrogate keys** on all tables (SERIAL) — simplifies joins, decouples identity from business data
2. **Temporal coaching** — `PlayerCoach.endDate` nullable (NULL = current) enables historical queries
3. **MatchPlayer junction** — supports future doubles extension without schema changes
4. **CHECK constraints** — enforce domain rules (gender, surface type, rounds, coach experience) at DB level
5. **Cascading deletes** — `ON DELETE CASCADE` prevents orphan records
6. **Performance indexes** — 7 indexes on FK columns used in multi-join queries

## Report

The full technical report is in [REPORT.md](REPORT.md), covering:
1. Introduction with academic citations
2. E-R model with full cardinality analysis
3. 3NF normalisation proof for all 8 tables
4. DDL with constraint explanations
5. DML with data design rationale
6. 4 simple + 4 complex queries with SQL, explanations, and expected results
7. Reflection (strengths, weaknesses, improvements, legal/ethical/security)
8. Conclusion and Harvard-formatted references

## License

ISC