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
SELECT COUNT(*) FROM raw_sleep;

SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT COUNT(*) FROM person;
SELECT COUNT(*) FROM sleepdata;

-- ============ PERSON (hub) ============
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

-- ============ LIFESTYLEDATA (fact) ============
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

-- ============ HEALTHMETRICS (fact) ============
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

-- ============ SLEEPDATA (fact, with disorder JOIN) ============
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

-- ============ QUERY 1: avg sleep by occupation ============
SELECT o.occupation_name, ROUND(AVG(s.sleep_duration), 2) AS avg_sleep
FROM person p
JOIN occupation o ON p.occupation_id = o.occupation_id
JOIN sleepdata s  ON p.person_id     = s.person_id
GROUP BY o.occupation_name
ORDER BY avg_sleep DESC;

-- ============ QUERY 2: sleep quality by activity band ============
SELECT 
    CASE 
        WHEN l.physical_activity < 40 THEN 'Low'
        WHEN l.physical_activity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS activity_band,
    ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY activity_band
ORDER BY avg_sleep_quality;

-- ============ QUERY 3: sleep duration by stress band ============
SELECT 
    CASE 
        WHEN l.stress_level BETWEEN 7 AND 10 THEN 'High'
        WHEN l.stress_level BETWEEN 4 AND 6 THEN 'Medium'
        ELSE 'Low'
    END AS stress_band,
    ROUND(AVG(s.sleep_duration), 2) AS avg_sleep_duration
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY stress_band
ORDER BY avg_sleep_duration DESC;
SELECT * FROM raw_sleep LIMIT 5;

DELETE FROM raw_sleep
WHERE person_id = 'Person ID';

SELECT COUNT(*) FROM raw_sleep;

SELECT blood_pressure
FROM raw_sleep
LIMIT 10;

SELECT 
    blood_pressure,
    SPLIT_PART(blood_pressure, '/', 1)::numeric AS systolic,
    ROUND(SPLIT_PART(blood_pressure, '/', 2)::numeric) AS diastolic
FROM raw_sleep
LIMIT 10;

ALTER TABLE raw_sleep ADD COLUMN systolic INT;
ALTER TABLE raw_sleep ADD COLUMN diastolic INT;

UPDATE raw_sleep
SET systolic  = SPLIT_PART(blood_pressure, '/', 1)::numeric,
    diastolic = ROUND(SPLIT_PART(blood_pressure, '/', 2)::numeric);

SELECT blood_pressure, systolic, diastolic
FROM raw_sleep
LIMIT 10;

ALTER TABLE raw_sleep DROP COLUMN blood_pressure;

SELECT systolic, diastolic FROM raw_sleep LIMIT 5;

SELECT age, sleep_duration, quality_of_sleep, heart_rate, daily_steps
FROM raw_sleep
LIMIT 5;

ALTER TABLE raw_sleep ALTER COLUMN age TYPE INTEGER USING age::integer;
ALTER TABLE raw_sleep ALTER COLUMN sleep_duration TYPE NUMERIC USING sleep_duration::numeric;
ALTER TABLE raw_sleep ALTER COLUMN quality_of_sleep TYPE INTEGER USING quality_of_sleep::integer;
ALTER TABLE raw_sleep ALTER COLUMN physical_activity TYPE INTEGER USING physical_activity::integer;
ALTER TABLE raw_sleep ALTER COLUMN stress_level TYPE INTEGER USING stress_level::integer;
ALTER TABLE raw_sleep ALTER COLUMN heart_rate TYPE INTEGER USING heart_rate::integer;
ALTER TABLE raw_sleep ALTER COLUMN daily_steps TYPE INTEGER USING daily_steps::integer;

SELECT age, sleep_duration, quality_of_sleep, heart_rate
FROM raw_sleep
LIMIT 5;

SELECT DISTINCT bmi_category FROM raw_sleep;
SELECT DISTINCT sleep_disorder FROM raw_sleep;
SELECT DISTINCT gender FROM raw_sleep;

