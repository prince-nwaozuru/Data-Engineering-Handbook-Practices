-- 5. DDL for hosts_cumulated: which dates each host saw any activity.

CREATE TABLE hosts_cumulated (
    host                   TEXT,
    host_activity_datelist DATE[],  -- every date the host had at least one event, newest first
    date                   DATE,    -- snapshot date
    PRIMARY KEY (host, date)
);
