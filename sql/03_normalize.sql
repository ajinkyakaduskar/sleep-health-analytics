-- =============================================================================
-- 03_normalize.sql  —  Split the flat staging table into a star-ish schema
-- =============================================================================
--   occupation      (dimension)   ─┐
--   sleepdisorder   (dimension)    │
--   person          (hub)  ────────┼── one row per person, FK → occupation
--   sleepdata       (fact)  ───────┤   FK → person, FK → sleepdisorder
--   lifestyledata   (fact)  ───────┤   FK → person
--   healthmetrics   (fact)  ───────┘   FK → person
--
-- Run order matters: dimensions first, then person, then the three fact tables.
-- =============================================================================

-- ---------- DIMENSION: occupation ----------
DROP TABLE IF EXISTS occupation CASCADE;
CREATE TABLE occupation (
    occupation_id   SERIAL PRIMARY KEY,
    occupation_name VARCHAR(50) UNIQUE
);
INSERT INTO occupation (occupation_name)
SELECT DISTINCT occupation FROM raw_sleep ORDER BY occupation;

-- ---------- DIMENSION: sleepdisorder ----------
DROP TABLE IF EXISTS sleepdisorder CASCADE;
CREATE TABLE sleepdisorder (
    disorder_id   SERIAL PRIMARY KEY,
    disorder_name VARCHAR(50) UNIQUE
);
INSERT INTO sleepdisorder (disorder_name)
SELECT DISTINCT sleep_disorder FROM raw_sleep ORDER BY sleep_disorder;

-- ---------- HUB: person ----------
DROP TABLE IF EXISTS person CASCADE;
CREATE TABLE person (
    person_id     INT PRIMARY KEY,
    gender        VARCHAR(10),
    age           INT,
    occupation_id INT REFERENCES occupation(occupation_id)
);
INSERT INTO person (person_id, gender, age, occupation_id)
SELECT r.person_id::int, r.gender, r.age, o.occupation_id
FROM raw_sleep r
JOIN occupation o ON r.occupation = o.occupation_name;

-- ---------- FACT: sleepdata ----------
DROP TABLE IF EXISTS sleepdata CASCADE;
CREATE TABLE sleepdata (
    sleepdata_id   SERIAL PRIMARY KEY,
    person_id      INT REFERENCES person(person_id),
    sleep_duration NUMERIC,
    sleep_quality  INT,
    disorder_id    INT REFERENCES sleepdisorder(disorder_id)
);
INSERT INTO sleepdata (person_id, sleep_duration, sleep_quality, disorder_id)
SELECT r.person_id::int, r.sleep_duration, r.quality_of_sleep, sd.disorder_id
FROM raw_sleep r
JOIN sleepdisorder sd ON r.sleep_disorder = sd.disorder_name;

-- ---------- FACT: lifestyledata ----------
DROP TABLE IF EXISTS lifestyledata CASCADE;
CREATE TABLE lifestyledata (
    lifestyle_id      SERIAL PRIMARY KEY,
    person_id         INT REFERENCES person(person_id),
    physical_activity INT,
    daily_steps       INT,
    stress_level      INT
);
INSERT INTO lifestyledata (person_id, physical_activity, daily_steps, stress_level)
SELECT person_id::int, physical_activity, daily_steps, stress_level
FROM raw_sleep;

-- ---------- FACT: healthmetrics ----------
DROP TABLE IF EXISTS healthmetrics CASCADE;
CREATE TABLE healthmetrics (
    health_id    SERIAL PRIMARY KEY,
    person_id    INT REFERENCES person(person_id),
    bmi_category VARCHAR(20),
    systolic     INT,
    diastolic    INT,
    heart_rate   INT
);
INSERT INTO healthmetrics (person_id, bmi_category, systolic, diastolic, heart_rate)
SELECT person_id::int, bmi_category, systolic, diastolic, heart_rate
FROM raw_sleep;

-- ---------- Row-count check: every table should show 1500 except the two dimensions ----------
SELECT 'raw_sleep'     AS tbl, COUNT(*) FROM raw_sleep
UNION ALL SELECT 'occupation',    COUNT(*) FROM occupation      -- 15
UNION ALL SELECT 'sleepdisorder', COUNT(*) FROM sleepdisorder   -- 5
UNION ALL SELECT 'person',        COUNT(*) FROM person
UNION ALL SELECT 'sleepdata',     COUNT(*) FROM sleepdata
UNION ALL SELECT 'lifestyledata', COUNT(*) FROM lifestyledata
UNION ALL SELECT 'healthmetrics', COUNT(*) FROM healthmetrics;
