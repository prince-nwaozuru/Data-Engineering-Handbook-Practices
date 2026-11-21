-- Helper: runs the cumulative load in 02_actors_cumulative_load.sql for every year
-- in the dataset (1970–2021), so the SCD queries have a full history to work with.

DO $$
DECLARE
    y INTEGER;
BEGIN
    FOR y IN (SELECT MIN(year) FROM actor_films)..(SELECT MAX(year) FROM actor_films) LOOP
        INSERT INTO actors
        WITH last_year AS (
            SELECT * FROM actors WHERE current_year = y - 1
        ),
        this_year AS (
            SELECT
                actorid,
                actor,
                year,
                ARRAY_AGG(ROW(film, votes, rating, filmid)::film_struct) AS films,
                AVG(rating) AS avg_rating
            FROM actor_films
            WHERE year = y
            GROUP BY actorid, actor, year
        )
        SELECT
            COALESCE(t.actorid, l.actorid),
            COALESCE(t.actor, l.actor),
            COALESCE(l.films, ARRAY[]::film_struct[]) || COALESCE(t.films, ARRAY[]::film_struct[]),
            CASE
                WHEN t.year IS NOT NULL THEN
                    CASE
                        WHEN t.avg_rating > 8 THEN 'star'
                        WHEN t.avg_rating > 7 THEN 'good'
                        WHEN t.avg_rating > 6 THEN 'average'
                        ELSE 'bad'
                    END::quality_class
                ELSE l.quality_class
            END,
            t.year IS NOT NULL,
            y
        FROM this_year t
        FULL OUTER JOIN last_year l ON t.actorid = l.actorid;
    END LOOP;
END $$;
