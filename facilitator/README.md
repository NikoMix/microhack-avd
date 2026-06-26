# Facilitator kit (Train-the-Trainer)

> **Status:** run-of-day fixed here; full facilitator guide + per-challenge talk tracks are
> delivered by the facilitator workstream. Trainer-only content.

This MicroHack is delivered **Train-the-Trainer**: attendees are consultants who will later run
it for their own customers. So you teach **both** the AVD Module B content **and** how to
facilitate it.

## Run of day (≈ 7.5 h incl. breaks)

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
| 17:30 | Debrief, **teardown check**, TtT tips, close | — | Confirm every learner ran `scripts/reset/` |

> Timings are a guide. The deploy challenge (C05) is the most likely to overrun — protect its
> 75-minute slot and keep the footprint tiny.

## Before the day (trainer checklist)

- [ ] Every learner has Copilot + an Azure subscription with budget rights.
- [ ] Confirm vCPU quota in the lab region for the chosen VM family (raise a quota request early).
- [ ] Dry-run C00 → C06 end to end yourself; time the deploy on the day's region.
- [ ] Decide the IaC track(s) you'll demo (Bicep, Terraform, or both).
- [ ] Have a fallback Azure subscription for tenant/login issues.

## During the day

- **Lead with the agent**, then show the manual path — that contrast is the lesson.
- Use the [`/review-evidence`](../.github/prompts/review-evidence.prompt.md) prompt to grade
  artifacts live; it models the auditor mindset.
- Watch cost: anyone who deploys must have a budget; everyone tears down before they leave.

## After the day

- Collect feedback as GitHub issues (the **challenge-feedback** and **lesson-learned** templates).
- Verify no learner left Azure resources running.

See [`solutions/`](../solutions/) for the worked keys and (when delivered) per-challenge talk
tracks alongside each challenge.
