# Facilitator guide

> Trainer-only. The **talk tracks** for delivering AVD Module B as a Train-the-Trainer MicroHack.
> Pair it with the [run of day](run-of-day.md) (timing), the
> [delivery checklist](delivery-checklist.md) (prep + rehearsal) and
> [cost & cleanup](cost-and-cleanup.md) (guardrails). On-screen decks live in
> [`slides/`](../slides/README.md).

## Train-the-Trainer philosophy

You are teaching **two things at once**:

1. **The content** — how a partner runs an AVD Advanced Specialization *Module B* engagement and
   produces the audit evidence (controls B.1.1 → B.4.2).
2. **The delivery** — how to *teach it* with the agentic toolkit, so your learners can run this day
   themselves.

Three principles carry the whole day:

- **Lead with the agent, not the answer.** Adopt the lead agent for each phase and let it work the
  scenario in front of the room. The learners should see *the agent reasoning*, then refine its
  output — not watch you type the answer you already knew.
- **Evidence is the unit of done.** Every challenge produces a named artifact mapped to a control.
  If there's no artifact, the control isn't met. Hold the gate.
- **Paper design, token-scale deploy.** Contoso is **1,000 users**; the lab deploys **1–2 session
  hosts**. Say this out loud at C02 and again at C05 so nobody tries to build the full footprint.

## The agentic toolkit in one screen

Open this on the plenary and refer back to it all day:

- **Custom agents** ([`.github/agents/`](../.github/agents/)) — one
  [`avd-engagement-lead`](../.github/agents/avd-engagement-lead.agent.md) orchestrator plus one
  specialist per control. The lead tracks engagement state and hands off.
- **Skills** ([`.github/skills/`](../.github/skills/)) — auto-activating AVD knowledge: sizing,
  FSLogix, the WAF lens, cost guardrails, migration cutover, evidence packaging, landing zone.
  Learners don't invoke these; they *fire* when the topic comes up.
- **MCP servers** ([`.vscode/mcp.json`](../.vscode/mcp.json)) — `github` (issues/PRs as the task
  board), `azure` (live resources, deploy, cost, quota), `microsoft-learn` (authoritative docs),
  `terraform` (registry lookups).

**Control → agent → evidence** is the spine of the day:

| Control | Challenge | Lead agent | Evidence |
|---|---|---|---|
| — | C00 Setup | `avd-engagement-lead` | Working env + **budget** |
| B.1.1 | C01 Assessment | `avd-assessor` | `assessment.md` |
| B.2.1 | C02 Solution design | `avd-architect` | `hld.md` |
| B.2.2 | C03 WAF review | `avd-waf-reviewer` | `waf-review.md` |
| B.2.3 | C04 PoC / Pilot | `avd-pilot-lead` | `pilot.md` |
| B.3.1 | C05 Deploy | `avd-deployment-engineer` | `deployment.md` + live infra |
| B.4.1 | C06 Validation | `avd-test-engineer` | `validation.md` |
| B.4.2 | C07 Handover | `avd-handover-writer` | LLD, runbook, KT, hypercare, sign-off |

## How to run a challenge (the repeatable loop)

Use the same five-beat loop for every challenge so learners internalise the rhythm:

1. **Frame (1–2 min)** — name the control and the evidence artifact. *"This is B.2.1. We leave with
   an HLD."*
2. **Adopt the agent** — switch to the lead agent; show the picker so they see it's a real, scoped
   persona.
3. **Demo a beat live** — run one meaningful loop against the Contoso scenario; narrate the agent's
   reasoning.
4. **Hand off to the room** — learners continue in their own Codespace; you circulate.
5. **Hold the gate** — read the Definition of done aloud; don't advance until the artifact exists.

## Per-challenge talk tracks

Each block below: **Objective → Demo live → Teaching points → Pitfalls → Gate → Cue**. Deck and
challenge links are in the headings.

### C00 · Setup & guardrails

- **Objective:** every learner has a working environment **and a deployed budget** before any spend.
- **Demo live:** adopt [`avd-engagement-lead`](../.github/agents/avd-engagement-lead.agent.md); show
  the Codespace, `az login`, and deploying the budget + auto-shutdown from
  [`scripts/`](../scripts/). Slides: [`00-welcome.md`](../slides/00-welcome.md).