DROP TABLE IF EXISTS occupation CASCADE;

CREATE TABLE occupation (
    occupation_id   SERIAL PRIMARY KEY,
    occupation_name VARCHAR(50) UNIQUE
);

INSERT INTO occupation (occupation_name)
SELECT DISTINCT occupation
FROM raw_sleep
ORDER BY occupation;

SELECT * FROM occupation;

DROP TABLE IF EXISTS sleepdisorder CASCADE;

CREATE TABLE sleepdisorder (
    disorder_id   SERIAL PRIMARY KEY,
    disorder_name VARCHAR(50) UNIQUE
);
INSERT INTO sleepdisorder (disorder_name)
SELECT DISTINCT sleep_disorder
FROM raw_sleep
ORDER BY sleep_disorder;
SELECT * FROM sleepdisorder;

SELECT column_name FROM information_schema.columns
WHERE table_name = 'raw_sleep'
ORDER BY ordinal_position;

SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT COUNT(*) FROM raw_sleep;
SELECT COUNT(*) FROM person;
SELECT COUNT(*) FROM sleepdata;
SELECT COUNT(*) FROM lifestyledata;
SELECT COUNT(*) FROM healthmetrics;

SELECT * FROM raw_sleep LIMIT 5;

SELECT 'raw_sleep' AS tbl, COUNT(*) FROM raw_sleep
UNION ALL SELECT 'occupation', COUNT(*) FROM occupation
UNION ALL SELECT 'sleepdisorder', COUNT(*) FROM sleepdisorder
UNION ALL SELECT 'person', COUNT(*) FROM person
UNION ALL SELECT 'sleepdata', COUNT(*) FROM sleepdata
UNION ALL SELECT 'lifestyledata', COUNT(*) FROM lifestyledata
UNION ALL SELECT 'healthmetrics', COUNT(*) FROM healthmetrics;


SELECT *
FROM healthmetrics;
SELECT*
FROM sleepdata;
SELECT*
FROM sleepdisorder;

SELECT h.bmi_category, ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality
FROM sleepdata s
JOIN healthmetrics h ON s.person_id = h.person_id
GROUP BY h.bmi_category
ORDER BY avg_sleep_quality;

SELECT sd.disorder_name,
       ROUND(AVG(h.heart_rate), 1) AS avg_heart_rate
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN healthmetrics h  ON s.person_id   = h.person_id
GROUP BY sd.disorder_name
ORDER BY avg_heart_rate DESC;

SELECT sd.disorder_name,
       ROUND(AVG(l.daily_steps), 0) AS avg_daily_steps
FROM sleepdata s
JOIN sleepdisorder sd  ON s.disorder_id = sd.disorder_id
JOIN lifestyledata l   ON s.person_id   = l.person_id
GROUP BY sd.disorder_name
ORDER BY avg_daily_steps;

SELECT* 
FROM lifestyledata
ORDER BY physical_activity DESC;

SELECT physical_activity, ROUND(AVG(stress_level), 2) AS avg_stress
FROM lifestyledata
GROUP BY physical_activity

SELECT 
    CASE 
        WHEN physical_activity < 40 THEN 'Low'
        WHEN physical_activity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS activity_band,
    ROUND(AVG(stress_level), 2) AS avg_stress
FROM lifestyledata
GROUP BY activity_band
ORDER BY avg_stress DESC;

SELECT*
FROM occupation, sleepdis
ORDER BY avg_stress;

SELECT o.occupation_name,
       COUNT(*) AS disorder_count
FROM sleepdata s
JOIN sleepdisorder d ON s.disorder_id  = d.disorder_id
JOIN person p        ON s.person_id    = p.person_id
JOIN occupation o    ON p.occupation_id = o.occupation_id
WHERE d.disorder_name <> 'None'
GROUP BY o.occupation_name
ORDER BY disorder_count DESC;

SELECT*
FROM occupation, sleepdata;

#QUERY 1

