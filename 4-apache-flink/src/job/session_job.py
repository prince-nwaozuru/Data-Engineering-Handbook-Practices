"""
Week 4 Flink homework: sessionize web events by IP address and host.

- Source: the bootcamp's Kafka web-traffic topic (same schema as the course's start_job.py).
- Session window with a 5-minute inactivity gap, keyed by (ip, host).
- Sink: Postgres table `sessionized_events`, one row per finished session with its event count.

Run inside the course's Flink docker setup:
    docker compose exec jobmanager ./bin/flink run -py /opt/src/job/session_job.py --pyFiles /opt/src -d
"""
import os

from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, StreamTableEnvironment
from pyflink.table.expressions import col, lit
from pyflink.table.window import Session


def create_events_source_kafka(t_env):
    kafka_key = os.environ.get("KAFKA_WEB_TRAFFIC_KEY", "")
    kafka_secret = os.environ.get("KAFKA_WEB_TRAFFIC_SECRET", "")
    table_name = "web_events_kafka"
    pattern = "yyyy-MM-dd''T''HH:mm:ss.SSS''Z''"
    t_env.execute_sql(f"""
        CREATE TABLE {table_name} (
            ip VARCHAR,
            event_time VARCHAR,
            referrer VARCHAR,
            host VARCHAR,
            url VARCHAR,
            geodata VARCHAR,
            window_timestamp AS TO_TIMESTAMP(event_time, '{pattern}'),
            WATERMARK FOR window_timestamp AS window_timestamp - INTERVAL '15' SECOND
        ) WITH (
            'connector' = 'kafka',
            'properties.bootstrap.servers' = '{os.environ.get("KAFKA_URL")}',
            'topic' = '{os.environ.get("KAFKA_TOPIC")}',
            'properties.group.id' = '{os.environ.get("KAFKA_GROUP")}',
            'properties.security.protocol' = 'SASL_SSL',
            'properties.sasl.mechanism' = 'PLAIN',
            'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username=\"{kafka_key}\" password=\"{kafka_secret}\";',
            'scan.startup.mode' = 'earliest-offset',
            'properties.auto.offset.reset' = 'earliest',
            'format' = 'json'
        )
    """)
    return table_name


def create_sessions_sink_postgres(t_env):
    table_name = "sessionized_events"
    t_env.execute_sql(f"""
        CREATE TABLE {table_name} (
            session_start TIMESTAMP(3),
            session_end   TIMESTAMP(3),
            ip            VARCHAR,
            host          VARCHAR,
            num_events    BIGINT
        ) WITH (
            'connector' = 'jdbc',
            'url' = '{os.environ.get("POSTGRES_URL")}',
            'table-name' = '{table_name}',
            'username' = '{os.environ.get("POSTGRES_USER", "postgres")}',
            'password' = '{os.environ.get("POSTGRES_PASSWORD", "postgres")}',
            'driver' = 'org.postgresql.Driver'
        )
    """)
    return table_name


def sessionize():
    env = StreamExecutionEnvironment.get_execution_environment()
    env.enable_checkpointing(10 * 1000)
    env.set_parallelism(3)
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    t_env = StreamTableEnvironment.create(env, environment_settings=settings)

    source_table = create_events_source_kafka(t_env)
    sink_table = create_sessions_sink_postgres(t_env)

    # A session closes after 5 minutes with no events from the same IP on the same host.
    t_env.from_path(source_table) \
        .window(Session.with_gap(lit(5).minutes).on(col("window_timestamp")).alias("s")) \
        .group_by(col("s"), col("ip"), col("host")) \
        .select(
            col("s").start.alias("session_start"),
            col("s").end.alias("session_end"),
            col("ip"),
            col("host"),
            col("ip").count.alias("num_events"),
        ) \
        .execute_insert(sink_table) \
        .wait()


if __name__ == "__main__":
    sessionize()
