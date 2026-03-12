# CS1DB Databases Coursework

A group technical assignment for the **CS1DB Databases module**, worth **50% of the final mark**. One PDF report (max ~7 pages, figures in annex) due **11 May 2026**.

---

## 1. Group Requirements

- Work in **groups of 4 students**
- One spokesperson registers the group before **25 Feb 2026**
- Submit one **effort allocation sheet** showing each member's contribution percentage

---

## 2. Database Project Scenario

Design and implement a **tennis tournament database** tracking:

**Players** — male/female, singles/doubles, name, gender, nationality, etc.

**Tournaments** — including Grand Slams; name, location, surface type, dates

**Matches** — results, winners, final set scores

**Coaches** — player–coach relationships; coaches must have professional playing experience

**Performance / Doping Detection** — flag players with significant performance improvements or sudden increases in games/sets won compared to previous tournaments

---

## 3. Required Queries

**Simple**
- Last 2 tournaments a player participated in
- Grand Slam winners from the previous year
- Player rankings based on match wins
- Players with frequent coach changes in last 3 years

**Complex**
- Winners of the Sunshine Double (Indian Wells + Miami Open)
- People who won championships as both player and coach
- Coaches who won titles with multiple players
- Players suspected of doping

---

## 4. Minimum Data Requirements

- 15+ players
- 5+ tournaments
- Match data for semi-finals and finals

---

## 5. Report Structure

1. **Introduction** — background, design techniques used
2. **Database Design & Implementation**
   - E-R Model (entities, attributes, keys, relationships, cardinalities, constraints — must satisfy 3NF)
   - SQL DDL (create tables) & DML (insert data) in PostgreSQL
   - 2 simple queries + 2 complex queries with SQL code and result screenshots
3. **Reflection** — strengths/weaknesses, improvements, legal/ethical/security considerations
4. **Conclusion** — short project summary

---

## 6. Marking Criteria

- E-R modelling & normalisation
- SQL implementation (DDL + DML)
- Query design
- Critical reflection
- Report presentation

# Report Structure
1. Front Page

2. Introduction

3. Database Design
   - ER Diagram
   - Design Decisions
   - Third Normal Form

4. Database Implementation
   4.1 SQL-DDL
   4.2 SQL-DML

5. Querying the Database
   - Simple Queries
   - Complex Queries

6. Reflection

7. Conclusion

8. Effort Allocation Sheet



npx prisma migrate dev