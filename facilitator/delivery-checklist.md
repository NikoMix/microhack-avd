# Delivery checklist

> Trainer-only. Everything to do **before** and **on** the day so you can run this with little
> supervision. Pairs with the [run of day](run-of-day.md), [facilitator guide](facilitator-guide.md)
> and [cost & cleanup](cost-and-cleanup.md).

The single most valuable prep is the [rehearsal](#rehearsal-the-critical-prep) — a full dry-run of
the agents, skills and MCP servers, ending on an empty resource group.

## Two weeks before

- [ ] Confirm the **paid Azure subscription** for the class and your access to it.
- [ ] Check **regional quota** in `swedencentral` for the session-host VM family you'll demo (a
      handful of vCPUs is enough at token scale) using the `azure` MCP quota tools.
- [ ] Confirm attendees can reach **GitHub Codespaces** and **Microsoft Entra** from their network.
- [ ] Decide the IaC track you'll demo live — **Bicep** ([`infra/bicep/`](../infra/bicep/)) or
      **Terraform** ([`infra/terraform/`](../infra/terraform/)) — and rehearse that one end to end.
- [ ] Send the [attendee pre-reads](#attendee-pre-reads).

## Three days before

- [ ] Run the **full [rehearsal](#rehearsal-the-critical-prep)** once, start to finish, and time C05.
- [ ] Build the slide decks (`cd slides && npm install && npm run build`) and skim every deck on a
      projector-sized screen for overflow.
- [ ] Verify the **budget + auto-shutdown** scripts in [`scripts/`](../scripts/) deploy cleanly.
- [ ] Prepare your **fallbacks**: a recorded C05 what-if → apply, and a pre-deployed slice you can
      fall back to (see [fallback plans](#fallback-plans)).
- [ ] Draft the engagement **GitHub issues** (one per challenge) so the task board is ready.

## Rehearsal (the critical prep)

Do this in a clean Codespace, exactly as a learner would. The goal is muscle memory for the
**agent + MCP** loop and a known-good timing for C05.

### Agents & skills

- [ ] Open the **agent picker** and confirm all **eight `avd-*` agents** are present and selectable.
- [ ] Adopt [`avd-engagement-lead`](../.github/agents/avd-engagement-lead.agent.md) and run
      [`/start-engagement`](../.github/prompts/start-engagement.prompt.md); confirm it **reads the
      scenario** from [`scenario/`](../scenario/README.md) and proposes the plan.
- [ ] Trigger each **skill** by talking about its topic (sizing, FSLogix, WAF, cost, migration) and
      confirm it **auto-activates** — note the phrases that fire it so you can reproduce them live.
- [ ] Hand off lead → specialist once (e.g. lead → `avd-assessor`) and confirm state carries over.

### MCP smoke tests

From [`.vscode/mcp.json`](../.vscode/mcp.json):

- [ ] `github` — list issues / open a test issue, then close it.
- [ ] `azure` — `account show`, list resource groups, read the budget; confirm the right
      subscription.
- [ ] `microsoft-learn` — fetch one AVD doc; confirm grounding works offline of your memory.
- [ ] `terraform` — look up one AVM module version (only if you'll demo the Terraform track).

### Dry-run the deploy (time it)

- [ ] Deploy the **budget** first (C00 gate).
- [ ] Run `az deployment ... what-if` (Bicep) or `terraform plan` (Terraform); **read the diff**.
- [ ] Apply **1–2 session hosts**; record the wall-clock time — this is your C05 budget.
- [ ] Run a C06 validation pass so you can pre-stage tests for class.
- [ ] **Tear down** and confirm via the `azure` MCP that the resource group is **empty**.

> If the timed deploy exceeds ~25 minutes, plan to **pre-deploy the slice** before class and demo
> the what-if against it (see [run of day → compressed](run-of-day.md#compressed-delivery-8-hours)).

## Day of — before the room fills

- [ ] Subscription + budget confirmed (`azure` MCP `account show` + budget present).
- [ ] Your Codespace warm; agent picker shows the eight `avd-*` agents.
- [ ] Decks open in presenter view; [`00-welcome.md`](../slides/00-welcome.md) up.
- [ ] Engagement issues created; the board is visible.
- [ ] Fallback recording + pre-deployed slice ready.
- [ ] Room/AV: projector resolution checked against the decks; network for Codespaces + Entra
      verified from the room.
- [ ] Cost dashboard open in a side tab for spot-checks during C05 (see
      [cost & cleanup](cost-and-cleanup.md)).

## Fallback plans

| Risk | Trigger | Fallback |
|---|---|---|
| Codespace build slow | C00 running long | Start builds at 09:00; pair learners; proceed on the plenary while builds finish |
| `az login` failures | Several learners stuck | Use device-code flow; verify subscription with `account show`; have a shared screen demo |
| C05 deploy overruns | Past ~16:00 | Switch to the **pre-deployed slice** + recorded what-if; keep the gate, skip the wait |
| Quota denied | what-if/plan errors | Smaller VM family / fewer hosts; you only need 1–2 at token scale |
| MCP server unavailable | Smoke test fails | Fall back to docs/CLI for that step; note it and continue; agents still work |
| Time pressure overall | Behind by a block | Trim manual contrasts + stretch goals, **never a gate** (see run of day → timing rules) |

## Attendee pre-reads

Send these ahead so class time is hands-on, not setup:

- Repo [`README.md`](../README.md) and [`challenges/README.md`](../challenges/README.md) — the
  control → agent → evidence map.
- [`challenges/challenge-00-setup/`](../challenges/challenge-00-setup/) — so environments are warm.
- [`scenario/README.md`](../scenario/README.md) — the Contoso brief (1,000 users, RDS/Citrix → AVD).
- A note that this is **OSS-only** and runs on a **paid subscription** with **guardrails + teardown**.
