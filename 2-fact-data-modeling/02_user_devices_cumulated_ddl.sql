-- 2. DDL for user_devices_cumulated
-- Tracks the days each user was active, per browser_type.
-- browser_type is a column (one row per user per browser) rather than a MAP key,
-- which keeps the table easy to query and join in Postgres.

CREATE TABLE user_devices_cumulated (
    user_id                  NUMERIC,
    browser_type             TEXT,
    device_activity_datelist DATE[],  -- every date the user was active on this browser, newest first
    date                     DATE,    -- snapshot date
    PRIMARY KEY (user_id, browser_type, date)
);