- **Teaching points:** the engagement lead is the *spine*; guardrails come **before** resources;
  GitHub issues are the engagement task board.
- **Pitfalls:** Codespace build is the morning long pole — start it at 09:00. `az login` device-code
  confusion. Wrong subscription selected.
- **Gate:** budget exists; `az account show` is correct; tags convention understood.
- **Cue:** *"Guardrails first. Nobody deploys a host until a budget is watching the meter."*

### C01 · Workload assessment — B.1.1

- **Objective:** personas, app inventory + delivery decisions, image strategy, sizing/density — all
  defensible. Slides: [`01-assessment.md`](../slides/01-assessment.md).
- **Demo live:** adopt [`avd-assessor`](../.github/agents/avd-assessor.agent.md); feed it
  [`scenario/personas.csv`](../scenario/personas.csv) and
  [`scenario/app-inventory.csv`](../scenario/app-inventory.csv); watch the **sizing skill** fire.
- **Teaching points:** **700 + 200 + 60 + 40 = 1,000** must reconcile; pooled multi-session for
  knowledge + call-centre, personal for power users + devs; sizing must **show its math** (users ÷
  density, IOPS, headroom) — not a guessed VM size.
- **Pitfalls:** inventing different numbers; guessing host counts; treating every app as "install on
  image" instead of deciding MSIX / package / per-host.
- **Gate:** numbers reconcile to 1,000; each persona has a host-pool type; sizing is calculated.
- **Cue:** *"If you can't show the arithmetic, an auditor won't accept the host count."*

### C02 · Solution design / HLD — B.2.1

- **Objective:** a buildable, **AVM-first** High-Level Design with a decision per component.
  Slides: [`02-solution-design.md`](../slides/02-solution-design.md).
- **Demo live:** adopt [`avd-architect`](../.github/agents/avd-architect.agent.md); turn the
  assessment into topology, identity, FSLogix, network, image, scaling and BCDR; map each to an
  **Azure Verified Module** and open [`infra/`](../infra/).
- **Teaching points:** every component is a *decision with a reason*; **Entra join + Intune** is the
  default (hybrid only when on-prem apps demand it); **FSLogix on Azure Files Premium / Kerberos**
  (ANF only > 1,000 users or latency-bound); **AVM modules named and pinned**.
