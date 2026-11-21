-- 1. State change tracking for players.
-- Compares each season's is_active flag with the previous season's for the same player:
--   first season seen         -> New
--   active   -> inactive      -> Retired
--   active   -> active        -> Continued Playing
--   inactive -> active        -> Returned from Retirement
--   inactive -> inactive      -> Stayed Retired

WITH with_previous AS (
    SELECT
        player_name,
        current_season,
        is_active,
        LAG(is_active) OVER (PARTITION BY player_name ORDER BY current_season) AS was_active
    FROM players
)
SELECT
    player_name,
    current_season,
    CASE
        WHEN was_active IS NULL AND is_active  THEN 'New'
        WHEN was_active AND NOT is_active      THEN 'Retired'
        WHEN was_active AND is_active          THEN 'Continued Playing'
        WHEN NOT was_active AND is_active      THEN 'Returned from Retirement'
        ELSE 'Stayed Retired'
    END AS player_state
FROM with_previous
ORDER BY player_name, current_season;
