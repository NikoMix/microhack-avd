---
name: avd-personas-sizing
description: Session-host sizing and density math for Azure Virtual Desktop. Use when mapping user personas to host pool types, VM families, users-per-host density, and FSLogix storage IOPS, so assessment and design numbers are calculated and defensible rather than guessed.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# AVD personas & sizing

Use when turning a user population into pools, SKUs, host counts, and storage. **Show the
math** — auditors and architects must see how the number was derived.

## Persona → pool

| Signal | Pooled multi-session | Personal |
|---|---|---|
| Standardised app set, shared hosts OK | ✅ | |
| Persistent state / admin rights / heavy single-user apps | | ✅ |
| Cost efficiency at scale | ✅ | |
| GPU / dev / power user | sometimes | ✅ |

Contoso defaults: knowledge workers + call centre → **pooled multi-session (Win 11 Enterprise
multi-session)**; power users + developers → **personal**.

## Density (multi-session) — method

1. Start from Microsoft's **multi-session sizing guidance** by workload (light/medium/heavy/
   power). Ground in **`microsoft-learn` MCP** ("session host sizing guidelines").
2. Pick a VM family: knowledge workers → general-purpose **D-series** (e.g. D4–D8as v5); call
   centre (high density, light) → D-series tuned for users/vCPU; power/dev → memory-optimised
   **E-series** or GPU **NV** if needed.
3. Density rule of thumb: **~1 vCPU per 1–2 light users**, fewer for heavy. Validate against the
   workload table; never exceed memory headroom (leave OS + FSLogix overhead).
4. Host count = ceil(peak concurrent users ÷ users-per-host) + N+1 headroom for maintenance.
5. Cross-check with the autoscale plan (don't size for peak if you ramp).

## Storage / FSLogix IOPS

- Premium Files baseline IOPS scales with provisioned size; size the share for **peak
  concurrent logons**, not total users (logon storms drive IOPS).
- Budget ~**10–30 IOPS/user** at steady state, higher during logon storms; profile size budget
  per persona (call centre small, devs large).
- Validate the chosen share tier delivers the peak-logon IOPS; see `avd-fslogix`.

## Output

A persona table: `persona | users | peak concurrency | pool type | VM family/SKU |
users/host | hosts | profile size | storage tier`. Every column traceable to a rule above.
