-- 2. Cumulative load: populates `actors` one year at a time.
-- Combines yesterday's state (last year's snapshot) with today's data (this year's films).
-- Run once per year, changing the two year values. Example below loads 1971 on top of 1970.

INSERT INTO actors
WITH last_year AS (
    SELECT *
    FROM actors
    WHERE current_year = 1970
),
this_year AS (
    SELECT
        actorid,
        actor,
        year,
        ARRAY_AGG(ROW(film, votes, rating, filmid)::film_struct) AS films,
        AVG(rating) AS avg_rating
    FROM actor_films
    WHERE year = 1971
    GROUP BY actorid, actor, year
)
SELECT
    COALESCE(t.actorid, l.actorid) AS actorid,
    COALESCE(t.actor, l.actor)     AS actor,
    -- keep every past film and append this year's films
    COALESCE(l.films, ARRAY[]::film_struct[])
        || COALESCE(t.films, ARRAY[]::film_struct[]) AS films,
    -- quality reflects the most recent year with films, so carry it forward in inactive years
    CASE
        WHEN t.year IS NOT NULL THEN
            CASE
                WHEN t.avg_rating > 8 THEN 'star'
                WHEN t.avg_rating > 7 THEN 'good'
                WHEN t.avg_rating > 6 THEN 'average'
                ELSE 'bad'
            END::quality_class
        ELSE l.quality_class
    END AS quality_class,
    t.year IS NOT NULL AS is_active,
    1971 AS current_year
FROM this_year t
FULL OUTER JOIN last_year l
    ON t.actorid = l.actorid;
