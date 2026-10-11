# Solution key — Challenge 01 · Workload assessment (B.1.1)

> ⚠️ **Trainers only.** Reference answer for [Challenge 01](../../challenges/challenge-01-workload-assessment/).
> Learners should attempt it with `avd-assessor` first. This is *a* correct answer, not the only one.

**Worked artifact:** [`assessment.md`](assessment.md) — a complete, audit-grade B.1.1 assessment.

## Why this answer is defensible

- **Reconciles to scenario** — 700 + 200 + 60 + 40 = **1000**; peak concurrency is **calculated**
  (users × peak %), giving 490 / 180 / 48 / 30 = **748** peak concurrent.
- **Pool type is justified, not assumed** — pooled multi-session for the two standardised,
  shareable populations; personal for the two that need persistent state / admin rights / nested
  virtualization.
- **Density shows the governing constraint** — knowledge workers are **RAM-bound** (~2 GiB/user →
  25/host), call centre is comfortably within both limits (30/host). Host count uses
  `ceil(peak / density) + N+1`.
- **FSLogix is sized for IOPS, not capacity** — 4,100 GB raw profile data, but the share is
  provisioned for the **logon-storm IOPS** of the 900 pooled users (≥ 5 TiB Premium, burst ~15k
  IOPS), with a split-share escape hatch and the **ANF threshold** (> ~1,000 pooled) called out.
- **Tied to discovery** — every density choice is corroborated against `map-assessment-sample.csv`
  (legacy hosts over-subscribed at ~1.1 GiB/user; profile file server IOPS-bound).

## The derivation a trainer should walk live

```text
peak concurrent      = users × peak %        (700×0.70=490, 200×0.90=180, 60×0.80=48, 40×0.75=30)
usable RAM / host    = 64 GiB − 8 GiB OS/agents/FSLogix = 56 GiB   (D16as_v5)
KW density (RAM)     = 56 / 2.0 GiB = 28  → plan 25 (Teams headroom)
CC density (RAM)     = 56 / 1.5 GiB ≈ 37  → plan 30 (conservative, shift autoscale)
KW hosts             = ceil(490/25) + N+1 = 20 + 1 = 21
CC hosts             = ceil(180/30) + N+1 = 6  + 1 = 7
personal VMs         = 60 power + 40 dev = 100 provisioned (~78 running at peak)
FSLogix raw          = 5×700 + 3×200 = 4,100 GB → Premium share ≥ 5 TiB (≈5,120/15,360 IOPS)
```

## Common ways learners go wrong (pre-empt these)

| Mistake | Why it's wrong | Steer them to |
|---|---|---|
| Size for **1000** users | Hosts serve **peak concurrent**, not headcount | `ceil(peak concurrent / density)` |
| Drop **N+1** | No maintenance/zone headroom → no patching without impact | always `+ N+1` |
| Size FSLogix on **capacity** | Logon **storms** drive IOPS, not GB stored | provision for peak-logon IOPS |
| Put power users / devs on **pooled** | Persistent state, admin rights, nested virt break sharing | personal pools |
| AMD SKU for **developers** | `Das_v5`/`Eas_v5` don't support nested virtualization | Intel `D8s_v5` for Docker/WSL2 |
| App rows with no rationale | Auditor rejects "install to image" with no *why* | decision **+** reason **+** risk |
| Invent new numbers | Breaks traceability through B.2.1→B.2.3 | reuse `scenario/` values exactly |

## Hand-off

The persona + density + FSLogix table is the **primary input to `avd-architect`** (Challenge 02).
Keep it unambiguous — the HLD, WAF review, and pilot all inherit these numbers.
