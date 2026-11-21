"""
Week 3 Spark homework: broadcast joins, bucket joins and aggregation on the Halo match data.

Steps
1. Turn off automatic broadcast joins so every join strategy is chosen explicitly.
2. Write match_details, matches and medals_matches_players as tables bucketed into
   16 buckets on match_id, so joining them on match_id needs no shuffle.
3. Explicitly broadcast the two small dimension tables, medals and maps.
4. Answer the four questions from the joined data.
5. Compare file sizes for different .sortWithinPartitions orders.

Run with:  spark-submit spark_homework_job.py --data-dir ../data
"""
import argparse
import os

from pyspark.sql import SparkSession, DataFrame
from pyspark.sql import functions as F

NUM_BUCKETS = 16


def get_spark() -> SparkSession:
    spark = SparkSession.builder.appName("halo_bucket_join_homework").getOrCreate()
    # 1. No automatic broadcasting: we decide which joins broadcast.
    spark.conf.set("spark.sql.autoBroadcastJoinThreshold", "-1")
    return spark


def read_csv(spark: SparkSession, data_dir: str, name: str) -> DataFrame:
    return spark.read.option("header", "true").option("inferSchema", "true").csv(
        os.path.join(data_dir, f"{name}.csv")
    )


def write_bucketed(df: DataFrame, table_name: str) -> None:
    """2. Save a table bucketed (and sorted) on match_id."""
    (
        df.write.mode("overwrite")
        .bucketBy(NUM_BUCKETS, "match_id")
        .sortBy("match_id")
        .saveAsTable(table_name)
    )


def build_joined(spark: SparkSession, data_dir: str) -> DataFrame:
    match_details = read_csv(spark, data_dir, "match_details").select(
        "match_id", "player_gamertag", "player_total_kills", "player_total_deaths"
    )
    matches = read_csv(spark, data_dir, "matches").select(
        "match_id", "mapid", "playlist_id", "completion_date"
    )
    medals_matches_players = read_csv(spark, data_dir, "medals_matches_players").select(
        "match_id", "player_gamertag", "medal_id", "count"
    )
    medals = read_csv(spark, data_dir, "medals").select(
        "medal_id", F.col("name").alias("medal_name")
    )
    maps = read_csv(spark, data_dir, "maps").select(
        "mapid", F.col("name").alias("map_name")
    )

    write_bucketed(match_details, "bucketed_match_details")
    write_bucketed(matches, "bucketed_matches")
    write_bucketed(medals_matches_players, "bucketed_medals_matches_players")

    md = spark.table("bucketed_match_details")
    m = spark.table("bucketed_matches")
    mmp = spark.table("bucketed_medals_matches_players")

    # Bucket joins on match_id: both sides share the same 16-bucket layout, so no shuffle.
    player_matches = md.join(m, on="match_id", how="inner")
    joined = player_matches.join(
        mmp, on=["match_id", "player_gamertag"], how="left"
    )

    # 3. Explicit broadcast joins for the small lookup tables.
    joined = joined.join(F.broadcast(medals), on="medal_id", how="left")
    joined = joined.join(F.broadcast(maps), on="mapid", how="left")
    return joined


def answer_questions(joined: DataFrame) -> dict:
    """4. Each answer is computed at the right grain, because the medal join
    creates one row per medal, which would otherwise inflate the counts."""
    player_match = joined.select(
        "match_id", "player_gamertag", "player_total_kills"
    ).distinct()
    match_level = joined.select("match_id", "playlist_id", "mapid", "map_name").distinct()

    most_kills_per_game = (
        player_match.groupBy("player_gamertag")
        .agg(F.avg("player_total_kills").alias("avg_kills_per_game"))
        .orderBy(F.desc("avg_kills_per_game"))
        .limit(1)
    )
    most_played_playlist = (
        match_level.groupBy("playlist_id")
        .agg(F.count("*").alias("matches_played"))
        .orderBy(F.desc("matches_played"))
        .limit(1)
    )
    most_played_map = (
        match_level.groupBy("mapid", "map_name")
        .agg(F.count("*").alias("matches_played"))
        .orderBy(F.desc("matches_played"))
        .limit(1)
    )
    most_killing_sprees_map = (
        joined.where(F.col("medal_name") == "Killing Spree")
        .groupBy("mapid", "map_name")
        .agg(F.sum("count").alias("killing_spree_medals"))
        .orderBy(F.desc("killing_spree_medals"))
        .limit(1)
    )
    return {
        "most_kills_per_game": most_kills_per_game,
        "most_played_playlist": most_played_playlist,
        "most_played_map": most_played_map,
        "most_killing_sprees_map": most_killing_sprees_map,
    }


def compare_sort_orders(spark: SparkSession, joined: DataFrame, output_dir: str) -> DataFrame:
    """5. Write the same data with different sortWithinPartitions orders and compare sizes.
    Sorting by low-cardinality columns first (playlist, map) groups repeated values together,
    which run-length and dictionary encoding in Parquet compress much better."""
    aggregated = (
        joined.groupBy("match_id", "playlist_id", "mapid", "player_gamertag")
        .agg(
            F.max("player_total_kills").alias("kills"),
            F.sum(F.coalesce(F.col("count"), F.lit(0))).alias("medals"),
        )
        .repartition(NUM_BUCKETS, "match_id")
    )
    sort_orders = {
        "unsorted": [],
        "by_playlist": ["playlist_id"],
        "by_map": ["mapid"],
        "by_playlist_then_map": ["playlist_id", "mapid"],
        "by_map_then_playlist": ["mapid", "playlist_id"],
    }
    rows = []
    for label, columns in sort_orders.items():
        path = os.path.join(output_dir, label)
        df = aggregated.sortWithinPartitions(*columns) if columns else aggregated
        df.write.mode("overwrite").parquet(path)
        rows.append((label, _dir_size_bytes(path)))
    return spark.createDataFrame(rows, ["sort_order", "size_bytes"]).orderBy("size_bytes")


def _dir_size_bytes(path: str) -> int:
    total = 0
    for root, _, files in os.walk(path):
        total += sum(os.path.getsize(os.path.join(root, f)) for f in files)
    return total


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-dir", default="../data")
    parser.add_argument("--output-dir", default="./sort_experiment")
    args = parser.parse_args()

    spark = get_spark()
    joined = build_joined(spark, args.data_dir)

    for question, df in answer_questions(joined).items():
        print(f"\n== {question}")
        df.show(truncate=False)

    print("\n== Parquet size by sortWithinPartitions order (smallest first)")
    compare_sort_orders(spark, joined, args.output_dir).show(truncate=False)


if __name__ == "__main__":
    main()
