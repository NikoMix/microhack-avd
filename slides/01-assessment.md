---
marp: true
theme: microhack
paginate: true
footer: "C01 · Workload assessment · B.1.1"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 01 — Workload assessment

## B.1.1 · `avd-assessor` · `assessment.md`

Turn Contoso's legacy RDS + Citrix estate into **personas, an app inventory with delivery
decisions, an image strategy, and defensible host sizing** — the numbers everything else depends on.

---

## Why this matters

Discovery is the **foundation of the engagement** and the first thing an auditor checks.

- Every later phase — design, pilot, deploy, validation — **traces back to these numbers**.
- Guessing here means an indefensible design later. The assessment must **show its working**.
- Frame it as a **MAP Toolkit / Azure Migrate / Citrix Director** discovery, the way a real
  engagement starts.

---

## From estate to evidence

<div class="columns">

**Inputs — `scenario/`**

- [`current-state.md`](../scenario/current-state.md) — the legacy estate
- [`personas.csv`](../scenario/personas.csv) — the four personas
- [`app-inventory.csv`](../scenario/app-inventory.csv) — the app estate
- [`map-assessment-sample.csv`](../scenario/map-assessment-sample.csv) — discovery export

**Output — `work/assessment.md`**

- Personas + pool decisions
- App delivery decisions
- Image strategy
- Sizing / density + IOPS

</div>

---

## The agentic way

- **Agent** — adopt [`avd-assessor`](../.github/agents/avd-assessor.agent.md): *"read `scenario/`
  and build the Module B workload assessment."*
- **Skill** — it draws on [`avd-personas-sizing`](../.github/skills/avd-personas-sizing/SKILL.md)
  for density math and [`avd-migration-cutover`](../.github/skills/avd-migration-cutover/SKILL.md)
  for wave framing.
- **MCP** — ground density in **`microsoft-learn`** (*"session host sizing guidelines"*); use
  **`azure`** for region/quota; **`github`** for the engagement board.

---

## Demo beats

```text
"avd-assessor: from scenario/, produce personas, app delivery decisions,
 an image strategy and host sizing with the math. Reconcile to 1,000 users."
```

1. Persona table reconciles to **1,000** — 700 / 200 / 60 / 40 — with pool type justified.
2. Each app gets a **delivery decision**: install-to-image · MSIX app attach · RemoteApp · SaaS.
3. Sizing: VM family + **users/host + host count + N+1**, derived not guessed, grounded in Learn.
4. Copy [`templates/assessment.md`](../.github/skills/avd-evidence-pack/templates/assessment.md)
   into `work/` and fill it in.

---

<!-- _class: gate -->

## Definition of done

- [ ] Personas **reconcile to 1,000**; pooled vs personal justified per persona.
- [ ] **Every application** has a delivery decision **and** a rationale.
- [ ] Sizing shows the **derivation** (density rule → host count → N+1); FSLogix IOPS budgeted.
- [ ] Consistent with `scenario/`; reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — ask `avd-assessor` to *show the density math*, then contrast with a number
  pulled from thin air. The defensibility is the lesson.
- **Pitfalls** — inventing different counts; skipping N+1 headroom; no app-by-app decision;
  sizing for peak instead of using autoscale.
- **Timing (60 min)** — the sizing/density conversation is where time goes; keep app triage brisk.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 02 · Solution design (HLD) — B.2.1

Hand the signed-off assessment to [`avd-architect`](../.github/agents/avd-architect.agent.md).
