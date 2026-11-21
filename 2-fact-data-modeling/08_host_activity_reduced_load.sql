-- 8. Day-by-day incremental load for host_activity_reduced.
-- Each run appends one day's values to the month's arrays. A host that first appears
-- mid-month gets zeros for the earlier days, so array position always equals day of month.
-- Example: loads 2023-01-02.

INSERT INTO host_activity_reduced
WITH daily_aggregate AS (
    SELECT
        host,
        DATE(CAST(event_time AS TIMESTAMP)) AS date,
        COUNT(1)                AS num_hits,
        COUNT(DISTINCT user_id) AS num_unique_visitors
    FROM events
    WHERE DATE(CAST(event_time AS TIMESTAMP)) = DATE '2023-01-02'
    GROUP BY host, DATE(CAST(event_time AS TIMESTAMP))
),
yesterday_array AS (
    SELECT *
    FROM host_activity_reduced
    WHERE month = DATE '2023-01-01'
)
SELECT
    DATE '2023-01-01' AS month,
    COALESCE(da.host, ya.host) AS host,
    CASE
        WHEN ya.hit_array IS NOT NULL
            THEN ya.hit_array || ARRAY[COALESCE(da.num_hits, 0)]::INTEGER[]
        ELSE ARRAY_FILL(0, ARRAY[(DATE '2023-01-02' - DATE '2023-01-01')])
             || ARRAY[COALESCE(da.num_hits, 0)]::INTEGER[]
    END AS hit_array,
    CASE
        WHEN ya.unique_visitors_array IS NOT NULL
            THEN ya.unique_visitors_array || ARRAY[COALESCE(da.num_unique_visitors, 0)]::INTEGER[]
        ELSE ARRAY_FILL(0, ARRAY[(DATE '2023-01-02' - DATE '2023-01-01')])
             || ARRAY[COALESCE(da.num_unique_visitors, 0)]::INTEGER[]
    END AS unique_visitors_array
FROM daily_aggregate da
FULL OUTER JOIN yesterday_array ya
    ON da.host = ya.host
ON CONFLICT (month, host)
DO UPDATE SET
    hit_array             = EXCLUDED.hit_array,
    unique_visitors_array = EXCLUDED.unique_visitors_array;
