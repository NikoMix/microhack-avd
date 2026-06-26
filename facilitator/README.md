# Facilitator kit (Train-the-Trainer)

> Trainer-only. Everything you need to run AVD Module B as a 1-day, classroom-led MicroHack with
> little supervision.

This MicroHack is delivered **Train-the-Trainer**: attendees are consultants who will later run it
for their own customers. So you teach **both** the AVD Module B content **and** how to facilitate it
with the agentic toolkit (Copilot agents, skills and MCP servers). On-screen decks live in
[`slides/`](../slides/README.md).

## What's in this kit

| File | Use it for |
|---|---|
| [`run-of-day.md`](run-of-day.md) | The minute-by-minute timetable (09:00–18:00), block objectives, timing rules, and an 8-hour compressed variant |
| [`facilitator-guide.md`](facilitator-guide.md) | TtT philosophy, the repeatable per-challenge loop, talk tracks for C00–C07, pitfalls, and the debrief |
| [`delivery-checklist.md`](delivery-checklist.md) | Prep timeline, the **agent + MCP rehearsal**, day-of checklist, and fallback plans |
| [`cost-and-cleanup.md`](cost-and-cleanup.md) | Budgets, required tags, cost levers, and the end-of-day **teardown gate** |

New to the kit? Read this page, then rehearse with the
[delivery checklist](delivery-checklist.md#rehearsal-the-critical-prep).

## Course learning objectives

By the end of the day, learners can:

- **Name the toolkit** — the eight `avd-*` agents, the auto-activating skills, and the four MCP
  servers, and explain the **control → agent → evidence** map.
- **Run the loop** — *frame → adopt the lead agent → demo a beat → hand off → hold the gate* — for
  any challenge.
- **Produce the evidence** — the named artifact for each control B.1.1 → B.4.2.
- **Hold the scenario** — reconcile Contoso to **700 / 200 / 60 / 40 = 1,000** users and design
  Entra-join + Intune with FSLogix on Azure Files Premium.
- **Deploy safely** — guardrails first, **what-if/plan before apply**, token scale, and **teardown**.
- **Facilitate it themselves** — rehearse the agents + MCP and run the day for their own customer.

## Run of day

**≈9 h elapsed (09:00–18:00)**, of which **≈7 h is hands-on** (the eight challenge time-boxes). Full
detail and the compressed 8-hour variant are in [`run-of-day.md`](run-of-day.md).

| Time | Block | Control | Facilitation note |
|---|---|---|---|
| 09:00 | Welcome, objectives, TtT framing | — | Start Codespaces building **now** |
| 09:15 | Plenary: AVD + Module B + the agentic toolkit | — | Demo the agents/skills/MCP live |
| 09:30 | **C00** Setup & guardrails | — | Everyone reaches a deployed budget |
| 10:15 | **C01** Workload assessment | B.1.1 | `avd-assessor`; reconcile the numbers |
| 11:15 | Break | — | |
| 11:30 | **C02** Solution design (HLD) | B.2.1 | `avd-architect`; diagram + decisions |
| 12:30 | Lunch | — | |
| 13:15 | **C03** Well-Architected review | B.2.2 | `avd-waf-reviewer`; Cost/Perf/Reliability |
| 14:00 | **C04** PoC / Pilot | B.2.3 | `avd-pilot-lead`; quantitative criteria |
| 14:45 | Break | — | |
| 15:00 | **C05** Deploy to production | B.3.1 | `avd-deployment-engineer`; what-if first |
| 16:15 | **C06** Service validation | B.4.1 | `avd-test-engineer`; evidence not assertion |
| 17:00 | **C07** Handover documentation | B.4.2 | `avd-handover-writer`; as-built |
| 17:45 | Debrief, **teardown check**, TtT tips, close | — | Confirm every learner has torn down |

> Timings are a guide. The deploy challenge (C05) is the most likely to overrun — protect its
> 75-minute slot and keep the footprint tiny.

## Go/no-go gates

Each challenge ends on a gate. **Hold them** — trim manual contrasts and stretch goals when time is
tight, never a gate.

| Challenge | Gate (don't advance until…) |
|---|---|
| C00 | A **budget** is deployed and the correct subscription is selected |
| C01 | Numbers **reconcile to 1,000** and sizing **shows its math** |
| C02 | Every component is **justified** and its **AVM module is named + pinned** |
| C03 | Findings are **prioritised** and **specific** to the HLD, with a decision register |
| C04 | Success criteria are **numbers** with a measurement method |
| C05 | **Budget exists** and **what-if/plan reviewed** before apply; deploy at token scale |
| C06 | Each C04 criterion has a **measured** pass/fail |
| C07 | The **LLD reflects as-built** reality and the pack is complete |
| Close | The `azure` MCP shows **nothing left running** |

## Before the day (trainer checklist)

Full prep timeline and the rehearsal are in [`delivery-checklist.md`](delivery-checklist.md). In
short:

- [ ] Every learner has Copilot + an Azure subscription with budget rights.
- [ ] Confirm vCPU quota in `swedencentral` for the chosen VM family (raise a quota request early).
- [ ] **Rehearse** the agents + skills + MCP and **dry-run/time C05** end to end yourself.
- [ ] Decide the IaC track(s) you'll demo (Bicep, Terraform, or both).
- [ ] Have a fallback subscription and a recorded C05 for login/quota issues.

## During the day

- **Lead with the agent**, then show the manual path — that contrast is the lesson.
- Use the [`/review-evidence`](../.github/prompts/review-evidence.prompt.md) prompt to grade
  artifacts live; it models the auditor mindset.
- Watch cost: anyone who deploys must have a budget; everyone tears down before they leave (see
  [`cost-and-cleanup.md`](cost-and-cleanup.md)).

## After the day

- Collect feedback as GitHub issues (the **challenge-feedback** and **lesson-learned** templates).
- Verify no learner left Azure resources running — the `azure` MCP should show empty resource groups.

See [`solutions/`](../solutions/) for the worked keys alongside each challenge.
