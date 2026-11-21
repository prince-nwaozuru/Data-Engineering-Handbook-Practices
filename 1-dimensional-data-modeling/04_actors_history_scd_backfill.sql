-- 4. Backfill: builds the whole `actors_history_scd` table in one query, as of 2020.
-- Approach: flag every year where quality_class or is_active changed, turn the running
-- sum of those flags into a "streak" id, then collapse each streak into one row.

INSERT INTO actors_history_scd
WITH with_previous AS (
    SELECT
        actorid,
        actor,
        current_year,
        quality_class,
        is_active,
        LAG(quality_class) OVER (PARTITION BY actorid ORDER BY current_year) AS previous_quality_class,
        LAG(is_active)     OVER (PARTITION BY actorid ORDER BY current_year) AS previous_is_active
    FROM actors
    WHERE current_year <= 2020
),
with_change_flag AS (
    SELECT
        *,
        CASE
            WHEN quality_class IS DISTINCT FROM previous_quality_class THEN 1
            WHEN is_active     IS DISTINCT FROM previous_is_active     THEN 1
            ELSE 0
        END AS change_flag
    FROM with_previous
),
with_streaks AS (
    SELECT
        *,
        SUM(change_flag) OVER (PARTITION BY actorid ORDER BY current_year) AS streak_id
    FROM with_change_flag
)
SELECT
    actorid,
    MAX(actor)          AS actor,
    quality_class,
    is_active,
    MIN(current_year)   AS start_date,
    MAX(current_year)   AS end_date,
    2020                AS current_year
FROM with_streaks
GROUP BY actorid, streak_id, quality_class, is_active
ORDER BY actorid, start_date;
