"""
Week 2 query converted to SparkSQL: deduplicate game_details so there is one row
per (game_id, team_id, player_id).
"""
from pyspark.sql import SparkSession

QUERY = """
WITH numbered AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY game_id, team_id, player_id ORDER BY game_id) AS row_num
    FROM game_details
)
SELECT *
FROM numbered
WHERE row_num = 1
"""


def do_dedupe_game_details(spark, dataframe):
    dataframe.createOrReplaceTempView("game_details")
    return spark.sql(QUERY).drop("row_num")


def main():
    spark = SparkSession.builder.master("local").appName("dedupe_game_details").getOrCreate()
    output_df = do_dedupe_game_details(spark, spark.table("game_details"))
    output_df.write.mode("overwrite").insertInto("game_details_deduped")
