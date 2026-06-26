# Challenge 01 — Workload assessment

> **Module B control:** B.1.1 — Workload Assessment · **Time-box:** 60 min ·
> **Lead agent:** `avd-assessor` · **Evidence:** `work/assessment.md`

## Objective

Turn Contoso's legacy **RDS + Citrix** estate into a defensible **AVD workload assessment**:
four personas, an application inventory with a delivery decision per app, an image strategy, and
**host sizing/density with the math shown**. This is the foundation every later artifact builds
on — get the numbers right here and the design, review, and pilot stay consistent.

## Prerequisites

- Completed [Challenge 00](../challenge-00-setup/) — working Codespace, Azure login, cost cap.
- The Contoso scenario data: [`scenario/`](../../scenario/) — read
  [`current-state.md`](../../scenario/current-state.md) and skim the three CSVs.

## The agentic way (do this first)

1. **Agent:** adopt [`avd-assessor`](../../.github/agents/avd-assessor.agent.md) — ask it to
   *"build the B.1.1 workload assessment from `scenario/`, reconciling to 700/200/60/40 = 1000
   users, and show the density math."*
2. **Skill:** it draws on [`avd-personas-sizing`](../../.github/skills/avd-personas-sizing/SKILL.md)
   (persona → pool, density method, FSLogix IOPS) and
   [`avd-fslogix`](../../.github/skills/avd-fslogix/SKILL.md) (profile share sizing).
3. **MCP:** ground sizing in **`microsoft-learn`** (search *"session host virtual machine sizing
   guidelines"*); use **`github`** to track this as the engagement task board.

> The point of this MicroHack is the agentic workflow. Let the agent draft, then **you** apply the
> consulting judgement: challenge every density number and tie it back to the discovery data.

## Steps

### 1. Read the discovery inputs

- [`scenario/current-state.md`](../../scenario/current-state.md) — estate, identity, network,
  pain points, goals/constraints.
- [`scenario/personas.csv`](../../scenario/personas.csv) — the four personas with counts, peak
  concurrency %, work patterns, app sets, profile sizes.
- [`scenario/app-inventory.csv`](../../scenario/app-inventory.csv) — apps, current delivery,
  criticality, peripheral/runtime dependencies, a starter `delivery_decision`.
- [`scenario/map-assessment-sample.csv`](../../scenario/map-assessment-sample.csv) — sample MAP
  Toolkit / Azure Migrate / Citrix Director output (CPU/RAM/peak-concurrent per legacy host).

### 2. Classify personas and justify pool type

For each persona, fix **users**, **peak concurrency** (count = users × peak %), **work pattern**,
**key apps**, and the **pool type** (pooled multi-session vs personal) — with the *reason*.
Knowledge workers + call centre → pooled multi-session; power users + developers → personal.

### 3. Decide delivery for every application

Triage each app in the inventory to one delivery method — **install to image / MSIX app attach /
per-user / RemoteApp / replace-with-SaaS / leave-on-prem** — with a rationale and the migration
risk (Citrix-specific, GPU, legacy runtime, peripheral, licensing). No app row without a decision.

### 4. Show the sizing math

Pick a VM family per persona and derive **users-per-host** from Microsoft's multi-session
guidance, calling out the **governing constraint** (vCPU vs RAM). Then:

```text
peak concurrent  = users × peak-concurrency %
hosts (pooled)   = ceil(peak concurrent / users-per-host) + N+1 maintenance headroom
personal pools   = 1 VM per assigned user (size for the single-user workload)
```

Cross-check your density against the **observed** legacy density in
`map-assessment-sample.csv` (e.g. the busiest RD Session Host ran ~58 concurrent users on
16 vCPU / 64 GB at ~88% CPU). Size **FSLogix** storage for the **peak-logon IOPS** of the pooled
population, not total users.

### 5. Produce the evidence artifact

Copy
[`.github/skills/avd-evidence-pack/templates/assessment.md`](../../.github/skills/avd-evidence-pack/templates/assessment.md)
into `work/assessment.md` and complete all seven sections. Keep it crisp tables + short rationale.

```bash
mkdir -p work
cp ../../.github/skills/avd-evidence-pack/templates/assessment.md work/assessment.md
```

## Definition of done (acceptance criteria)

- [ ] `work/assessment.md` exists and follows the template (all seven sections completed).
- [ ] Persona counts reconcile to **700 + 200 + 60 + 40 = 1000**; peak concurrency is calculated.
- [ ] Every persona has a pool-type decision **and** a reason.
- [ ] Every application row has a delivery decision **and** a rationale + migration risk.
- [ ] Host count and FSLogix storage are shown **with the calculation**, not asserted, and the
      governing constraint (vCPU/RAM/IOPS) is named.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md)
      prompt (or by `avd-assessor`) → **PASS**.

## Stretch goals

- Reconcile your per-persona density against **every** host in `map-assessment-sample.csv` and note
  where observed CPU/RAM peaks would change your VM family choice.
- Flag the apps that should be **re-platformed** rather than lifted (e.g. the statutory reporting
  tool's SaaS option) and estimate the licensing/run-cost delta.

<details>
<summary>Trainer notes</summary>

- **Timing:** ~15 min reading scenario, ~25 min personas + app triage, ~20 min sizing math +
  artifact. The sizing derivation is where learners stall — demo it once, live.
- **Common pitfalls:** sizing for **total** users instead of **peak concurrent**; forgetting
  **N+1**; sizing FSLogix on capacity instead of **logon-storm IOPS**; putting power users/devs on
  pooled hosts; leaving app rows with no rationale.
- **Talking points:** the assessment is the *contract* the rest of the engagement inherits — if the
  density is hand-waved here, B.2.1/B.2.2/B.2.3 all wobble. Tie numbers to discovery (MAP) so the
  auditor sees evidence, not opinion.
- **Solution key:** [`solutions/challenge-01/`](../../solutions/challenge-01/).

</details>

## What's next

→ [Challenge 02 — Solution design (HLD)](../challenge-02-solution-design/) (B.2.1).
