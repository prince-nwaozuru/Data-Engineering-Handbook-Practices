-- 1. Deduplicate game_details: keep one row per (game_id, team_id, player_id).
-- The raw table has 246,043 rows but only 245,754 unique player-game-team combinations.

WITH deduped AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id ORDER BY game_id) AS row_num
    FROM game_details
)
SELECT *
FROM deduped
WHERE row_num = 1;
