# Project Execution Plan — CS1DB Tennis Tournament Database

Due: **11 May 2026** | Weight: **50% of final mark** | Target: **First Class / Distinction (≥70%)**

---

## Phase 1 — Environment Setup

### 1.1 Prerequisites
- Node.js ≥ 18
- PostgreSQL ≥ 14 running locally (or a hosted instance)
- `npm` (already installed)

### 1.2 Install dependencies
```bash
npm install
```

### 1.3 Configure database connection
Create a `.env` file in the project root:
```env
DATABASE_URL="postgresql://<user>:<password>@localhost:5432/tennis_db"
```
> `.env` is read by `prisma.config.ts` via `dotenv/config`.

---

## Phase 2 — Database Design (E-R Model)

This is the highest-weighted section. It must satisfy **3NF** and use professional notation (crow's foot or Chen).

### 2.1 Entities & key attributes

| Entity | Key attributes |
|---|---|
| `Player` | id, name, gender, nationality, dateOfBirth, isActive |
| `Coach` | id, name, nationality, formerPlayerExperience (bool) |
| `Tournament` | id, name, location, surfaceType, startDate, endDate, isGrandSlam |
| `Match` | id, tournamentId, round, matchDate, surface |
| `MatchPlayer` | matchId, playerId, side (A/B), isWinner (doubles join) |
| `PlayerCoach` | playerId, coachId, startDate, endDate |
| `MatchScore` | id, matchId, setNumber, playerAGames, playerBGames |
| `PerformanceFlag` | id, playerId, tournamentId, flagReason, flaggedAt |

### 2.2 Key relationships & cardinalities
- Player ↔ Tournament: **many-to-many** via Match + MatchPlayer
- Player ↔ Coach: **many-to-many** (over time) via PlayerCoach (track history)
- Match → Tournament: **many-to-one**
- Match → MatchScore: **one-to-many** (one row per set)
- Coach constraint: `formerPlayerExperience = true` required

### 2.3 Normalisation checklist
- [ ] No repeating groups (1NF)
- [ ] Every non-key attribute fully depends on the whole key (2NF)
- [ ] No transitive dependencies (3NF)
- [ ] Coach/Player split correctly (coaches who were also players are in both tables)

### 2.4 Deliverable
Draw the E-R diagram (use [draw.io](https://draw.io), Lucidchart, or pgModeler) and export as PNG for the report annex.

---

## Phase 3 — Prisma Schema Implementation

Edit `prisma/schema.prisma` to define all models from Phase 2.

### 3.1 Reference model structure
```prisma
model Player {
  id            Int            @id @default(autoincrement())
  name          String
  gender        String         // "M" | "F"
  nationality   String
  dateOfBirth   DateTime
  isActive      Boolean        @default(true)
  coaches       PlayerCoach[]
  matchEntries  MatchPlayer[]
  flags         PerformanceFlag[]
}

model Coach {
  id                     Int           @id @default(autoincrement())
  name                   String
  nationality            String
  formerPlayerExperience Boolean
  players                PlayerCoach[]
}

model PlayerCoach {
  id        Int      @id @default(autoincrement())
  player    Player   @relation(fields: [playerId], references: [id])
  playerId  Int
  coach     Coach    @relation(fields: [coachId], references: [id])
  coachId   Int
  startDate DateTime
  endDate   DateTime?
}

model Tournament {
  id          Int      @id @default(autoincrement())
  name        String
  location    String
  surfaceType String   // "Hard" | "Clay" | "Grass"
  startDate   DateTime
  endDate     DateTime
  isGrandSlam Boolean  @default(false)
  matches     Match[]
}

model Match {
  id           Int          @id @default(autoincrement())
  tournament   Tournament   @relation(fields: [tournamentId], references: [id])
  tournamentId Int
  round        String       // "QF" | "SF" | "F"
  matchDate    DateTime
  players      MatchPlayer[]
  scores       MatchScore[]
}

model MatchPlayer {
  id       Int     @id @default(autoincrement())
  match    Match   @relation(fields: [matchId], references: [id])
  matchId  Int
  player   Player  @relation(fields: [playerId], references: [id])
  playerId Int
  side     String  // "A" | "B"
  isWinner Boolean @default(false)
}

model MatchScore {
  id            Int    @id @default(autoincrement())
  match         Match  @relation(fields: [matchId], references: [id])
  matchId       Int
  setNumber     Int
  playerAGames  Int
  playerBGames  Int
}

model PerformanceFlag {
  id           Int      @id @default(autoincrement())
  player       Player   @relation(fields: [playerId], references: [id])
  playerId     Int
  tournament   Tournament @relation(fields: [tournamentId], references: [id])
  tournamentId Int
  flagReason   String
  flaggedAt    DateTime @default(now())
}
```

### 3.2 Run the migration
```bash
npx prisma migrate dev --name init
```
This creates `prisma/migrations/` and applies the schema to your database.

---

## Phase 4 — Seed Data (DDL + DML)

Minimum requirements: **15+ players, 5+ tournaments, SF + Final match data**.

### 4.1 Create `src/seed.js`
```js
const prisma = require('./db');

async function main() {
  // 1. Create tournaments (include Indian Wells + Miami Open for Sunshine Double query)
  // 2. Create coaches (with formerPlayerExperience = true)
  // 3. Create players (8 male, 7 female minimum)
  // 4. Link players to coaches via PlayerCoach (include some with multiple coaches over time)
  // 5. Create matches (at least SF + Final per tournament)
  // 6. Add MatchPlayers and MatchScores for each match
  // 7. Optionally seed PerformanceFlags for doping detection
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
```

### 4.2 Add seed script to `package.json`
```json
"scripts": {
  "seed": "node src/seed.js"
}
```

### 4.3 Run seed
```bash
npm run seed
```

---

## Phase 5 — Query Implementation

Create `src/queries.js` (or separate files per query). Include SQL equivalents in the report.

### Simple Queries

**Q1 — Last 2 tournaments a player participated in**
```sql
SELECT t.name, t.start_date
FROM match_player mp
JOIN match m ON mp.match_id = m.id
JOIN tournament t ON m.tournament_id = t.id
WHERE mp.player_id = :playerId
ORDER BY t.start_date DESC
LIMIT 2;
```

**Q2 — Grand Slam winners from the previous year**
```sql
SELECT DISTINCT p.name, t.name AS tournament
FROM match_player mp
JOIN match m ON mp.match_id = m.id
JOIN tournament t ON m.tournament_id = t.id
JOIN player p ON mp.player_id = p.id
WHERE t.is_grand_slam = true
  AND mp.is_winner = true
  AND m.round = 'F'
  AND EXTRACT(YEAR FROM t.start_date) = EXTRACT(YEAR FROM NOW()) - 1;
```

**Q3 — Player rankings (by match wins)**
```sql
SELECT p.name, COUNT(*) AS wins
FROM match_player mp
JOIN player p ON mp.player_id = p.id
WHERE mp.is_winner = true
GROUP BY p.id, p.name
ORDER BY wins DESC;
```

**Q4 — Players with frequent coach changes (last 3 years)**
```sql
SELECT p.name, COUNT(pc.coach_id) AS coach_changes
FROM player_coach pc
JOIN player p ON pc.player_id = p.id
WHERE pc.start_date >= NOW() - INTERVAL '3 years'
GROUP BY p.id, p.name
HAVING COUNT(pc.coach_id) > 1
ORDER BY coach_changes DESC;
```

### Complex Queries

**Q5 — Sunshine Double winners (Indian Wells + Miami Open same year)**
```sql
SELECT p.name, EXTRACT(YEAR FROM t.start_date) AS year
FROM match_player mp
JOIN match m ON mp.match_id = m.id
JOIN tournament t ON m.tournament_id = t.id
JOIN player p ON mp.player_id = p.id
WHERE mp.is_winner = true AND m.round = 'F'
  AND t.name IN ('Indian Wells Open', 'Miami Open')
GROUP BY p.id, p.name, EXTRACT(YEAR FROM t.start_date)
HAVING COUNT(DISTINCT t.name) = 2;
```

**Q6 — People who won championships as both player and coach**
```sql
SELECT p.name
FROM match_player mp
JOIN player p ON mp.player_id = p.id
JOIN match m ON mp.match_id = m.id
WHERE mp.is_winner = true AND m.round = 'F'
INTERSECT
SELECT c.name
FROM player_coach pc
JOIN coach c ON pc.coach_id = c.id
JOIN match_player mp ON mp.player_id = pc.player_id
JOIN match m ON mp.match_id = m.id
WHERE mp.is_winner = true AND m.round = 'F';
```

**Q7 — Coaches who won titles with multiple different players**
```sql
SELECT c.name, COUNT(DISTINCT mp.player_id) AS players_won_with
FROM player_coach pc
JOIN coach c ON pc.coach_id = c.id
JOIN match_player mp ON mp.player_id = pc.player_id
JOIN match m ON mp.match_id = m.id
WHERE mp.is_winner = true AND m.round = 'F'
  AND m.match_date BETWEEN pc.start_date AND COALESCE(pc.end_date, NOW())
GROUP BY c.id, c.name
HAVING COUNT(DISTINCT mp.player_id) > 1;
```

**Q8 — Players suspected of doping (significant performance spike)**
```sql
WITH wins_per_tournament AS (
  SELECT mp.player_id, m.tournament_id, COUNT(*) AS wins
  FROM match_player mp
  JOIN match m ON mp.match_id = m.id
  WHERE mp.is_winner = true
  GROUP BY mp.player_id, m.tournament_id
),
ranked AS (
  SELECT *,
    LAG(wins) OVER (PARTITION BY player_id ORDER BY tournament_id) AS prev_wins
  FROM wins_per_tournament
)
SELECT p.name, r.tournament_id, r.wins, r.prev_wins,
       (r.wins - r.prev_wins) AS improvement
FROM ranked r
JOIN player p ON r.player_id = p.id
WHERE r.prev_wins IS NOT NULL
  AND (r.wins - r.prev_wins) >= 2  -- threshold: tune as needed
ORDER BY improvement DESC;
```

### 5.1 Run queries in Prisma (`$queryRaw`)
```js
const results = await prisma.$queryRaw`
  SELECT p.name, COUNT(*) AS wins ...
`;
console.table(results);
```

---

## Phase 6 — Testing & Screenshots

- [ ] Run each query and capture **result screenshots** (required for report)
- [ ] Verify row counts match seeded data
- [ ] Test edge cases (player with no matches, coach with no wins, etc.)
- [ ] Use `psql` or a GUI (TablePlus, DBeaver, pgAdmin) for clean screenshots

```bash
npx prisma studio   # visual browser for your data
```

---

## Phase 7 — Report Writing

Max **~7 pages** body + annex. Use the structure below.

| Section | Content | Tips for Distinction |
|---|---|---|
| **1. Introduction** | Background, chosen design techniques | Cite academic sources (books, papers) |
| **2a. E-R Model** | Diagram + written explanation of entities, relationships, cardinalities, constraints, 3NF proof | Use professional notation; annotate every cardinality |
| **2b. SQL DDL** | `CREATE TABLE` statements with constraints | Show PK, FK, NOT NULL, CHECK constraints explicitly |
| **2c. SQL DML** | Sample `INSERT` statements | Explain design decisions inline |
| **2d. Queries** | SQL code + result screenshot for 2 simple + 2 complex | Explain what each query does and why it answers the scenario |
| **3. Reflection** | Strengths, weaknesses, improvements, legal/ethical/security | Mention GDPR for player data; discuss indexing/performance |
| **4. Conclusion** | Short project summary | Tie back to learning outcomes |

### References (Harvard style, minimum 5)
- Ramakrishnan, R. & Gehrke, J. (2003) *Database Management Systems*. McGraw-Hill.
- Date, C.J. (2004) *An Introduction to Database Systems*. Pearson.
- Elmasri, R. & Navathe, S. (2015) *Fundamentals of Database Systems*. Pearson.
- PostgreSQL Documentation: https://www.postgresql.org/docs/
- Prisma Documentation: https://www.prisma.io/docs

---

## Phase 8 — Final Checklist Before Submission

- [ ] E-R diagram exported as PNG in report annex
- [ ] All 4 queries answered (2 simple + 2 complex) with screenshots
- [ ] DDL + DML SQL included in report
- [ ] 15+ players, 5+ tournaments, SF + Final data seeded
- [ ] Effort allocation sheet completed (all 4 group members)
- [ ] Coach constraint enforced (`formerPlayerExperience = true`)
- [ ] Report is ≤ ~7 pages body (figures in annex don't count)
- [ ] References formatted consistently (Harvard)
- [ ] PDF exported and ready to submit by **11 May 2026**

---

## Quick Command Reference

```bash
# Setup
cp .env.example .env          # fill in DATABASE_URL
npm install

# Database
npx prisma migrate dev --name init    # apply schema
npm run seed                          # insert test data
npx prisma studio                     # visual data browser

# Development
node src/queries.js                   # run query scripts

# Reset (destructive — wipes all data)
npx prisma migrate reset
```
