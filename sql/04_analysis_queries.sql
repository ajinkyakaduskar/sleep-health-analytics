-- =============================================================================
-- 04_analysis_queries.sql  —  The 12 queries behind the Tableau charts
-- =============================================================================
-- Each query was run in pgAdmin, exported to CSV (data/query_results/), and
-- loaded into Tableau Public. Chart type and README section noted per query.
-- Q5, Q6, Q7 also feed the two-measure charts Q10 and Q13.
-- =============================================================================


-- Q1 · Which occupations sleep the most on average?          → colour-encoded bar
SELECT o.occupation_name,
       ROUND(AVG(s.sleep_duration), 2) AS avg_sleep
FROM person p
JOIN occupation o ON p.occupation_id = o.occupation_id
JOIN sleepdata  s ON p.person_id     = s.person_id
GROUP BY o.occupation_name
ORDER BY avg_sleep DESC;


-- Q2 · Does more physical activity improve sleep quality?     → bar (ordinal bands)
SELECT CASE WHEN l.physical_activity < 40 THEN 'Low'
            WHEN l.physical_activity BETWEEN 40 AND 70 THEN 'Medium'
            ELSE 'High' END                   AS activity_band,
       ROUND(AVG(s.sleep_quality), 2)         AS avg_sleep_quality
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY activity_band
ORDER BY avg_sleep_quality;


-- Q3 · Do stressed people sleep less?                         → bar (ordinal bands)
SELECT CASE WHEN l.stress_level BETWEEN 7 AND 10 THEN 'High'
            WHEN l.stress_level BETWEEN 4 AND 6  THEN 'Medium'
            ELSE 'Low' END                    AS stress_band,
       ROUND(AVG(s.sleep_duration), 2)        AS avg_sleep_duration
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY stress_band
ORDER BY avg_sleep_duration DESC;


-- Q4 · Does BMI affect sleep quality?                         → bar (ordinal)
SELECT h.bmi_category,
       ROUND(AVG(s.sleep_quality), 2) AS avg_sleep_quality
FROM sleepdata s
JOIN healthmetrics h ON s.person_id = h.person_id
GROUP BY h.bmi_category
ORDER BY avg_sleep_quality DESC;


-- Q5 · Average resting heart rate by sleep disorder           → bar; also feeds Q13
SELECT sd.disorder_name,
       ROUND(AVG(h.heart_rate), 1) AS avg_heart_rate
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN healthmetrics h  ON s.person_id   = h.person_id
GROUP BY sd.disorder_name
ORDER BY avg_heart_rate DESC;


-- Q6 · Average daily steps by sleep disorder                  → bar; also feeds Q13
SELECT sd.disorder_name,
       ROUND(AVG(l.daily_steps), 0) AS avg_daily_steps
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN lifestyledata l  ON s.person_id   = l.person_id
GROUP BY sd.disorder_name
ORDER BY avg_daily_steps;


-- Q7 · Does physical activity reduce stress?                  → bar; also feeds Q10
SELECT CASE WHEN physical_activity < 40 THEN 'Low'
            WHEN physical_activity BETWEEN 40 AND 70 THEN 'Medium'
            ELSE 'High' END                   AS activity_band,
       ROUND(AVG(stress_level), 2)            AS avg_stress
FROM lifestyledata
GROUP BY activity_band
ORDER BY avg_stress DESC;


-- Q8 · Which occupations report the most sleep disorders?     → packed bubbles
--      'None' is excluded so the count is people WITH a disorder.
SELECT o.occupation_name,
       COUNT(*) AS disorder_count
FROM sleepdata s
JOIN sleepdisorder d ON s.disorder_id   = d.disorder_id
JOIN person p        ON s.person_id     = p.person_id
JOIN occupation o    ON p.occupation_id = o.occupation_id
WHERE d.disorder_name <> 'None'
GROUP BY o.occupation_name
ORDER BY disorder_count DESC;


-- Q9 · What share of people have a sleep disorder?            → pie (parts of a whole)
--      'None' is INCLUDED here — the pie needs the full population to sum to 100%.
SELECT sd.disorder_name,
       COUNT(*) AS people
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
GROUP BY sd.disorder_name
ORDER BY people DESC;


-- Q10 · Does more activity mean better sleep AND less stress?  → side-by-side bar
--       Q2 + Q7 merged: one GROUP BY, two aggregates. Both measures on a 1–10 scale.
SELECT CASE WHEN l.physical_activity < 40 THEN 'Low'
            WHEN l.physical_activity BETWEEN 40 AND 70 THEN 'Medium'
            ELSE 'High' END                   AS activity_band,
       ROUND(AVG(s.sleep_quality), 2)         AS avg_sleep_quality,
       ROUND(AVG(l.stress_level), 2)          AS avg_stress
FROM lifestyledata l
JOIN sleepdata s ON l.person_id = s.person_id
GROUP BY activity_band;


-- Q12 · How does sleep duration change as stress rises?       → line (1–10, unbanded)
--       Same relationship as Q3 but at full resolution — the banding is dropped.
SELECT l.stress_level,
       ROUND(AVG(s.sleep_duration), 2) AS avg_sleep_duration
FROM sleepdata s
JOIN lifestyledata l ON s.person_id = l.person_id
GROUP BY l.stress_level
ORDER BY l.stress_level;


-- Q13 · Do sleep disorders show up in heart rate and steps?   → dual-axis (bar + line)
--       Q5 + Q6 merged. Scales differ (~75 bpm vs ~6,000 steps) so Tableau needs
--       two independent axes, not a shared one.
SELECT sd.disorder_name,
       ROUND(AVG(h.heart_rate), 1)  AS avg_heart_rate,
       ROUND(AVG(l.daily_steps), 0) AS avg_daily_steps
FROM sleepdata s
JOIN sleepdisorder sd ON s.disorder_id = sd.disorder_id
JOIN healthmetrics h  ON s.person_id   = h.person_id
JOIN lifestyledata l  ON s.person_id   = l.person_id
GROUP BY sd.disorder_name
ORDER BY avg_heart_rate DESC;
