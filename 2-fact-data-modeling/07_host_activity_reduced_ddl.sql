-- 7. DDL for host_activity_reduced: a monthly reduced fact table.
-- One row per host per month; position N in each array holds that metric for day N of the month.

CREATE TABLE host_activity_reduced (
    month                  DATE,       -- first day of the month
    host                   TEXT,
    hit_array              INTEGER[],  -- COUNT(1) of events per day
    unique_visitors_array  INTEGER[],  -- COUNT(DISTINCT user_id) per day
    PRIMARY KEY (month, host)
);
