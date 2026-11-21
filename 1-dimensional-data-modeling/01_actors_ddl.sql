-- 1. DDL for the cumulative `actors` table
-- One row per actor per year. `films` accumulates every film the actor has made up to `current_year`.

CREATE TYPE film_struct AS (
    film   TEXT,
    votes  INTEGER,
    rating REAL,
    filmid TEXT
);

CREATE TYPE quality_class AS ENUM ('star', 'good', 'average', 'bad');

CREATE TABLE actors (
    actorid       TEXT,
    actor         TEXT,
    films         film_struct[],
    quality_class quality_class,  -- based on the average rating of the actor's most recent year of films
    is_active     BOOLEAN,        -- true if the actor released a film in current_year
    current_year  INTEGER,
    PRIMARY KEY (actorid, current_year)
);
