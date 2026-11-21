-- 3. Cumulative query that builds device_activity_datelist from events, one day at a time.
-- Example: builds the 2023-01-02 snapshot from the 2023-01-01 snapshot plus that day's events.
-- The devices table has every device listed twice, so it is deduplicated first.

INSERT INTO user_devices_cumulated
WITH devices_deduped AS (
    SELECT DISTINCT device_id, browser_type
    FROM devices
),
yesterday AS (
    SELECT *
    FROM user_devices_cumulated
    WHERE date = DATE '2023-01-01'
),
today AS (
    SELECT
        e.user_id,
        d.browser_type,
        DATE(CAST(e.event_time AS TIMESTAMP)) AS date_active
    FROM events e
    JOIN devices_deduped d
        ON e.device_id = d.device_id
    WHERE DATE(CAST(e.event_time AS TIMESTAMP)) = DATE '2023-01-02'
      AND e.user_id IS NOT NULL
    GROUP BY e.user_id, d.browser_type, DATE(CAST(e.event_time AS TIMESTAMP))
)
SELECT
    COALESCE(t.user_id, y.user_id)           AS user_id,
    COALESCE(t.browser_type, y.browser_type) AS browser_type,
    CASE
        WHEN y.device_activity_datelist IS NULL THEN ARRAY[t.date_active]
        WHEN t.date_active IS NULL              THEN y.device_activity_datelist
        ELSE ARRAY[t.date_active] || y.device_activity_datelist
    END AS device_activity_datelist,
    DATE '2023-01-02' AS date
FROM today t
FULL OUTER JOIN yesterday y
    ON t.user_id = y.user_id
   AND t.browser_type = y.browser_type;
