-- 3. Window functions on game_details.

-- 3a. Most games a team has won in any 90-game stretch.
-- One row per team per game, then a rolling 90-game sum of wins.
WITH team_games AS (
    SELECT DISTINCT
        gd.team_abbreviation AS team,
        g.game_id,
        g.game_date_est,
        CASE
            WHEN gd.team_id = g.home_team_id    THEN g.home_team_wins
            WHEN gd.team_id = g.visitor_team_id THEN 1 - g.home_team_wins
        END AS won
    FROM game_details gd
    JOIN games g
        ON gd.game_id = g.game_id
),
rolling AS (
    SELECT
        team,
        game_date_est,
        SUM(won) OVER (
            PARTITION BY team
            ORDER BY game_date_est, game_id
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS wins_in_last_90_games
    FROM team_games
)
SELECT team, MAX(wins_in_last_90_games) AS most_wins_in_90_games
FROM rolling
GROUP BY team
ORDER BY most_wins_in_90_games DESC
LIMIT 1;

-- 3b. Longest run of consecutive games in which LeBron James scored more than 10 points.
-- Gaps-and-islands: a new streak starts every time he fails to score over 10,
-- so a running count of those failures gives each streak its own id.
WITH lebron_games AS (
    SELECT DISTINCT
        g.game_id,
        g.game_date_est,
        gd.pts
    FROM game_details gd
    JOIN games g
        ON gd.game_id = g.game_id
    WHERE gd.player_name = 'LeBron James'
      AND gd.pts IS NOT NULL  -- skip games he did not play (DNP rows have no points)
),
flagged AS (
    SELECT
        *,
        SUM(CASE WHEN pts > 10 THEN 0 ELSE 1 END)
            OVER (ORDER BY game_date_est, game_id) AS streak_id
    FROM lebron_games
)
SELECT
    MIN(game_date_est) AS streak_start,
    MAX(game_date_est) AS streak_end,
    COUNT(*)           AS games_in_a_row_over_10_points
FROM flagged
WHERE pts > 10
GROUP BY streak_id
ORDER BY games_in_a_row_over_10_points DESC
LIMIT 1;
