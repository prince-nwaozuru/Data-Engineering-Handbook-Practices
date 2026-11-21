-- 5. Incremental load: rolls `actors_history_scd` forward from 2020 to 2021 using only
-- last year's SCD and this year's `actors` snapshot, without rescanning all history.
-- Records fall into four groups:
--   historical : versions that already ended before last year; copied as-is
--   unchanged  : current versions whose attributes did not change; end_date is extended
--   changed    : current versions whose attributes changed; old version closed, new one opened
--   new        : actors appearing for the first time

CREATE TYPE scd_type AS (
    quality_class quality_class,
    is_active     BOOLEAN,
    start_date    INTEGER,
    end_date      INTEGER
);

INSERT INTO actors_history_scd
WITH last_year_scd AS (
    SELECT * FROM actors_history_scd
    WHERE current_year = 2020
      AND end_date = 2020
),
historical_scd AS (
    SELECT actorid, actor, quality_class, is_active, start_date, end_date
    FROM actors_history_scd
    WHERE current_year = 2020
      AND end_date < 2020
),
this_year_data AS (
    SELECT * FROM actors
    WHERE current_year = 2021
),
unchanged_records AS (
    SELECT
        t.actorid,
        t.actor,
        t.quality_class,
        t.is_active,
        l.start_date,
        t.current_year AS end_date
    FROM this_year_data t
    JOIN last_year_scd l
        ON t.actorid = l.actorid
    WHERE t.quality_class = l.quality_class
      AND t.is_active = l.is_active
),
changed_records AS (
    SELECT
        t.actorid,
        t.actor,
        UNNEST(ARRAY[
            ROW(l.quality_class, l.is_active, l.start_date, l.end_date)::scd_type,
            ROW(t.quality_class, t.is_active, t.current_year, t.current_year)::scd_type
        ]) AS records
    FROM this_year_data t
    JOIN last_year_scd l
        ON t.actorid = l.actorid
    WHERE t.quality_class IS DISTINCT FROM l.quality_class
       OR t.is_active IS DISTINCT FROM l.is_active
),
unnested_changed_records AS (
    SELECT
        actorid,
        actor,
        (records::scd_type).quality_class,
        (records::scd_type).is_active,
        (records::scd_type).start_date,
        (records::scd_type).end_date
    FROM changed_records
),
new_records AS (
    SELECT
        t.actorid,
        t.actor,
        t.quality_class,
        t.is_active,
        t.current_year AS start_date,
        t.current_year AS end_date
    FROM this_year_data t
    LEFT JOIN last_year_scd l
        ON t.actorid = l.actorid
    WHERE l.actorid IS NULL
)
SELECT *, 2021 AS current_year FROM (
    SELECT * FROM historical_scd
    UNION ALL
    SELECT * FROM unchanged_records
    UNION ALL
    SELECT * FROM unnested_changed_records
    UNION ALL
    SELECT * FROM new_records
) combined;
