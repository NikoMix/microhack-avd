# Challenge 07 — Handover documentation

> **Module B control:** B.4.2 — Handover Documentation · **Time-box:** 45 min ·
> **Lead agent:** `avd-handover-writer` · **Evidence:** `work/handover/{lld,runbook,kt-plan,hypercare,signoff,lessons-learned}.md`

## Objective

Turn the engagement's evidence into a coherent **operational handover pack** the customer can run
the platform with: an **as-built Low-Level Design**, a day-2 **operations runbook**, a
**knowledge-transfer plan**, a **hypercare plan**, a **customer sign-off**, and **lessons learned**.
This is the billable deliverable that closes the engagement.

## Prerequisites

- Completed [Challenge 05](../challenge-05-deploy-to-production/) and
  [Challenge 06](../challenge-06-service-validation/) — `deployment.md` and `validation.md`.
- The HLD (`work/hld.md`) and assessment (`work/assessment.md`) from earlier challenges.

## The agentic way (do this first)

1. **Agent:** adopt **`avd-handover-writer`** — ask it to assemble the six handover documents from
   the existing evidence and the **actual deployed resources**.
2. **Skill:** it draws on `avd-landing-zone` (LLD detail), `avd-fslogix` (profile operations),
   `avd-cost-guardrails` (run-rate), and `avd-migration-cutover` (the cutover record).
3. **MCP:** `azure` to pull live resource names / IDs into the LLD; `microsoft-learn` for ops
   guidance; `github` for the task board and sign-off trail.

> The point of this MicroHack is the agentic workflow. Use the agent to draft, then **you** apply
> the consulting judgement and verify.

## Steps

Copy the six templates from
[`.github/skills/avd-evidence-pack/templates/handover/`](../../.github/skills/avd-evidence-pack/templates/handover/)
into `work/handover/` and complete each:

1. **`lld.md`** — the **as-built** low-level design: actual resource names, IDs, SKUs, subnets,
   FSLogix share, and identity config pulled from the deployment (not placeholders).
2. **`runbook.md`** — day-2 operations: scaling, image/update cadence, FSLogix maintenance,
   patching, monitoring/alerts, and the top incidents with first-response steps.
3. **`kt-plan.md`** — knowledge-transfer sessions, audiences, and the ownership-transfer schedule.
4. **`hypercare.md`** — hypercare duration, severity definitions, contacts, and exit criteria.
5. **`signoff.md`** — the acceptance checklist mapped to the success criteria, plus signatures.
6. **`lessons-learned.md`** — what went well / badly and concrete follow-up actions.

When the evidence is captured, **tear the lab down** with
[`scripts/reset/`](../../scripts/reset/) — handover does not need a running environment.

## Definition of done (acceptance criteria)

- [ ] All six `work/handover/*.md` exist and follow their templates.
- [ ] The **LLD reflects the actually-deployed** names / IDs (verified via the `azure` MCP).
- [ ] The runbook covers scaling, FSLogix, image updates, monitoring, and rollback.
- [ ] Sign-off maps acceptance criteria to the validated results from B.4.1.
- [ ] Lessons learned has **concrete, owned** follow-up actions.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md) prompt → **PASS**.
- [ ] Lab **torn down** (`scripts/reset/`) after the evidence is captured.

## Stretch goals

- Produce a one-page **executive summary** of the engagement and outcomes.
- Add a **cost run-rate appendix** (steady-state vs lab) from `avd-cost-guardrails`.
- Record (or storyboard) one KT session from the plan.

<details>
<summary>Trainer notes</summary>

- **Timing:** six documents in 45 minutes — split them across pairs/tables. The agent drafts fast;
  the value is the learner **curating** for accuracy and customer-readiness.
- **Common pitfalls:** an LLD full of template placeholders instead of real deployed values; a
  generic runbook that isn't specific to this build; forgetting the **teardown** at the end.
- **Talking points:** the handover pack is the **deliverable that gets paid for**; as-built
  accuracy and sign-off discipline are what separate a consultant from a script-runner.
- **Solution key:** [`solutions/challenge-07/`](../../solutions/challenge-07/).

</details>

## What's next

→ Engagement complete. Assemble the full evidence pack across all challenges and run
[`/review-evidence`](../../.github/prompts/review-evidence.prompt.md) over every artifact, then
confirm the lab is torn down. See the [`solutions/`](../../solutions/) keys to compare.
