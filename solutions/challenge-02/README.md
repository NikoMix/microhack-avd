# Solution key — Challenge 02 · Solution design / HLD (B.2.1)

> ⚠️ **Trainers only.** Reference answer for [Challenge 02](../../challenges/challenge-02-solution-design/).
> Learners should attempt it with `avd-architect` first.

**Worked artifact:** [`hld.md`](hld.md) — a complete, buildable B.2.1 High-Level Design.

## Why this answer is defensible

- **Directly buildable** — every domain names the **AVM module** that implements it, with a
  **pinned version verified against the Terraform Registry** (host-pool `0.4.0`, scaling-plan
  `0.2.1`, storage `0.7.3`, vnet `0.19.0`, …). Names/params line up with
  [`infra/README.md`](../../infra/README.md).
- **Reconciles with the assessment** — four host pools map 1:1 to the four personas;
  `maxSessionLimit` = the per-host density from C01 (25 KW / 30 CC); FSLogix is the same ≥ 5 TiB
  Premium share sized for logon-storm IOPS.
- **Decisions, not descriptions** — a 10-row register with options-considered + justification for
  every significant choice (pool model, identity, ANF threshold, ZRS, Cloud Cache, load balancing,
  connectivity, Shortpath, personal-host cost control).
- **Honours the conventions** — Entra join + Intune default, Files Premium + Kerberos, naming
  `<type>-avd-<env>-sec`, required tags, `swedencentral`.

## Teaching points

- **AVM-first + pin + verify.** The version table models the right behaviour: pin a version and
  confirm it via the `terraform` MCP / AVM index at build time. Note Bicep AVM versions differ from
  Terraform — don't copy one into the other.
- **Hybrid join is a fallback, not a default.** The honest answer keeps Entra join and pushes the
  LOB CRM smartcard/Kerberos question into the **pilot** rather than reflexively going hybrid.
- **BreadthFirst vs DepthFirst** is the classic UX-vs-cost AVD trade-off — BreadthFirst wins for a
  logon-storm-heavy population; DepthFirst is the cost lever the WAF review may revisit.

## Common ways learners go wrong (pre-empt these)

| Mistake | Why it's wrong | Steer them to |
|---|---|---|
| Domains described, no **AVM module** named | "Buildable" is the B.2.1 bar | name the module + pin a version |
| Re-sizes FSLogix differently from C01 | Breaks traceability | carry the ≥ 5 TiB Premium share forward |
| Default to **hybrid join** everywhere | Re-introduces the AD dependency AVD removes | Entra join; hybrid only where an app forces it |
| No **BCDR** objectives | Auditor expects RTO/RPO | state realistic RTO/RPO + backup |
| One giant host pool | Can't tune image/density/scaling per persona | per-persona pools |
| No decisions register | Descriptions aren't decisions | options + choice + justification |
| Copies a Bicep version into Terraform (or vice-versa) | The two AVM lines version independently | pin each track separately |

## Hand-off

The HLD is the contract for `avd-waf-reviewer` (C03), `avd-pilot-lead` (C04), and the deployment
work (C05). Fix-now WAF findings must be folded back into this document before production.
