# 2. Fact Data Modelling: Devices, Events and Hosts

Eight queries on the `events`, `devices` and `game_details` tables (January 2023 web traffic).

| File | Task |
|---|---|
| `01_dedupe_game_details.sql` | Removes duplicates: 246,043 rows down to 245,754 unique (game, team, player) rows |
| `02_user_devices_cumulated_ddl.sql` | `user_devices_cumulated`, with `browser_type` as a column and a `DATE[]` activity list |
| `03_user_devices_cumulated_load.sql` | Daily cumulative load from `events` joined to deduplicated `devices` |
| `04_datelist_int.sql` | Converts the date list into a 32-bit bitmask, plus days active this month and a weekly-active flag |
| `05_hosts_cumulated_ddl.sql` | `hosts_cumulated` with `host_activity_datelist` |
| `06_hosts_cumulated_load.sql` | Daily incremental load of each host's active dates |
| `07_host_activity_reduced_ddl.sql` | Monthly reduced fact table with `hit_array` and `unique_visitors_array` |
| `08_host_activity_reduced_load.sql` | Day-by-day load that appends to the month's arrays (`ON CONFLICT ... DO UPDATE`) |

## Design decisions

- **`browser_type` as a column** instead of a `MAP<STRING, ARRAY[DATE]>`. Postgres has no native map type, and one row per user per browser is easier to join and filter.
- **The `devices` table lists every device twice**, so it's deduplicated before joining, otherwise every activity day would be counted twice.
- **Bitmask layout:** the most significant bit is the snapshot date and each following bit is one day earlier, so "active in the last 7 days" is a single `AND` with `11111110…`.
- **Reduced fact arrays are padded with zeros** when a host first appears mid-month, so array position always equals day of the month.

## Verification

Loaded every day from 2023-01-01 to 2023-01-31 and checked against the raw events:
- The total length of all `device_activity_datelist` arrays (2,738) equals the number of distinct user, browser and day combinations in `events`.
- The `hit_array` totals for each host equal that host's raw event count, for example 12,460 for www.zachwilson.tech.
- The `unique_visitors_array` totals equal the distinct (user, day) counts for each host.
