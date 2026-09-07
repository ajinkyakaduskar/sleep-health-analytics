-- =============================================================================
-- 01_load_raw.sql  —  Stage the raw CSV into PostgreSQL
-- =============================================================================
-- All columns land as TEXT on purpose: the source file has a combined
-- "111/71.15" blood-pressure string and a header row that gets imported as data
-- when loading through pgAdmin's Import tool. Types are fixed in 02_clean.sql.
--
-- Load method used: pgAdmin → right-click raw_sleep → Import/Export Data →
-- Format CSV, Header ON, Delimiter ','. (Or use \copy from psql — see below.)
-- =============================================================================

DROP TABLE IF EXISTS raw_sleep;

CREATE TABLE raw_sleep (
    person_id         TEXT,
    gender            TEXT,
    age               TEXT,
    occupation        TEXT,
    sleep_duration    TEXT,
    quality_of_sleep  TEXT,
    physical_activity TEXT,
    stress_level      TEXT,
    bmi_category      TEXT,
    blood_pressure    TEXT,
    heart_rate        TEXT,
    daily_steps       TEXT,
    sleep_disorder    TEXT
);

-- psql alternative to the pgAdmin import wizard:
-- \copy raw_sleep FROM 'data/raw_sleep_health.csv' WITH (FORMAT csv, HEADER true);

-- Sanity check: expect 1,500 rows (1,501 if the header row was imported as data —
-- 02_clean.sql removes it).
SELECT COUNT(*) FROM raw_sleep;
SELECT * FROM raw_sleep LIMIT 5;
