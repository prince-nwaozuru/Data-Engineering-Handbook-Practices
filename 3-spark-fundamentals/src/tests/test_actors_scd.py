from collections import namedtuple

from chispa.dataframe_comparer import assert_df_equality
from pyspark.sql import functions as F

from ..jobs.actors_scd_job import do_actors_scd_transformation

Actor = namedtuple("Actor", "actorid actor current_year quality_class is_active")
ActorScd = namedtuple(
    "ActorScd", "actorid actor quality_class is_active start_date end_date current_year"
)


def test_actors_scd_backfill(spark):
    source_data = [
        # good for two years, then star, then inactive (quality carried forward)
        Actor("nm001", "Jane Doe", 2018, "good", True),
        Actor("nm001", "Jane Doe", 2019, "good", True),
        Actor("nm001", "Jane Doe", 2020, "star", True),
        Actor("nm001", "Jane Doe", 2021, "star", False),
        # a single-year actor
        Actor("nm002", "John Roe", 2020, "bad", True),
    ]
    source_df = spark.createDataFrame(source_data)

    actual_df = do_actors_scd_transformation(spark, source_df, 2021)

    expected_data = [
        ActorScd("nm001", "Jane Doe", "good", True, 2018, 2019, 2021),
        ActorScd("nm001", "Jane Doe", "star", True, 2020, 2020, 2021),
        ActorScd("nm001", "Jane Doe", "star", False, 2021, 2021, 2021),
        ActorScd("nm002", "John Roe", "bad", True, 2020, 2020, 2021),
    ]
    # the job writes current_year as an INT literal
    expected_df = spark.createDataFrame(expected_data).withColumn(
        "current_year", F.col("current_year").cast("int")
    )

    assert_df_equality(
        actual_df, expected_df, ignore_row_order=True, ignore_nullable=True
    )


def test_actors_scd_respects_as_of_year(spark):
    source_df = spark.createDataFrame([
        Actor("nm001", "Jane Doe", 2020, "good", True),
        Actor("nm001", "Jane Doe", 2021, "bad", True),
    ])

    actual_df = do_actors_scd_transformation(spark, source_df, 2020)

    expected_df = spark.createDataFrame([
        ActorScd("nm001", "Jane Doe", "good", True, 2020, 2020, 2020),
    ]).withColumn("current_year", F.col("current_year").cast("int"))
    assert_df_equality(
        actual_df, expected_df, ignore_row_order=True, ignore_nullable=True
    )
