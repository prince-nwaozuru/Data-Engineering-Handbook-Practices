from collections import namedtuple

from chispa.dataframe_comparer import assert_df_equality

from ..jobs.dedupe_game_details_job import do_dedupe_game_details

GameDetail = namedtuple("GameDetail", "game_id team_id player_id player_name pts")


def test_dedupe_removes_exact_duplicates(spark):
    source_df = spark.createDataFrame([
        GameDetail(1, 10, 100, "LeBron James", 30.0),
        GameDetail(1, 10, 100, "LeBron James", 30.0),  # duplicate row
        GameDetail(1, 10, 101, "Anthony Davis", 25.0),
        GameDetail(2, 10, 100, "LeBron James", 12.0),  # same player, different game
    ])

    actual_df = do_dedupe_game_details(spark, source_df)

    expected_df = spark.createDataFrame([
        GameDetail(1, 10, 100, "LeBron James", 30.0),
        GameDetail(1, 10, 101, "Anthony Davis", 25.0),
        GameDetail(2, 10, 100, "LeBron James", 12.0),
    ])
    assert_df_equality(
        actual_df, expected_df, ignore_row_order=True, ignore_nullable=True
    )


def test_dedupe_keeps_unique_rows_unchanged(spark):
    rows = [
        GameDetail(5, 20, 200, "Stephen Curry", 40.0),
        GameDetail(5, 21, 300, "Kevin Durant", 35.0),
    ]
    actual_df = do_dedupe_game_details(spark, spark.createDataFrame(rows))

    assert_df_equality(
        actual_df,
        spark.createDataFrame(rows),
        ignore_row_order=True,
        ignore_nullable=True,
    )
