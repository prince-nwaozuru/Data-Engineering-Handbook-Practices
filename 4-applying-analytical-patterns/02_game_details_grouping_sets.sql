-- 2. GROUPING SETS: one pass over game_details that aggregates at three levels at once:
--    (player, team), (player, season) and (team).
-- The result is saved as a table so the questions below can be answered from it.

CREATE TABLE game_details_dashboard AS
WITH deduped AS (
    SELECT
        gd.*,
        g.season,
        -- did this player's team win the game?
        CASE
            WHEN gd.team_id = g.home_team_id    THEN g.home_team_wins = 1
            WHEN gd.team_id = g.visitor_team_id THEN g.home_team_wins = 0
        END AS team_won,
        ROW_NUMBER() OVER (PARTITION BY gd.game_id, gd.team_id, gd.player_id ORDER BY gd.game_id) AS row_num
    FROM game_details gd
    JOIN games g
        ON gd.game_id = g.game_id
)
SELECT
    CASE
        WHEN GROUPING(player_name) = 0 AND GROUPING(team_abbreviation) = 0 THEN 'player__team'
        WHEN GROUPING(player_name) = 0 AND GROUPING(season) = 0            THEN 'player__season'
        WHEN GROUPING(team_abbreviation) = 0                               THEN 'team'
    END AS aggregation_level,
    COALESCE(player_name, '(overall)')       AS player_name,
    COALESCE(team_abbreviation, '(overall)') AS team,
    season,
    SUM(COALESCE(pts, 0))                    AS total_points,
    COUNT(DISTINCT CASE WHEN team_won THEN game_id END) AS games_won
FROM deduped
WHERE row_num = 1
GROUP BY GROUPING SETS (
    (player_name, team_abbreviation),
    (player_name, season),
    (team_abbreviation)
);

-- Who scored the most points playing for one team?
SELECT player_name, team, total_points
FROM game_details_dashboard
WHERE aggregation_level = 'player__team'
ORDER BY total_points DESC
LIMIT 1;

-- Who scored the most points in one season?
SELECT player_name, season, total_points
FROM game_details_dashboard
WHERE aggregation_level = 'player__season'
ORDER BY total_points DESC
LIMIT 1;

-- Which team has won the most games?
SELECT team, games_won
FROM game_details_dashboard
WHERE aggregation_level = 'team'
ORDER BY games_won DESC
LIMIT 1;