SELECT o.occupation_name, ROUND(AVG(s.sleep_duration), 2) AS avg_sleep
FROM person p
JOIN occupation o ON p.occupation_id = o.occupation_id
JOIN sleepdata s  ON p.person_id     = s.person_id
GROUP BY o.occupation_name
ORDER BY avg_sleep DESC;

SELECT COUNT(DISTINCT physical_activity) FROM lifestyledata;

SELECT COUNT(DISTINCT stress_level) FROM lifestyledata;
SELECT COUNT(DISTINCT bmi_category) FROM healthmetrics;

#QUERY 2
SELECT 
    CASE 
        WHEN l.physical_activity < 40 THEN 'Low'
        WHEN l.physical_activity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS activity_band,
    ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY activity_band
ORDER BY avg_sleep_quality;

#QUERY 3
SELECT 
    CASE 
        WHEN l.stress_level BETWEEN 7 AND 10 THEN 'High'
        WHEN l.stress_level BETWEEN 4 AND 6 THEN 'Medium'
        ELSE 'Low'
    END AS stress_band,
    ROUND(AVG(s.sleep_duration), 2) AS avg_sleep_duration
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY stress_band
ORDER BY avg_sleep_duration DESC;

#QUERY 4
SELECT h.bmi_category,
       ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality
FROM sleepdata s
JOIN healthmetrics h ON s.person_id = h.person_id
GROUP BY h.bmi_category
ORDER BY avg_sleep_quality DESC;

#QUERY 5
SELECT sd.disorder_name,
       ROUND(AVG(h.heart_rate), 1) AS avg_heart_rate
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN healthmetrics h  ON s.person_id   = h.person_id
GROUP BY sd.disorder_name
ORDER BY avg_heart_rate DESC;

#Query6
SELECT sd.disorder_name,
       ROUND(AVG(l.daily_steps), 0) AS avg_daily_steps
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN lifestyledata l  ON s.person_id   = l.person_id
GROUP BY sd.disorder_name
ORDER BY avg_daily_steps;

#Query 7
SELECT 
    CASE 
        WHEN physical_activity < 40 THEN 'Low'
        WHEN physical_activity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS activity_band,
    ROUND(AVG(stress_level), 2) AS avg_stress
FROM lifestyledata
GROUP BY activity_band
ORDER BY avg_stress DESC;

#Query 8
SELECT o.occupation_name, COUNT(*) AS disorder_count
FROM sleepdata s
JOIN sleepdisorder d ON s.disorder_id = d.disorder_id
JOIN person p        ON s.person_id = p.person_id
JOIN occupation o    ON p.occupation_id = o.occupation_id
WHERE d.disorder_name <> 'None'
GROUP BY o.occupation_name
ORDER BY disorder_count DESC;

#QUERY9
SELECT sd.disorder_name,
       COUNT(*) AS people
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
GROUP BY sd.disorder_name
ORDER BY people DESC;


#Query 10
Does more physical activity mean better sleep and less stress?


SELECT 
    CASE 
        WHEN l.physical_activity < 40 THEN 'Low'
        WHEN l.physical_activity BETWEEN 40 AND 70 THEN 'Medium'
        ELSE 'High'
    END AS activity_band,
    ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality,
    ROUND(AVG(l.stress_level), 2)   AS avg_stress
FROM lifestyledata l
JOIN sleepdata s ON l.person_id = s.person_id
GROUP BY activity_band;

--QUERY 12---
SELECT l.stress_level,
       ROUND(AVG(s.sleep_duration), 2) AS avg_sleep_duration
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY l.stress_level
ORDER BY l.stress_level;

--QUERY 13--
SELECT sd.disorder_name,
       ROUND(AVG(h.heart_rate), 1) AS avg_heart_rate,
       ROUND(AVG(l.daily_steps), 0) AS avg_daily_steps
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN healthmetrics h  ON s.person_id   = h.person_id
JOIN lifestyledata l  ON s.person_id   = l.person_id
GROUP BY sd.disorder_name
ORDER BY avg_heart_rate DESC;