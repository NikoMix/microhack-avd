# Run of day — minute-by-minute

> Trainer-only. The **full timetable** for the 1-day, classroom-led delivery. Pairs with the
> [facilitator guide](facilitator-guide.md) (talk tracks + pitfalls), the
> [delivery checklist](delivery-checklist.md) (prep + rehearsal), and
> [cost & cleanup](cost-and-cleanup.md).

This is an **intensive day**: **≈9 h elapsed (09:00–18:00)**, of which **≈7 h is hands-on**
(the eight challenge time-boxes) and the rest is plenary, breaks and lunch. The per-challenge
time-boxes match [`challenges/README.md`](../challenges/README.md) exactly. A
[compressed 8-hour variant](#compressed-delivery-8-hours) is below.

## Schedule at a glance

| Start | End | Dur | Block | Control | Lead agent |
|---|---|---|---|---|---|
| 09:00 | 09:15 | 15 | Welcome & TtT framing | — | — |
| 09:15 | 09:30 | 15 | Plenary: agentic toolkit + Contoso (live demo) | — | `avd-engagement-lead` |
| 09:30 | 10:15 | 45 | **C00** Setup & guardrails | — | `avd-engagement-lead` |
| 10:15 | 11:15 | 60 | **C01** Workload assessment | B.1.1 | `avd-assessor` |
| 11:15 | 11:30 | 15 | Break | — | — |
| 11:30 | 12:30 | 60 | **C02** Solution design (HLD) | B.2.1 | `avd-architect` |
| 12:30 | 13:15 | 45 | Lunch | — | — |
| 13:15 | 14:00 | 45 | **C03** Well-Architected review | B.2.2 | `avd-waf-reviewer` |
| 14:00 | 14:45 | 45 | **C04** PoC / Pilot | B.2.3 | `avd-pilot-lead` |
| 14:45 | 15:00 | 15 | Break | — | — |
| 15:00 | 16:15 | 75 | **C05** Deploy to production | B.3.1 | `avd-deployment-engineer` |
| 16:15 | 17:00 | 45 | **C06** Service validation | B.4.1 | `avd-test-engineer` |
| 17:00 | 17:45 | 45 | **C07** Handover documentation | B.4.2 | `avd-handover-writer` |
| 17:45 | 18:00 | 15 | Debrief, **teardown check**, close | — | — |

**Totals:** hands-on 420 min · plenary/welcome/debrief 45 min · breaks + lunch 75 min = **540 min**.

## Block-by-block

- **09:00 · Welcome & TtT framing (15)** — objective: set the two-layer Train-the-Trainer contract
  (content *and* delivery). Facilitation: **start the Codespace build now** — it is the morning
  long pole. Open the [welcome deck](../slides/00-welcome.md).
- **09:15 · Plenary (15)** — objective: learners can name the agents, skills and MCP servers and
  the control → evidence map. Facilitation: **demo live** — adopt `avd-engagement-lead`, run
  [`/start-engagement`](../.github/prompts/start-engagement.prompt.md), and smoke-test the
  `microsoft-learn` MCP. Keep it to one crisp loop.
- **09:30 · C00 Setup & guardrails (45)** — objective: working env + **a deployed budget**.
  Gate: **nobody proceeds without a budget.** Facilitation: circulate; the long poles are the
  Codespace build and `az login`. See [`challenges/challenge-00-setup/`](../challenges/challenge-00-setup/).
- **10:15 · C01 Workload assessment (60)** — objective: defensible personas, app delivery
  decisions, image strategy, sizing. Gate: numbers **reconcile to 1,000** and sizing **shows its
  math**. Facilitation: demo `avd-assessor`; reconcile 700 / 200 / 60 / 40.
- **11:30 · C02 Solution design / HLD (60)** — objective: a buildable, AVM-first HLD with a
  decision per component. Gate: every component **justified**; AVM modules **named + pinned**.
  Facilitation: show the AVM module map, then open [`infra/`](../infra/).
- **13:15 · C03 Well-Architected review (45)** — objective: prioritised, AVD-specific findings +
  decision register. Gate: findings **prioritised** and **specific**. Facilitation: challenge any
  generic finding; force it back to a pillar + an HLD decision.
- **14:00 · C04 PoC / Pilot (45)** — objective: bounded pilot with **quantitative** success
  criteria + a go/no-go rule. Gate: criteria are **numbers, not adjectives**. Facilitation: replace
  every *"it works"* with a target + a measurement method.
- **15:00 · C05 Deploy to production (75)** — objective: live AVD at **token scale** via AVM, with
  Go-Live + cutover/rollback. Gate: **budget exists** and **what-if/plan reviewed** before apply.
  Facilitation: this is **the overrun risk** — protect the slot, keep it to **1–2 hosts**, have a
  fallback ready. The **what-if → apply** moment is the headline demo.
- **16:15 · C06 Service validation (45)** — objective: measured pass/fail against the C04 criteria,
  incl. FSLogix integrity. Gate: **measured, not asserted.** Facilitation: pre-stage tests in your
  dry-run so live time is spent on results.
- **17:00 · C07 Handover documentation (45)** — objective: as-built handover pack + sign-off.
  Gate: **LLD reflects as-built reality.** Facilitation: show the agent reading live Azure for the
  LLD; contrast with the C02 design intent.
- **17:45 · Debrief & teardown check (15)** — objective: reinforce the chain and the agentic
  pattern; **confirm every learner has torn down.** Gate: **`azure` MCP shows nothing left
  running.** Collect feedback as GitHub issues.

## Timing rules

1. **Protect C05 (75 min).** It is the single most likely block to overrun. If you are behind,
   pre-deploy the slice during lunch or fall back to a recording — never skip the what-if demo.
2. **Trim manual fallbacks, not gates.** When time is tight, shorten the manual contrast and the
   stretch goals; never skip a Definition-of-done gate.
3. **Start the Codespace build at 09:00.** Don't wait for the plenary to finish.
4. **Two 15-minute breaks + 45-minute lunch are load-bearing** — the day is dense; keep them.
5. **Budget the buffer into C05 and C07.** Both have natural compression room (smaller footprint,
   template-driven docs) if earlier blocks run long.

## Compressed delivery (8 hours)

To fit an 8-hour day (≈480 min, e.g. 09:00–17:00 with a 30-minute lunch), keep all eight gates but
recover ~60 minutes:

- **Pre-deploy the C05 slice** before class and demo the what-if against the existing stack — saves
  ~20 min of live deploy.
- **Run C03 and C06 as guided plenary** rather than fully hands-on — saves ~20 min.
- **Lunch 30 min**, drop one break to 10 min — saves ~20 min.

> Do not compress C00 (the budget gate) or the debrief teardown check — those protect cost.

## What's next

- Per-challenge talk tracks, demos and pitfalls → [facilitator guide](facilitator-guide.md).
- Prep and rehearsal of the agents + MCP → [delivery checklist](delivery-checklist.md).
- Budgets, monitoring and teardown → [cost & cleanup](cost-and-cleanup.md).
