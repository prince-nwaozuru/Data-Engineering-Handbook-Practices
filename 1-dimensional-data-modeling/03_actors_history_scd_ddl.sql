-- 3. DDL for `actors_history_scd`: a Type 2 slowly changing dimension
-- Each row is a period during which an actor's quality_class and is_active stayed the same.
-- The dataset is yearly, so the start and end of each period are years.

CREATE TABLE actors_history_scd (
    actorid       TEXT,
    actor         TEXT,
    quality_class quality_class,
    is_active     BOOLEAN,
    start_date    INTEGER,  -- first year of this version
    end_date      INTEGER,  -- last year of this version
    current_year  INTEGER,  -- the snapshot year this SCD was built as of
    PRIMARY KEY (actorid, start_date, current_year)
);
