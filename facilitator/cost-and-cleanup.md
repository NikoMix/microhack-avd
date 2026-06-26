# Cost & cleanup

> Trainer-only. This MicroHack runs on a **paid Azure subscription**. Cost discipline is part of
> the teaching, not an afterthought. Pairs with the [delivery checklist](delivery-checklist.md) and
> the [facilitator guide](facilitator-guide.md).

The golden rule: **guardrails before resources, teardown before you leave.** The day opens on a
budget (C00) and closes on an empty resource group (debrief).

## Principles

- **Paper design, token-scale deploy.** Contoso is **1,000 users**; the class deploys **1–2 session
  hosts**. The full footprint is never built in the room.
- **Budget first.** No session host is created before the budget + auto-shutdown from
  [`scripts/`](../scripts/) is deployed. This is the C00 gate.
- **Preview before apply.** Every `apply`/`create` follows a `what-if` (Bicep) or `plan` (Terraform)
  so cost surprises are caught before they spend.
- **One resource group per learner**, tagged, so cleanup is a single delete and spend is attributable.

## Required tags

Every resource carries these (from the repo conventions) so spend is attributable and cleanup is
scriptable:

| Tag | Value |
|---|---|
| `workload` | `avd-microhack` |
| `env` | `lab` |
| `owner` | learner alias |
| `costCenter` | `training` |
| `autoDelete` | `true` |

## Cost levers

Pull these to keep the lab cheap without losing the learning:

| Lever | Default | Why |
|---|---|---|
| Session hosts | **1–2** | Enough to demo pooled + personal; never the full 1,000-user footprint |
| VM family | Small / current-gen | A few vCPUs renders the experience at token scale |
| Auto-shutdown | **On** (C00) | Stops idle hosts billing overnight |
| Storage | Azure Files Premium, smallest viable | Demonstrates FSLogix without provisioning for 1,000 |
| Region | `swedencentral` | Consistent quota + pricing for the class |
| Lifetime | Hours, not days | Deploy in C05, validate in C06, tear down at debrief |

## During class

- [ ] Confirm the **budget exists** before C05 (`azure` MCP — read the budget; C00 should have
      created it).
- [ ] Keep a **cost view open** in a side tab; spot-check during and after C05.
- [ ] If spend trends high, **reduce host count** rather than abandoning the deploy — 1 host still
      demonstrates the gate.
- [ ] Watch for **forgotten what-if** — applying without previewing is the usual cause of surprise
      spend.

## Teardown (end of day — a gate, not a nicety)

Run this in the debrief block; **do not let the room leave until it's done.**

1. **Tear down with the reset scripts** in [`scripts/`](../scripts/) (or
   `az group delete` / `terraform destroy` for the lab resource group).
2. **Verify empty** with the `azure` MCP: list the resource group's resources — it should return
   **nothing**. An empty group (or a deleted group) is the proof.
3. **Confirm no orphans:** check for stray disks, public IPs, NICs, or storage accounts outside the
   group that carry the `workload=avd-microhack` tag.
4. **Leave the budget in place** until you've confirmed zero running resources, then remove it if the
   subscription is being released.

> **Post-class verification:** the next day, re-check the `azure` MCP cost view for the class
> resource groups — spend should flatten to zero. If it doesn't, hunt the `autoDelete=true` tag.

## If something is left running

- Filter by tag `workload=avd-microhack` across the subscription and delete what remains.
- Personal host pools and their VMs are the most common leftovers — they don't scale to zero like
  pooled hosts do.
- Storage accounts and managed disks bill even when hosts are stopped — delete the **resource
  group**, not just the VMs.
