# Contoso AVD — Hypercare Plan (B.4.2)

> Owner: AVD Delivery Lead · Date: 2026-06-27

## Window

- **Duration:** 2 weeks (10 business days) post go-live per wave.
- **Coverage:** business hours 07:00–19:00 CET (aligned to scaling ramp), with on-call for P1 outside
  hours.
- **Staffing:** Delivery Lead + 1 AVD engineer (shadowing Contoso Ops L1/L2). Ops own the keyboard;
  delivery advises (reverse-shadowing in week 2).

## Severity matrix

| Severity | Definition | Response target | Resolution target |
| --- | --- | --- | --- |
| P1 | Service down / many users cannot connect; CRM or Finance Suite unusable | 15 min | 4 h (workaround), 1 business day (fix) |
| P2 | Degraded — slow logons (P95 > 30 s) or single host down with capacity at risk | 30 min | 1 business day |
| P3 | Minor / single user, cosmetic, or query | 4 business hours | 3 business days |

## Escalation path

- **L1** Contoso Service Desk → triage with runbook incident playbook.
- **L2** Contoso Cloud Ops (`grp-avd-lab-admins`) → deeper AVD/FSLogix/IaC.
- **L3 / Vendor** Microsoft support (AVD / Azure Files / Entra) for service-side or platform issues.
- **On-call:** P1 pages the AVD engineer on-call; Delivery Lead is escalation owner during hypercare.
- Contacts maintained in the hypercare bridge channel (Teams) and on-call roster.

## Daily cadence

- **Stand-up:** 09:15 CET, 15 min — review overnight alerts, open incidents, planned changes.
- **Metrics tracked:** logon duration P50/P95, host health (Available/Unavailable), active sessions,
  incident count by severity, budget burn.
- **Report format:** one-page daily note posted to the bridge channel: yesterday's incidents,
  current P95, open items + owners, risks.

## Exit criteria (move to BAU)

- Logon **P95 ≤ 30 s** sustained over **5 consecutive business days**.
- **Zero** open P1 incidents and no P1 in the trailing 5 business days.
- **Fewer than 3 P2** incidents in the final week, all with documented resolutions.
- All KT exit criteria met; Ops performed each runbook op at least once unaided.
- Sign-off (`signoff.md`) accepted by customer sponsor.