- **Pitfalls:** designing the full 1,000-user footprint (it's a *paper* design); skipping BCDR;
  vague identity story; un-pinned modules.
- **Gate:** every component justified; AVM module + version named for each; identity + profile
  decisions explicit.
- **Cue:** *"This is the buildable design — but we build it at token scale in C05."*

### C03 · Well-Architected review — B.2.2

- **Objective:** prioritised, **AVD-specific** findings + a decision register. Slides:
  [`03-well-architected-review.md`](../slides/03-well-architected-review.md).
- **Demo live:** adopt [`avd-waf-reviewer`](../.github/agents/avd-waf-reviewer.agent.md); review the
  C02 HLD through the **WAF lens** skill; produce findings ranked by impact.
- **Teaching points:** Cost / Performance / Reliability lead for AVD; a finding must point at a
  *specific* HLD decision and a remediation; the decision register records what you **won't** change
  and why.
- **Pitfalls:** generic advice ("enable backups") with no AVD specificity or priority; reviewing the
  product instead of *this* design.
- **Gate:** findings prioritised and specific to the HLD; decision register present.
- **Cue:** *"Push every generic finding back to a pillar and an HLD line."*

### C04 · PoC / Pilot — B.2.3

- **Objective:** a bounded pilot with **quantitative** success criteria and a go/no-go rule.
  Slides: [`04-poc-pilot.md`](../slides/04-poc-pilot.md).
- **Demo live:** adopt [`avd-pilot-lead`](../.github/agents/avd-pilot-lead.agent.md); define scope
  (in/out), measurable criteria, the test plan and the go/no-go.
- **Teaching points:** criteria are **numbers** (logon < N s, app launch < N s, density target,
  FSLogix attach success %); a pilot **de-risks** production — tie each criterion to a C06 test.
- **Pitfalls:** "it works" criteria; unbounded scope; no rollback trigger.
- **Gate:** every success criterion is a number with a measurement method.
- **Cue:** *"Adjectives don't pass audits. Give me a threshold and how you'll measure it."*

### C05 · Deploy to production — B.3.1

- **Objective:** live AVD at **token scale** via AVM IaC, with a Go-Live record and cutover/rollback.
  Slides: [`05-deploy-to-production.md`](../slides/05-deploy-to-production.md).
- **Demo live:** adopt [`avd-deployment-engineer`](../.github/agents/avd-deployment-engineer.agent.md);
  **preview first** — `az deployment ... what-if` (Bicep) or `terraform plan` (Terraform) — then
  apply **1–2 hosts**; capture the cutover + rollback plan. Tracks: [`infra/bicep/`](../infra/bicep/)
  / [`infra/terraform/`](../infra/terraform/).
- **Teaching points:** **what-if/plan before apply, every time**; budget must already exist (C00);
  the cutover plan is the migration story from RDS/Citrix; rollback is non-negotiable.
- **Pitfalls:** **the overrun block** — protect the 75 min; scaling beyond 1–2 hosts; applying
  without previewing; forgetting tags.
- **Gate:** budget present **and** what-if/plan reviewed before apply; deployment succeeds at token
  scale.
- **Cue:** *"Preview, read the diff aloud, then apply. This is the headline demo of the day."*

### C06 · Service validation — B.4.1

- **Objective:** measured pass/fail against the C04 criteria — logon, app launch, scaling, failover,
  **FSLogix integrity**. Slides: [`06-service-validation.md`](../slides/06-service-validation.md).
- **Demo live:** adopt [`avd-test-engineer`](../.github/agents/avd-test-engineer.agent.md); run the
  validation against the deployed environment and record results vs. the pilot targets.
- **Teaching points:** validation **closes the loop** opened in C04; FSLogix profile integrity is the
  classic failure mode; results are **measured, not asserted**.
- **Pitfalls:** asserting success without numbers; skipping FSLogix; no link back to C04 criteria.
- **Gate:** each C04 criterion has a measured pass/fail.
- **Cue:** *"C04 set the bar; C06 jumps it — with numbers."*

### C07 · Handover documentation — B.4.2

- **Objective:** an as-built handover pack (LLD, runbook, KT plan, hypercare, sign-off,
  lessons learned). Slides: [`07-handover-documentation.md`](../slides/07-handover-documentation.md).
- **Demo live:** adopt [`avd-handover-writer`](../.github/agents/avd-handover-writer.agent.md); have
  it read **live Azure** (via the `azure` MCP) to produce the **LLD as-built**, then assemble the
  pack.
- **Teaching points:** the LLD reflects **what was deployed**, not the C02 intent; the runbook is
  operational, not architectural; sign-off + lessons learned close the engagement.
- **Pitfalls:** copying the HLD into the LLD; skipping the runbook; no sign-off.
- **Gate:** LLD matches as-built reality; pack is complete.
- **Cue:** *"The HLD was the plan. The LLD is the photograph of what we actually built."*

## Debrief & close

- **Replay the spine.** Walk back up the control → agent → evidence table; the room should now read
  it without prompting.
- **Name the pattern.** *Frame → adopt agent → demo → hand off → hold the gate* is portable to any
  engagement, not just AVD.
- **Confirm teardown.** The `azure` MCP must show **nothing left running**; see
  [cost & cleanup](cost-and-cleanup.md). This is a cost gate, not an optional step.
- **Collect feedback as issues.** Feedback goes on the repo as GitHub issues — model the task-board
  behaviour you taught all day.

## Common pitfalls (all-day)

- **Skipping a gate to save time.** Trim manual contrasts and stretch goals instead — never a gate.
- **Inventing scenario numbers.** Always reconcile to **700 / 200 / 60 / 40 = 1,000**.
- **Building the full footprint.** Repeat "paper design, token-scale deploy" at C02 and C05.
- **Deploying without a budget.** C00 is a hard prerequisite for C05.
- **Applying without previewing.** Every `apply`/`create` follows a what-if/plan.
- **Letting agents go unrefined.** The teaching is in *refining* the agent's output, not accepting it.
- **Forgetting teardown.** Close the day on an empty resource group.
