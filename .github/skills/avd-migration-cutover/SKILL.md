---
name: avd-migration-cutover
description: Migration patterns from on-premises RDS and Citrix to Azure Virtual Desktop — discovery mapping, wave planning, coexistence, cutover, and rollback. Use when planning how Contoso moves ~1,000 users off legacy VDI without a big-bang risk.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# RDS / Citrix → AVD migration & cutover

Use when planning the move off legacy VDI. The goal is **wave-based, reversible** migration with
coexistence, not big-bang. Ground AVD-side specifics in the **`microsoft-learn` MCP**.

## Map legacy → AVD

| Legacy (RDS / Citrix) | AVD equivalent |
|---|---|
| RDSH session collection / Citrix delivery group | Host pool (pooled multi-session) |
| Published desktop | Desktop application group |
| Published app (RemoteApp / Citrix published app) | RemoteApp application group |
| Citrix MCS/PVS golden image | Azure Image Builder → Compute Gallery |
| UPM / roaming profiles | FSLogix profile containers |
| Citrix StoreFront / Web | AVD workspace + client / web client |
| NetScaler / Gateway | AVD service (no gateway VMs) + Conditional Access |
| Citrix Director / RDS perf | AVD Insights + Log Analytics |

## Wave plan

1. **Discovery** — inventory users, apps, peripherals, GPU/legacy dependencies (MAP / Azure
   Migrate / Citrix Director). Feeds B.1.1.
2. **Pilot wave** — representative slice per persona; validate against success criteria (B.2.3).
3. **Persona waves** — migrate by persona/department, lowest-risk first (knowledge workers →
   call centre → power users → developers). Each wave has entry/exit criteria.
4. **Coexistence** — run AVD and legacy in parallel during the window; shared profiles strategy
   and app access for both; network peering to on-prem resources.
5. **Decommission** — only after the last wave validates; reclaim Citrix/RDS licences and infra.

## Cutover checklist (per wave)

- Comms sent; users know the new client + URL.
- Profiles seeded/migrated; app access verified for the wave's app set.
- Conditional Access + licensing assigned (Win 11 multi-session entitlement).
- Validation gate passed (logon, app launch, profile) before declaring the wave done.

## Rollback

- Keep the legacy collection/delivery group **live** until the wave passes validation.
- Per-wave fallback: re-point users to legacy, no data loss (profiles still intact).
- Document the rollback trigger conditions and the exact steps — this is required B.3.1 evidence.
