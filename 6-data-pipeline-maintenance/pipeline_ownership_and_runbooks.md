# Data Pipeline Maintenance Plan

A team of four data engineers (**Engineer A, B, C and D**) owns five pipelines across three business areas.

## Pipelines and ownership

Each engineer is primary on at most two pipelines and secondary on at most two, so knowledge is spread out and nobody is a single point of failure. Investor-facing pipelines get primary and secondary owners who work on different areas, so a second pair of eyes always comes from outside the primary's area.

| # | Pipeline | Business area | Consumer | Primary | Secondary |
|---|---|---|---|---|---|
| 1 | Unit-level profit | Profit | Experimentation | A | C |
| 2 | Aggregate profit | Profit | **Investors** | A | B |
| 3 | Daily growth | Growth | Experimentation | B | D |
| 4 | Aggregate growth | Growth | **Investors** | B | C |
| 5 | Aggregate engagement | Engagement | **Investors** | C | D |

Engineer D is primary on nothing yet; in a real team that would rotate quarterly so D owns a pipeline within three months. D carries more of the on-call load and onboarding work until then.

**What owners do**
- **Primary:** builds and changes the pipeline, reviews every PR to it, keeps its runbook current, and is the first escalation after on-call.
- **Secondary:** reviews major changes, can run a backfill alone, and covers when the primary is away.

## On-call schedule

- **Rotation:** one week per engineer, Monday 10:00 to Monday 10:00, so it's always A → B → C → D. Each person is on call about 13 weeks a year.
- **Handoff:** a 15-minute Monday meeting. The outgoing engineer walks through open incidents, flaky jobs and anything due that week, such as month-end investor reporting.
- **Backup:** the next person in the rotation is backup for the week and takes over if the primary on-call can't respond within 30 minutes.
- **Hours:** pipelines feeding investors page 24/7. Experiment pipelines (1 and 3) only alert during business hours, because a one-day delay there doesn't change any decision.

**Holidays and fairness**
- Major holidays (New Year's Day, Christmas, Thanksgiving, and each engineer's own important religious or cultural holidays) are tracked in a shared calendar at the start of each year.
- Holiday weeks are spread evenly: nobody covers more than one major holiday week per year, and whoever covered Christmas doesn't cover New Year's.
- Swaps are allowed with team agreement and recorded in the calendar, so the schedule always shows who is really on call.
- Covering a holiday earns a day off in lieu.
- Planned vacation is entered at least four weeks ahead, and the rotation is adjusted around it.

## Runbooks for investor-reported pipelines

### Pipeline 2: Aggregate profit (investors)

| | |
|---|---|
| **Owners** | Primary A, secondary B |
| **Schedule** | Daily at 06:00 UTC; month-end and quarter-end runs are investor-critical |
| **Inputs** | Revenue from billing, costs from finance/ERP exports, refunds and chargebacks, FX rates |
| **Output** | `agg_profit_daily` and `agg_profit_monthly`, used by the investor reporting dashboard |
| **SLA** | Previous day's numbers available by 09:00 UTC; month-end figures locked by the 3rd business day |

**What could go wrong**
- **Late or missing upstream data:** finance exports the cost file manually, so it may arrive late or not at all at month-end.
- **Currency conversion:** missing or stale FX rates for a day, so profit in non-USD regions is wrong.
- **Double counting:** duplicate billing events, or a refund recorded in both billing and the payment processor.
- **Revenue recognition changes:** finance changes how a product's revenue is recognized, and historical numbers no longer match previously reported ones.
- **Late-arriving refunds or chargebacks** change a month that was already reported.
- **Schema changes upstream:** a renamed or retyped column in the billing system breaks the job or silently nulls a field.
- **Restatements:** a backfill changes numbers investors have already seen.

**Checks that should run every time:** total revenue within ±X% of the 7-day trend; no NULL currency or FX rate; row counts versus the source; profit for each region not negative unless flagged.

### Pipeline 4: Aggregate growth (investors)

| | |
|---|---|
| **Owners** | Primary B, secondary C |
| **Schedule** | Daily at 05:00 UTC |
| **Inputs** | Sign-ups, account cancellations and reactivations, the subscriptions table |
| **Output** | `agg_growth_daily`: new, churned, resurrected and net active users, by region and plan |
| **SLA** | Available by 08:00 UTC |

**What could go wrong**
- **Late event data:** the event stream lags, so yesterday's sign-ups are undercounted and corrected the next day.
- **Definition drift:** product changes what counts as "active" or "churned" without telling data engineering.
- **Bot or test accounts** inflate sign-ups, for example during a spam attack or QA load test.
- **Duplicate users:** the same person signs up twice, or account merges aren't reflected.
- **Time zone boundaries:** days are split in local time in one system and UTC in another, so numbers don't match other reports.
- **Missing partitions:** an upstream job fails silently and one day has zero rows, which looks like a crash in growth.
- **Growth accounting doesn't balance:** yesterday's active users plus new and resurrected, minus churned, no longer equals today's active users.

**Checks:** the growth accounting identity balances each day; daily sign-ups within an expected band; no day with zero rows; the share of known bot or test accounts below a threshold.

### Pipeline 5: Aggregate engagement (investors)

| | |
|---|---|
| **Owners** | Primary C, secondary D |
| **Schedule** | Daily at 07:00 UTC |
| **Inputs** | Clickstream events, sessions, the user dimension |
| **Output** | `agg_engagement_daily`: DAU, WAU, MAU, sessions per user, time spent |
| **SLA** | Available by 10:00 UTC |

**What could go wrong**
- **Event tracking breaks:** a client release stops sending an event, or sends it twice, so engagement drops or spikes overnight.
- **Clickstream volume spikes** (a viral day or a bot attack) make the job slow or run out of memory and miss its SLA.
- **Sessionization errors:** a change to the session gap or to deduplication logic shifts sessions per user, with no real change in behaviour.
- **Skewed joins:** a few very active users or a null `user_id` key overload single partitions and the job stalls.
- **Bot traffic** inflates DAU unless it's filtered consistently.
- **Daylight saving time changes** create 23- or 25-hour days.
- **Metric definition changes:** if DAU is redefined, historical values must be restated consistently or investors will see a false jump.

**Checks:** DAU is never greater than MAU; day-over-day DAU change within an expected band; share of events with a null `user_id` below a threshold; the session count reconciles with the raw event count.

## Escalation path (all investor pipelines)

1. The on-call engineer acknowledges within 30 minutes and checks the runbook.
2. If it's not fixed within 2 hours, or the SLA is at risk, page the pipeline's primary owner.
3. If investor numbers will be late or have to be restated, the primary owner tells the finance or investor-relations stakeholder **before** the SLA passes.
4. After any incident affecting investor numbers, write a postmortem within 5 business days.
