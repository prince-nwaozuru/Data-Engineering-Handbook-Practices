-- 6. Incremental query that builds host_activity_datelist one day at a time.
-- Example: builds the 2023-01-02 snapshot from the 2023-01-01 snapshot plus that day's events.

INSERT INTO hosts_cumulated
WITH yesterday AS (
    SELECT *
    FROM hosts_cumulated
    WHERE date = DATE '2023-01-01'
),
today AS (
    SELECT
        host,
        DATE(CAST(event_time AS TIMESTAMP)) AS date_active
    FROM events
    WHERE DATE(CAST(event_time AS TIMESTAMP)) = DATE '2023-01-02'
    GROUP BY host, DATE(CAST(event_time AS TIMESTAMP))
)
SELECT
    COALESCE(t.host, y.host) AS host,
    CASE
        WHEN y.host_activity_datelist IS NULL THEN ARRAY[t.date_active]
        WHEN t.date_active IS NULL            THEN y.host_activity_datelist
        ELSE ARRAY[t.date_active] || y.host_activity_datelist
    END AS host_activity_datelist,
    DATE '2023-01-02' AS date
FROM today t
FULL OUTER JOIN yesterday y
    ON t.host = y.host;
