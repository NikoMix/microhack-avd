---
name: avd-cost-guardrails
description: Cost-safety guardrails for running real AVD deployments in a classroom on a paid Azure subscription. Use before and during any deploy challenge to put budgets, auto-shutdown, small SKUs, and teardown in place so learners never run up a surprise bill.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# AVD cost guardrails

This MicroHack deploys **real** Azure resources on the learner's **own paid subscription**.
Cost safety outranks speed. Apply these before any session host exists, and always tear down.

## Before deploying (mandatory)

1. **Budget + alert** — deploy a Consumption budget (e.g. €/$50 lab cap) with email alerts at
   50/80/100%. Use `scripts/setup/`. Confirm via the **`azure` MCP** cost tools.
2. **Auto-shutdown** — schedule session-host deallocation outside class hours.
3. **Quota check** — confirm vCPU quota for the chosen family/region via the `azure` MCP
   (`quota`, `region`) before deploying — avoids half-built stacks.

## While deploying

- **Small SKUs, 1–2 hosts.** The ~1,000-user Contoso footprint is a **paper design**; deploy a
  token slice only.
- **`what-if` / `plan` first**, every time. Read back the cost shape before apply.
- Prefer **pooled multi-session** for the lab (fewer VMs) unless testing personal pools.
- Stop hosts when not actively testing (autoscale ramp-down or manual deallocate).

## After deploying (mandatory)

- **Tear down** with `scripts/reset/` — deletes the resource group / AVD objects and confirms
  nothing is left running.
- Verify deletion via the `azure` MCP (list resources in the RG → empty).
- Leave the **budget** until you've confirmed zero ongoing spend.

## Cost levers (teach these)

| Lever | Effect |
|---|---|
| Autoscale (time + demand) | Biggest single saver — pay for hosts only when used |
| Right-sized SKUs per persona | Avoid oversizing "to be safe" |
| Pooled multi-session | Fewer VMs per user vs personal |
| Files Standard vs Premium | Only pay Premium where IOPS needs it |
| Reserved Instances / savings plan | Steady personal hosts |
| Log retention/ingestion caps | Control Log Analytics spend |

> If a learner is about to deploy without a budget, **stop them** and point here first.
