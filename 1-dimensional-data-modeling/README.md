# 1. Dimensional Data Modelling: Actors

Models the `actor_films` dataset (1970–2021) as a cumulative table and a Type 2 slowly changing dimension.

| File | Task |
|---|---|
| `01_actors_ddl.sql` | `actors` table with a `films` array of structs, a `quality_class` enum and `is_active` |
| `02_actors_cumulative_load.sql` | Loads one year at a time: last year's snapshot `FULL OUTER JOIN` this year's films |
| `02b_actors_load_all_years.sql` | Helper that runs the yearly load for every year in the dataset |
| `03_actors_history_scd_ddl.sql` | `actors_history_scd` Type 2 table with `start_date` and `end_date` |
| `04_actors_history_scd_backfill.sql` | Builds the whole SCD in one query, using `LAG` change flags and running-sum streak ids |
| `05_actors_history_scd_incremental.sql` | Rolls the SCD forward one year by combining historical, unchanged, changed and new records |

## Design decisions

- **`quality_class` is carried forward** in years an actor makes no films, because the definition is "the average rating of their most recent year". `is_active` becomes false in those years.
- **The cumulative table only appends.** Each year's `films` array is last year's array plus this year's films, so no history is rescanned.
- **The incremental SCD only reads last year's SCD and this year's snapshot.** Unchanged versions have their `end_date` extended. Changed versions are closed and a new version opened, using `UNNEST` on an array of two records.

## Verification

- After loading all 52 years, every actor's `films` array matches their row count in `actor_films`.
- The 2021 SCD built **incrementally** from the 2020 SCD is identical to a **full backfill** run as of 2021: 119,331 rows, with zero differences in either direction.
- No actor has overlapping SCD periods.
