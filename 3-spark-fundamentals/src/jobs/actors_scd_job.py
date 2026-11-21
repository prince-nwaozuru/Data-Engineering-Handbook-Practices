"""
Week 1 query converted to SparkSQL: backfill of the actors_history_scd Type 2 table.
Input:  `actors` (one row per actor per year with quality_class and is_active)
Output: one row per unbroken period of the same quality_class and is_active.
"""
from pyspark.sql import SparkSession

QUERY = """
WITH with_previous AS (
    SELECT
        actorid,
        actor,
        current_year,
        quality_class,
        is_active,
        LAG(quality_class) OVER (PARTITION BY actorid ORDER BY current_year) AS previous_quality_class,
        LAG(is_active)     OVER (PARTITION BY actorid ORDER BY current_year) AS previous_is_active
    FROM actors
    WHERE current_year <= {as_of_year}
),
with_change_flag AS (
    SELECT
        *,
        CASE
            WHEN NOT (quality_class <=> previous_quality_class) THEN 1
            WHEN NOT (is_active <=> previous_is_active)         THEN 1
            ELSE 0
        END AS change_flag
    FROM with_previous
),
with_streaks AS (
    SELECT
        *,
        SUM(change_flag) OVER (PARTITION BY actorid ORDER BY current_year) AS streak_id
    FROM with_change_flag
)
SELECT
    actorid,
    MAX(actor)        AS actor,
    quality_class,
    is_active,
    MIN(current_year) AS start_date,
    MAX(current_year) AS end_date,
    {as_of_year}      AS current_year
FROM with_streaks
GROUP BY actorid, streak_id, quality_class, is_active
"""


def do_actors_scd_transformation(spark, dataframe, as_of_year):
    dataframe.createOrReplaceTempView("actors")
    return spark.sql(QUERY.format(as_of_year=int(as_of_year)))


def main():
    spark = SparkSession.builder.master("local").appName("actors_scd").getOrCreate()
    output_df = do_actors_scd_transformation(spark, spark.table("actors"), 2020)
    output_df.write.mode("overwrite").insertInto("actors_history_scd")
