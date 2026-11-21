# 3. Spark Fundamentals

## Part 1: Bucket joins and aggregation (`spark_homework_job.py`)

Uses the Halo dataset (`match_details`, `matches`, `medals_matches_players`, `medals`, `maps`).

1. Turns off automatic broadcasting: `spark.sql.autoBroadcastJoinThreshold = -1`.
2. Writes `match_details`, `matches` and `medals_matches_players` as tables **bucketed into 16 buckets on `match_id`**, so joining them on `match_id` needs no shuffle.
3. **Explicitly broadcasts** the small `medals` and `maps` lookup tables with `F.broadcast`.
4. Answers the questions. Each answer is computed at the right grain, because the medal join creates one row per medal and would otherwise inflate kills and match counts.
5. Writes the aggregated data with five different `sortWithinPartitions` orders and compares Parquet file sizes. Sorting by the low-cardinality columns (playlist, map) first should give the smallest files, because repeated values compress well with run-length and dictionary encoding.

```bash
spark-submit spark_homework_job.py --data-dir <path-to-bootcamp>/3-spark-fundamentals/data
```

**Expected answers.** I cross-checked these with SQL over the same CSV files:

| Question | Answer |
|---|---|
| Player with the most kills per game | `gimpinator14`, 109 kills per game (only one match played) |
| Most played playlist | `f72e0ef0-7c4a-4307-af78-8e38dac3fdba` (9,350 matches) |
| Most played map | Breakout Arena (8,587 matches) |
| Map with the most Killing Spree medals | Breakout Arena (6,744 medals) |

## Part 2: PySpark testing (`src/`)

Two queries from weeks 1–2 converted from PostgreSQL to SparkSQL, each with unit tests using fake input and expected output.

| Job | Converted from | Tests |
|---|---|---|
| `src/jobs/actors_scd_job.py` | Week 1 SCD backfill. `IS DISTINCT FROM` becomes Spark's null-safe `<=>`. | `src/tests/test_actors_scd.py`: change detection, inactive years, the as-of year cutoff |
| `src/jobs/dedupe_game_details_job.py` | Week 2 `game_details` deduplication | `src/tests/test_dedupe_game_details.py`: exact duplicates removed, unique rows untouched |

```bash
pip install -r requirements.txt
python -m pytest src/tests
```
