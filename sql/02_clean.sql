-- =============================================================================
-- 02_clean.sql  —  Clean the staging table in place
-- =============================================================================
-- 1. Drop the header row that the import wizard loaded as data
-- 2. Split "systolic/diastolic" blood pressure into two INT columns
-- 3. Convert the remaining TEXT columns to proper numeric types
-- 4. Inspect the categorical columns before building dimension tables
-- =============================================================================

-- 1. Header row imported as data
DELETE FROM raw_sleep
WHERE person_id = 'Person ID';

SELECT COUNT(*) FROM raw_sleep;   -- expect 1500

-- 2. Blood pressure: "111/71.15" → systolic 111, diastolic 71
--    Preview the split first
SELECT blood_pressure,
       SPLIT_PART(blood_pressure, '/', 1)::numeric          AS systolic,
       ROUND(SPLIT_PART(blood_pressure, '/', 2)::numeric)   AS diastolic
FROM raw_sleep
LIMIT 10;

ALTER TABLE raw_sleep ADD COLUMN systolic  INT;
ALTER TABLE raw_sleep ADD COLUMN diastolic INT;

UPDATE raw_sleep
SET systolic  = SPLIT_PART(blood_pressure, '/', 1)::numeric,
    diastolic = ROUND(SPLIT_PART(blood_pressure, '/', 2)::numeric);

ALTER TABLE raw_sleep DROP COLUMN blood_pressure;

-- 3. Type conversions (TEXT → INTEGER / NUMERIC)
ALTER TABLE raw_sleep ALTER COLUMN age               TYPE INTEGER USING age::integer;
ALTER TABLE raw_sleep ALTER COLUMN sleep_duration    TYPE NUMERIC USING sleep_duration::numeric;
ALTER TABLE raw_sleep ALTER COLUMN quality_of_sleep  TYPE INTEGER USING quality_of_sleep::integer;
ALTER TABLE raw_sleep ALTER COLUMN physical_activity TYPE INTEGER USING physical_activity::integer;
ALTER TABLE raw_sleep ALTER COLUMN stress_level      TYPE INTEGER USING stress_level::integer;
ALTER TABLE raw_sleep ALTER COLUMN heart_rate        TYPE INTEGER USING heart_rate::integer;
ALTER TABLE raw_sleep ALTER COLUMN daily_steps       TYPE INTEGER USING daily_steps::integer;

-- 4. Inspect categoricals — these become the dimension tables in 03_normalize.sql
SELECT DISTINCT bmi_category   FROM raw_sleep;   -- Underweight / Normal / Overweight / Obese
SELECT DISTINCT sleep_disorder FROM raw_sleep;   -- None / Insomnia / Sleep Apnea / RLS / Narcolepsy
SELECT DISTINCT gender         FROM raw_sleep;   -- Male / Female
SELECT COUNT(DISTINCT occupation) FROM raw_sleep; -- 15

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'raw_sleep'
ORDER BY ordinal_position;
