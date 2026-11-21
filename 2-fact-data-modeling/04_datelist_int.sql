-- 4. Converts device_activity_datelist into datelist_int: a 32-bit integer where each bit
-- is one day of the month (the most significant bit is the snapshot date, and each bit after it is one day earlier).
-- This makes "active in the last 7 days" or "days active this month" cheap bit operations.

WITH users AS (
    SELECT *
    FROM user_devices_cumulated
    WHERE date = DATE '2023-01-31'
),
series AS (
    SELECT generate_series(DATE '2023-01-01', DATE '2023-01-31', INTERVAL '1 day')::DATE AS series_date
),
place_holder_ints AS (
    SELECT
        u.user_id,
        u.browser_type,
        CASE
            WHEN u.device_activity_datelist @> ARRAY[s.series_date]
                THEN CAST(POW(2, 31 - (u.date - s.series_date)) AS BIGINT)
            ELSE 0
        END AS placeholder_int_value
    FROM users u
    CROSS JOIN series s
)
SELECT
    user_id,
    browser_type,
    CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))                          AS datelist_int,
    BIT_COUNT(CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32)))                AS days_active_in_month,
    BIT_COUNT(CAST('11111110000000000000000000000000' AS BIT(32))
              & CAST(CAST(SUM(placeholder_int_value) AS BIGINT) AS BIT(32))) > 0          AS is_weekly_active
FROM place_holder_ints
GROUP BY user_id, browser_type;
