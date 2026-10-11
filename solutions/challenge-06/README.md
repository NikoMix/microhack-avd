# Trainer Solution Key — Challenge 06: Service Validation (B.4.1)

This README is the trainer-facing rationale behind the worked `validation.md` evidence
artifact in this folder. It explains *why* the validation is structured the way it is and
how to coach learners through reading the results honestly.

## Why sign-off is evidence-based

Service validation is not an opinion — it is a claim ("the service meets the bar") backed by
a reproducible measurement. Every row in `validation.md` carries the exact command or KQL
that produced its actual value, so a reviewer can re-run it and get the same answer. We assert
nothing we cannot show. A "Pass" with no attached query is not a pass.

## Why generate load first, then query logon performance

Logon performance is measured from `WVDConnections` Started→Connected events. If no one has
signed in during the query window, **there is no data to summarise** and the percentiles are
empty/null. So the workflow is deliberately two steps:

1. `Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -ConcurrentUsers 5 -DurationMinutes 5`
   creates real connection events at classroom scale.

2. `Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec -AsMarkdown` then queries the populated
   window and emits the results table.

Generate the signal, *then* measure it. Querying first yields a misleading "no data" result
that learners often misread as a failure.

## How to read P50 vs P95

1. **P50 (median)** is the typical experience — half of logons are faster, half slower. It
   tells you what a normal user feels day to day.

2. **P95** is the tail — only 5% of logons are slower than this. It captures the bad-day,
   peak-hour, cold-cache experience and is the number that drives complaints. The pilot bar
   sets both (P50 ≤ 20 s, P95 ≤ 30 s) precisely so a good median cannot hide an ugly tail.

## Interpreting lab-scale numbers directionally

The lab is 2 hosts and a 5-user storm. Read the actuals **directionally against the target**,
not as a production capacity statement. P95 ≈ 26 s on a tiny lab tells you the design and
image are healthy and trending well under 30 s; it does **not** prove the number holds at
1,000-user peak density. Production sign-off confirms the same query at production density
during pilot/UAT. The lab proves the mechanism works and the direction is right.

## The classic gotcha: ARM resource id vs workspace GUID

KQL run from the Logs blade resolves the table for you, but when you query Log Analytics
programmatically you must target the **workspace customer id (GUID)** — not the workspace's
**ARM resource id** (`/subscriptions/.../workspaces/log-avd-lab-sec`). Passing the ARM id to
the Data Collector / query API returns an authorization or "workspace not found" error, or
silently empty results. `Test-AvdService.ps1` resolves the workspace GUID for you, which is
why learners who copy the canonical KQL into the portal succeed but a hand-rolled API call
sometimes returns nothing. If a learner sees empty results from a script, check this first.

## Why Inconclusive / Skipped is an honest status

`Inconclusive` and `Skipped` are first-class outcomes, not soft failures:

1. **Skipped** means the thing under test is not deployed yet (e.g. a feature out of scope for
   the lab slice). It is not a defect — there is simply nothing to assert.

2. **Inconclusive** means there is insufficient signal to make the call (e.g. a true host-loss
   failover on a 2-host lab — draining one leaves only one, so the reschedule cannot be fully
   demonstrated). Marking it Inconclusive and explaining the limitation is more honest than a
   false Pass or an unfair Fail. The honest path is to validate directionally and defer the
   full proof to production density.

## The fully-worked logon KQL, line by line

```kusto
WVDConnections
| where TimeGenerated > ago(1h)
| project CorrelationId, UserName, State, TimeGenerated, SessionHostName
| summarize StartTime = minif(TimeGenerated, State == "Started"),
            ConnectedTime = minif(TimeGenerated, State == "Connected")
            by CorrelationId, UserName, SessionHostName
| where isnotnull(ConnectedTime)
| extend LogonSeconds = datetime_diff('second', ConnectedTime, StartTime)
| summarize P50 = percentile(LogonSeconds, 50), P95 = percentile(LogonSeconds, 95), Sessions = count()
```

1. `WVDConnections` — the AVD connection-events table fed by AVD Insights / diagnostics.
2. `where TimeGenerated > ago(1h)` — scope to the recent window you just loaded; widen if the load-test ran earlier.
3. `project ...` — keep only the fields needed: the per-connection `CorrelationId`, the user, the state, the timestamp, and the host.
4. `summarize StartTime = minif(... State == "Started")` — for each connection, take the earliest `Started` timestamp (logon begins).
5. `ConnectedTime = minif(... State == "Connected")` — and the earliest `Connected` timestamp (session usable) for the same connection.
6. `by CorrelationId, UserName, SessionHostName` — group per connection so start and connect pair up correctly.
7. `where isnotnull(ConnectedTime)` — drop connections that never completed, so failed/abandoned attempts do not skew the timing.
8. `extend LogonSeconds = datetime_diff('second', ConnectedTime, StartTime)` — the logon duration in whole seconds.
9. `summarize P50 = percentile(..., 50), P95 = percentile(..., 95), Sessions = count()` — the median, the tail, and how many sessions backed the numbers (always check `Sessions` is non-trivial).

## Common ways learners go wrong

1. **No data in the window** — they query logon perf before running the load-test, get empty
   percentiles, and panic. Always generate signal first and check `Sessions`.

2. **Expecting production numbers from a tiny lab** — they treat a 2-host, 5-user result as a
   capacity guarantee. Read it directionally against the target, not as production proof.

3. **Treating Inconclusive as Fail** — they fail the resilience row because the 2-host lab
   cannot show full failover. Inconclusive with an explanation is the correct, honest call.

4. **Not reconciling back to the pilot criteria** — they produce a results table but never map
   it to the B.2.3 bar, persona by persona. The artifact only earns sign-off when it explicitly
   reconciles (and justifies any deviation, like the failover Inconclusive).

## How the worked example uses the failure path

The worked `validation.md` deliberately includes a **Fail** (the logon-P95 alert mis-firing on
an empty pre-load window) and an **Inconclusive** (failover at 2-host scale) so learners
practise the remediation loop. Note the loop-back decision: the alert fix is a rule-tuning
change (no host/storage redeploy, so **no B.3.1 loop-back**), and the failover gap is a
lab-scale limitation marked N/A. Coach learners that "loop back to B.3.1" is reserved for real
deployment defects, not for tuning or scale artifacts.
