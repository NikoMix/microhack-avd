<!-- SOLUTION KEY (trainer reference) — control B.2.2 Well-Architected Review.
     Findings reference the HLD in solutions/challenge-02/hld.md by section. -->
# Contoso AVD — Well-Architected Review (B.2.2)

> Author: AVD Engagement Team · Date: 2026-06-27 · Reviewed design version: HLD v1.0
> ([`solutions/challenge-02/hld.md`](../challenge-02/hld.md))

## Summary

The HLD is **fundamentally sound** — AVM-first, Entra join + Conditional Access, FSLogix on Files
Premium, per-persona pools, autoscale. **No critical findings.** Eight findings (**2 High, 6
Medium**) concentrate on the three AVD-critical pillars: the **single profile share vs the morning
logon storm** (Performance), an **untested restore** (Reliability), and **uncontrolled Log
Analytics ingestion** (Cost). **Seven are fix-now** (folded into the HLD before go-live); **one** is
accepted and **validated in the pilot**. Four findings carry forward as **pilot risks** (F3, F4,
F5, and the LOB CRM smartcard from HLD Decision 2).

## Findings

| ID | Pillar | Finding | Risk (H/M/L) | Recommendation | HLD §ref | Owner |
|---|---|---|---|---|---|---|
| F1 | Cost | 100 personal VMs use start-on-connect but no reservation/savings-plan for the steady-running baseline (~78 at peak) | M | Add a 30-day run-rate gate, then 1-yr reservations / savings plan for the baseline personal hosts | §2.6, §2.1 | Cloud FinOps |
| F2 | Cost | Log Analytics ingestion uncontrolled across ~28 pooled + 100 personal hosts (AVD Insights + perf counters + event logs) | M | Scope DCR counters, set table-level retention, apply a daily cap / commitment tier | §2.7 | Platform ops |
| F3 | Performance | A single 5 TiB profile share serves all 900 pooled users; the 490-KW morning storm may exceed Premium burst IOPS and regress logon time | **H** | Split KW and CC onto separate shares/storage accounts **from day one**; validate peak-logon IOPS in the pilot | §2.3 | Storage / Platform |
| F4 | Performance | KW density of 25/host rests on a 2 GiB/user RAM budget not yet validated against Teams + LOB CRM | M | Validate density under load in the pilot; keep N+1 + autoscale headroom; adjust SKU if CPU-bound | §2.1, §2.6 | Architecture |
| F5 | Reliability | Profile share is ZRS + snapshots but restore is only "to be tested" — an untested restore is not a backup | **H** | Author + execute a tested restore runbook as a go-live gate (B.4.1 case) | §2.3, §2.8 | Platform ops |
| F6 | Reliability | Session hosts not explicitly zone-distributed; a zonal outage could drop a whole pool | M | Spread session hosts across availability zones per pool (confirm AVM VM `zone` config) | §2.1, §2.8 | Architecture |
| F7 | Security | Clipboard/drive/screen-capture redirection policy unspecified, yet call-centre + LOB CRM handle customer data | M | Set device-redirection RDP properties + screen-capture protection per pool (tightest on CC) | §2.1, §2.2 | Security |
| F8 | Operations | Alerts listed but no concrete logon-time P95 target or action-group routing — "alert on logon time" isn't actionable | M | Define thresholds (e.g. P95 < 30 s) wired to the pilot criteria + an action group | §2.7 | Platform ops |

## Pillar notes

### Cost Optimization

Autoscale per persona is in place (good). The two levers left on the table are **commitment
discounts** for the always-on personal baseline (F1) and **observability spend** (F2) — Log
Analytics ingestion is the cost that quietly grows with host count and verbose counters. Files
Premium at 5 TiB is justified by IOPS, not defaulted, so it stays. Revisit **DepthFirst** only if
post-pilot cost pressure outweighs the logon-storm UX cost.

### Performance Efficiency

The dominant AVD performance risk is the **logon storm against FSLogix** (F3): a single share's
burst ceiling is a real bottleneck for 490 concurrent KW logons, so split the shares pre-emptively
rather than reactively. Density (F4) is an **assumption to prove**, not a defect — the pilot retires
it. RDP Shortpath and VDOT are already in the design.

### Reliability

Redundancy is designed (ZRS, snapshots, gallery replication) but **recoverability is unproven**
(F5) and **zone placement is implicit** (F6). Both are cheap to fix now and materially change the
real-world resilience. RTO/RPO objectives exist and are realistic.

### Security

Strong baseline: Entra join, Conditional Access + MFA, private endpoints, least-privilege RBAC. The
gap is **in-session data-egress controls** (F7) — clipboard/drive redirection and screen-capture
protection — which matters most for the customer-data-handling call centre.

### Operational Excellence

Monitoring coverage is good, but **alerts need numbers and routing** (F8). Everything is in IaC
(AVM), so drift control and change process are achievable; define the patch/rebuild cadence
(monthly, per HLD §2.5) in the runbook at handover.

## Decision register

| Finding | Decision | Justification | HLD change |
|---|---|---|---|
| F1 | **Fix now** (commit the gate) | Right-sizing reservations needs real run-rate data | §2.6: add a 30-day reservation-review gate for personal hosts |
| F2 | **Fix now** | Ingestion cost compounds with host count; cheap to bound | §2.7: scope DCR counters + retention + daily cap |
| F3 | **Fix now** | Logon-storm IOPS is the top performance risk; don't wait for it to bite | §2.3: provision **two** profile shares (KW, CC) from day one |
| F4 | **Accept + validate in pilot** | Density is a defensible assumption to prove, not a known defect | No change yet; flagged as pilot success criterion |
| F5 | **Fix now** | An untested restore is not a backup | §2.8: add a tested restore runbook as a go-live gate |
| F6 | **Fix now** | Zone spread is near-zero cost and removes a single-zone failure mode | §2.1: set availability-zone distribution per pool |
| F7 | **Fix now** | Customer-data handling requires egress controls | §2.2: define redirection + screen-capture policy per pool |
| F8 | **Fix now** | Alerts without thresholds aren't actionable | §2.7: add P95 thresholds + action group |

> **Carried to the pilot (B.2.3):** F3 (logon-storm IOPS), F4 (density under load), F5 (restore),
> plus the LOB CRM **smartcard/cloud-trust** question from HLD Decision 2. These become the pilot's
> quantitative success criteria.
