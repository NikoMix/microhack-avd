# Challenges — the Contoso AVD Module B engagement

Eight challenges take you through a complete **AVD Advanced Specialization Module B** engagement
for **Contoso**, using GitHub Copilot **agents, skills, and MCP servers** at every step. Each
challenge maps to a Module B control and produces the **evidence artifact** an auditor expects.

> **New here?** Read the root [`README.md`](../README.md) and
> [`scenario/`](../scenario/) first, then start at **Challenge 00**.

## Run of day (1-day, classroom-led)

| # | Challenge | Control | Time-box | Lead agent | Evidence artifact |
|---|---|---|---|---|---|
| 00 | [Setup & guardrails](challenge-00-setup/) | — | 45 min | `avd-engagement-lead` | Working env + cost cap |
| 01 | [Workload assessment](challenge-01-workload-assessment/) | B.1.1 | 60 min | `avd-assessor` | `assessment.md` |
| 02 | [Solution design (HLD)](challenge-02-solution-design/) | B.2.1 | 60 min | `avd-architect` | `hld.md` |
| 03 | [Well-Architected review](challenge-03-well-architected-review/) | B.2.2 | 45 min | `avd-waf-reviewer` | `waf-review.md` |
| 04 | [PoC / Pilot](challenge-04-poc-pilot/) | B.2.3 | 45 min | `avd-pilot-lead` | `pilot.md` |
| 05 | [Deploy to production](challenge-05-deploy-to-production/) | B.3.1 | 75 min | `avd-deployment-engineer` | `deployment.md` |
| 06 | [Service validation](challenge-06-service-validation/) | B.4.1 | 45 min | `avd-test-engineer` | `validation.md` |
| 07 | [Handover documentation](challenge-07-handover-documentation/) | B.4.2 | 45 min | `avd-handover-writer` | LLD + runbook + KT + sign-off |

_Total ~7.5 h including breaks. See [`facilitator/`](../facilitator/) for the minute-by-minute
timetable, break placement, and the Train-the-Trainer guidance._

## How each challenge works

1. **Adopt the lead agent** (`avd-engagement-lead`) to orchestrate, or jump straight to the
   challenge's specialist agent.
2. **Do it the agentic way** — every challenge shows which **agent / skill / MCP** to use first,
   then a manual fallback.
3. **Produce the evidence** — copy the matching template from the `avd-evidence-pack` skill into
   the challenge's `work/` folder and fill it in.
4. **Pass the gate** — check your artifact against the **Definition of done** before moving on.

## Tracks

- **IaC:** Challenges 05–06 run on either the **Bicep** or **Terraform** track — both deploy the
  same landing zone. Pick one (or try both). See [`infra/`](../infra/).
- **Footprint:** Live deploys use a **tiny lab slice** (1–2 session hosts). Contoso's full
  ~1,000-user design stays on paper. Guardrails + teardown are in [`scripts/`](../scripts/).

## Solutions

Worked solution keys live in [`solutions/`](../solutions/) — for **trainers**. Learners should
attempt each challenge before peeking.
