-- Questions answered from the `sessionized_events` table written by src/job/session_job.py.

-- Table the Flink job writes into (create it in Postgres before starting the job).
CREATE TABLE IF NOT EXISTS sessionized_events (
    session_start TIMESTAMP(3),
    session_end   TIMESTAMP(3),
    ip            VARCHAR,
    host          VARCHAR,
    num_events    BIGINT
);

-- 1. Average number of web events per session from a user on Tech Creator.
SELECT
    ROUND(AVG(num_events), 2) AS avg_events_per_session,
    COUNT(*)                  AS sessions
FROM sessionized_events
WHERE host LIKE '%techcreator.io';

-- 2. Compare hosts.
SELECT
    host,
    COUNT(*)                                              AS sessions,
    ROUND(AVG(num_events), 2)                             AS avg_events_per_session,
    ROUND(AVG(EXTRACT(EPOCH FROM session_end - session_start)) / 60, 1) AS avg_session_minutes
FROM sessionized_events
WHERE host IN ('zachwilson.techcreator.io', 'zachwilson.tech', 'lulu.techcreator.io')
GROUP BY host
ORDER BY avg_events_per_session DESC;
