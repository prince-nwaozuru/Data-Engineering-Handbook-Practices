# Data Engineering Bootcamp Practice

My working copy of the free **DataExpert.io Data Engineering Bootcamp** materials, which I used to practise data modelling, Spark, Flink/Kafka streaming and data quality.

> **Credit:** The course outline, lecture labs, datasets and homework prompts in `materials/` were created by [DataExpert.io](https://www.dataexpert.io) (Zach Wilson) and come from the public [Data Engineer Handbook](https://github.com/DataExpert-io/data-engineer-handbook) repository. They are not my original work. This repo records my practice with them; the Spark notebooks in `materials/3-spark-fundamentals/notebooks/` include my own runs.

## Modules covered

| Module | Topics |
|---|---|
| 1. Dimensional data modelling | Cumulative tables, slowly changing dimensions (SCD Type 2), incremental SCD loads, graph data modelling |
| 2. Fact data modelling | Fact tables, date-list and bitmask patterns, monthly array metrics |
| 3. Spark fundamentals | PySpark DataFrames, joins, bucketing, partitioning, testing Spark jobs |
| 4. Apache Flink training | Real-time pipelines with Kafka, PyFlink and PostgreSQL in Docker |
| 4. Applying analytical patterns | Growth accounting, funnels, window functions |
| 5. KPIs and experimentation | Metric design and A/B testing |
| 6. Data impact and pipeline maintenance | Data visualisation, runbooks and on-call for pipelines |

## Running the labs

Each module has its own README with setup steps. Most modules run locally with Docker Compose: copy `example.env` to `.env` and run `make up` or `docker compose up`.
