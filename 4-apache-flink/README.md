# 4. Apache Flink: Sessionizing Web Traffic

`src/job/session_job.py` reads the bootcamp's Kafka web-traffic stream and groups events into **sessions keyed by IP address and host, with a 5-minute inactivity gap**. Each finished session is written to Postgres with its start, end and event count.

- **Event time and watermarks:** sessions use the event's own timestamp, with a 15-second watermark for late events.
- **Session windows:** unlike fixed (tumbling) windows, a session stays open as long as the same IP keeps sending events to the same host less than 5 minutes apart.
- **Session end:** Flink reports the end as the last event plus the 5-minute gap, so session length in the analysis includes that gap.

`session_analysis.sql` answers the questions from the sink table:
1. The average number of web events per session on Tech Creator hosts.
2. A comparison of sessions, events per session and session length across `zachwilson.techcreator.io`, `zachwilson.tech` and `lulu.techcreator.io`.

## Running it

Uses the course's Flink and Kafka Docker setup ([module instructions](https://github.com/DataExpert-io/data-engineer-handbook/tree/main/intermediate-bootcamp/materials/4-apache-flink-training)). Kafka and Postgres credentials come from environment variables and are never committed.

```bash
# create the sink table in Postgres, then:
docker compose exec jobmanager ./bin/flink run -py /opt/src/job/session_job.py --pyFiles /opt/src -d
```
