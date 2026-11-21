# Data Engineering Bootcamp: Homework Solutions

My solutions to the homework assignments from the free [DataExpert.io Data Engineering Bootcamp](https://github.com/DataExpert-io/data-engineer-handbook). The assignment prompts and datasets belong to DataExpert.io; this repo contains only the solutions.

| Module | What it covers | Stack | Tested |
|---|---|---|---|
| [1. Dimensional data modelling](1-dimensional-data-modeling) | Cumulative table design, Type 2 SCD backfill and incremental loads | PostgreSQL | ✅ Run against the bootcamp dataset |
| [2. Fact data modelling](2-fact-data-modeling) | Deduplication, cumulative date lists, bitmask `datelist_int`, monthly reduced fact table | PostgreSQL | ✅ Run day by day for January 2023 |
| [3. Spark fundamentals](3-spark-fundamentals) | Bucket joins, explicit broadcast joins, `sortWithinPartitions` experiment, PySpark jobs with unit tests | PySpark, pytest, chispa | Written for the course's Spark setup |
| [4. Apache Flink](4-apache-flink) | Session windows over a Kafka stream (5-minute gap), per-host analysis | PyFlink, Kafka, PostgreSQL | Written for the course's Flink setup |
| [4. Applying analytical patterns](4-applying-analytical-patterns) | State change tracking, `GROUPING SETS`, rolling windows, gaps and islands | PostgreSQL | ✅ Run against the bootcamp dataset |
| [6. Data pipeline maintenance](6-data-pipeline-maintenance) | Pipeline ownership, a fair on-call rotation, runbooks for investor-facing pipelines | Markdown | n/a |

## Running the SQL

The SQL modules use the bootcamp's Postgres dataset. Follow the [module 1 setup](https://github.com/DataExpert-io/data-engineer-handbook/tree/main/intermediate-bootcamp/materials/1-dimensional-data-modeling) to start Postgres and restore `data.dump`, then run each module's files in numbered order.
