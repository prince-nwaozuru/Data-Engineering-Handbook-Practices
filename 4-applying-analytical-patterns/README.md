# 4. Applying Analytical Patterns: NBA Data

Uses the `players`, `game_details` and `games` tables from week 1.

| File | Pattern |
|---|---|
| `01_player_state_tracking.sql` | State change tracking with `LAG`: New, Retired, Continued Playing, Returned from Retirement, Stayed Retired |
| `02_game_details_grouping_sets.sql` | One `GROUPING SETS` pass over (player, team), (player, season) and (team), saved as a dashboard table |
| `03_window_functions.sql` | A rolling 90-game window, and a gaps-and-islands scoring streak |

## Results (bootcamp dataset)

| Question | Answer |
|---|---|
| Most points for one team | Giannis Antetokounmpo, Milwaukee (15,556) |
| Most points in one season | James Harden, 2018 season (3,247) |
| Team with the most wins | Golden State Warriors (445) |
| Most wins in a 90-game stretch | Golden State Warriors (77) |
| LeBron James's longest streak of games over 10 points | 134 games in a row (Oct 2016 – Jan 2018) |

These numbers cover only the games in the bootcamp dataset (mostly the 2015–2022 seasons, including playoffs), so they're smaller than career totals.

**State tracking check:** Michael Jordan shows as Retired in 1998, Stayed Retired in 1999–2000, Returned from Retirement in 2001, Continued Playing in 2002 and Retired again in 2003. That matches his real career.
