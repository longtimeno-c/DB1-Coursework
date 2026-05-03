You need to build a group PostgreSQL database project for a tennis tournament results system, then submit one PDF report on Blackboard by 11 May 2026. It is worth 50% of CS1DB.

What the coursework is

You are designing and implementing a database that tracks:

tennis players, male and female
singles and doubles matches
tournaments/events, especially Grand Slams and major tournaments
match results, including set scores
player–coach relationships over time
coaches, who must also have had professional playing experience
performance improvements that could suggest possible doping

You can use dummy/synthetic data, but you need at least:

15+ players
5+ events/tournaments
complete match data for at least the semi-finals and finals of each event
enough attributes to support the required queries
What you actually need to submit

Submit one group report as a PDF. Max length is 7 pages, but you can use an annex/appendix for figures/screenshots. You also need an effort allocation sheet showing each group member’s contribution percentage, note, and signature.

The report should follow this structure:

1. Front page

Include:

Module Code: CS1DB
Assignment report title
Date completed
Actual hours spent
AI tools used, if any
2. Introduction — 10 marks

Explain the background of the project: basically, that you are creating a database for tennis players, tournaments, results, coaches, and performance tracking.

Also explain which design techniques you will use, for example:

E-R modelling
normalisation to 3NF
PostgreSQL implementation
SQL DDL for table creation
SQL DML for inserting and querying data
3. E-R modelling — 30 marks

This is a big section.

You need to create an Entity Relationship model, probably in draw.io, showing your database structure. The supporting material says the evidence expected is an E-R diagram, defined entities, constraints, assumptions, and a written justification that the model is in 3NF.

Your model should include entities such as:

Player
Coach
Tournament
Event
Match
MatchSet
PlayerCoach
Team or DoublesTeam
MatchParticipant
PerformanceMetric

For each table/entity, show:

attributes
data types
primary keys
foreign keys
relationships
cardinality, e.g. one-to-many, many-to-many
constraints
assumptions

You also need to explain why it is in Third Normal Form. That means saying things like:

each table represents one clear thing
every non-key attribute depends on the whole primary key
there are no transitive dependencies
repeated data has been split into separate tables
many-to-many relationships use linking tables
4. PostgreSQL implementation — 30 marks

You need to actually build the database in PostgreSQL.

This means writing SQL DDL like:

CREATE TABLE player (...);
CREATE TABLE tournament (...);
CREATE TABLE match (...);

You need to show:

the SQL code used to create the tables
screenshots proving the tables were created
validation that the structure matches your E-R model
evidence that constraints work properly

Then you need to populate the tables using SQL DML:

INSERT INTO player (...) VALUES (...);
INSERT INTO tournament (...) VALUES (...);
INSERT INTO match (...) VALUES (...);

You need screenshots showing data in the tables. The supporting material specifically says to evidence table population and include full SQL code for the queries.

5. Query data from the database — 15 marks

You need to choose:

2 simple queries
2 complex queries

From the assignment list.

Simple query options include:

last 2 tournaments a specified player participated in
all Grand Slam winners from the previous year
ranking table based on singles match victories
players with most frequent coach changes in the past 3 years

Complex query options include:

winners of the Sunshine Double, or two events in the same year
people who won championships both as players and coaches
coaches who won championships with multiple players
suspected doping players

For each query, include:

test case name
what the query is meant to prove
SQL code
screenshot of the result
short explanation of whether it worked

The supporting material gives this exact style: test description, expected outcome, entity creation/data insertion, SQL query, and result screenshot.

6. Reflection — 10 marks

You need to critically evaluate the database.

Talk about technical strengths and weaknesses, for example:

3NF reduces duplication
foreign keys maintain consistency
constraints prevent invalid data
synthetic data limits realism
doping detection is simplified and would need better real-world data
doubles matches make modelling more complex

Then cover legal, social, ethical, and professional issues:

doping suspicion should not be treated as proof
player data should be handled carefully
performance analytics could be unfair or misleading
access control and information security are needed
backups, permissions, and data validation matter
7. Conclusion — 5 marks

Summarise what your group built:

an E-R model
a normalised PostgreSQL database
populated test data
working SQL queries
reflections on limitations and ethics
Group admin stuff

Your group should have four members. A spokesperson was supposed to register the group by 25 February 2026, but the actual coursework submission is due 11 May 2026. You must include the effort allocation sheet with contribution percentages.

What I’d do first

Start with the database design, not the report. Build the tables around these core ideas:

Players can play matches.
Coaches are also people with playing experience.
Tournaments contain events.
Matches belong to events.
Matches have participants and winners.
Sets store the actual scores.
Coach relationships need start and end dates.
Performance metrics can be calculated per player per tournament.

Then write the SQL, insert dummy data, run the four queries, screenshot everything, and finally assemble the report.