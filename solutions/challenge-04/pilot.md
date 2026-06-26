<!-- SOLUTION KEY (trainer reference) — control B.2.3 PoC / Pilot.
     Success criteria are quantitative and map to WAF findings in solutions/challenge-03/waf-review.md. -->
# Contoso AVD — PoC / Pilot (B.2.3)

> Author: AVD Engagement Team · Date: 2026-06-27 · Pilot window: 2 weeks (1 week guided + 1 week shadow)
>
> 📏 **Reading this key:** the **Results** table (§4) shows *representative lab measurements* so
> trainers can demo a complete, passing pilot. In a live engagement the learner records their **own**
> numbers from the deployed lab — see [Challenge 06](../../challenges/) (B.4.1 Service Validation).

## 1. Scope

| In scope | Out of scope |
|---|---|
| **Knowledge-worker** persona: 15 pilot users on **1–2** `D16as_v5` pooled hosts | Full 1,000-user rollout; call-centre persona **at scale** |
| **Power** persona: 2 users on `E4as_v5` personal hosts | All 4 host pools at production size |
| **Developer** persona: 1 user on `D8s_v5` personal host (nested virt) | BCDR region failover (scheduled in B.4.1) |
| Core apps: M365 Apps, Teams (optimized), Edge, **LOB CRM (smartcard)** | The full 120-app estate; printing estate |
| FSLogix on **Files Premium** (separate KW + CC shares, per WAF F3) | ANF (not needed < 1,000 pooled) |
| Entra join + Conditional Access + MFA; autoscale on KW pool | Hybrid-join path (only if smartcard test fails) |
| Tested profile **restore** drill (WAF F5); redirection policy (WAF F7) | Citrix legacy app *X* remediation (deferred) |

Pilot user count: **18** · Duration: **2 weeks** · Environment: **lab subscription, `swedencentral`,
1–2 KW hosts + 3 personal VMs, small SKUs, budget + auto-shutdown applied before any host is created.**

## 2. Success criteria (quantitative)

| # | Criterion | Target | Measurement method |
|---|---|---|---|
| 1 | Logon time (P95) | **< 30 s** | AVD Insights / KQL on `WVDConnections` (connect → desktop ready) |
| 2 | App launch — LOB CRM | **< 8 s** | Stopwatch + `Microsoft-Windows-Diagnostics-Performance` |
| 3 | Profile load (FSLogix) | **< 15 s** | FSLogix `Operational` log events 25/26; `frx list-redirects` |
| 4 | Host CPU at 25 users/host | **< 75 %** | AVD Insights / VM Insights perf counters under load |
| 5 | P1 incidents | **0** | ITSM queue over the pilot window |
| 6 | Logon-storm IOPS (1 host, 25 concurrent at 08:00) | **within Premium burst** | Storage account `Transactions` / `SuccessE2ELatency` metrics |
| 7 | Profile restore | **RTO < 30 min, RPO ≤ 24 h, 0 extra data loss** | Timed restore drill from share snapshot |
| 8 | LOB CRM smartcard auth on Entra-joined host | **success** | Functional test (cloud-trust / Entra Kerberos) |

## 3. Test plan

| Test | Maps to WAF finding | Method |
|---|---|---|
| T1 — Logon storm | **F3** (§2.3) | Ramp 25 concurrent logons onto one KW host at 08:00; capture criteria 1 + 6 |
| T2 — Density under load | **F4** (§2.1/§2.6) | Drive 25 users with a Teams call + CRM + Edge; capture criterion 4 |
| T3 — Profile restore drill | **F5** (§2.3/§2.8) | Delete a test profile, restore from snapshot, time RTO; capture criterion 7 |
| T4 — Smartcard auth | **HLD Decision 2** | LOB CRM login on Entra-joined host via cloud-trust; capture criterion 8 |
| T5 — Redirection policy | **F7** (§2.2) | Attempt clipboard/drive egress on CC-profile host; confirm blocked |
| T6 — Autoscale schedule | **HLD §2.6** | Confirm time-based plan ramps hosts up pre-08:00 and down post-18:00 |
| T7 — App launch + steady-state UX | criteria 2, 3 | Launch M365 / Teams / CRM; measure launch + profile load |

## 4. Results

> *Representative lab measurements (see banner above).*

| Criterion | Target | Actual | Pass/Fail | Evidence |
|---|---|---|---|---|
| 1 — Logon P95 | < 30 s | 22 s | ✅ Pass | AVD Insights logon-duration workbook |
| 2 — CRM launch | < 8 s | 6.4 s | ✅ Pass | Perf log + stopwatch sample (n=20) |
| 3 — Profile load | < 15 s | 9 s | ✅ Pass | FSLogix event 26 timings |
| 4 — Host CPU @ 25 users | < 75 % | 68 % peak | ✅ Pass | VM Insights, T2 run |
| 5 — P1 incidents | 0 | 0 | ✅ Pass | ITSM queue export |
| 6 — Logon-storm IOPS | within burst | 12.1k IOPS peak (burst ~15.4k) | ✅ Pass | Storage `Transactions` metric, T1 |
| 7 — Restore | RTO < 30 m / RPO ≤ 24 h | 18 min, 0 extra loss | ✅ Pass | Timed restore drill log |
| 8 — Smartcard | success | success (cloud-trust) | ✅ Pass | T4 functional screenshot |

## 5. Go / No-Go

- **Recommendation:** **GO with conditions** — all eight criteria passed at pilot scale; the design
  is validated for a **phased** production rollout starting with the knowledge-worker wave.
- **Conditions / required fixes before B.3.1:**
  1. **F3** — provision **separate KW and CC profile shares** in production IaC (proven necessary by
     the logon-storm headroom margin).
  2. **F5** — the tested **restore runbook** is signed off and added to the ops handover.
  3. **F7** — **redirection + screen-capture policy** enforced on all pooled pools (tightest on CC).
  4. **F4** — production autoscale keeps **N+1 + headroom** at the validated 25 users/host.
- **Residual risks:**
  - **Call-centre persona** not load-tested at scale → run a dedicated CC wave (200 users, shift
    scaling) before its production cutover.
  - **BCDR region failover** untested → scheduled in B.4.1 service validation.
  - **Citrix legacy app *X*** compatibility unverified → deferred to app remediation; keep the
    Citrix bridge for that app group until resolved (see migration cutover plan).
