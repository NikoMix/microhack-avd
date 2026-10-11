# Challenge 04 — PoC / Pilot

> **Module B control:** B.2.3 — PoC / Pilot · **Time-box:** 45 min ·
> **Lead agent:** `avd-pilot-lead` · **Evidence:** `work/pilot.md`

## Objective

Prove the design works for a representative slice of Contoso **before** full production: a scoped
pilot with **quantitative** success criteria, a test plan that retires the WAF risks, a results
table of actual-vs-target, and an explicit **go / no-go** recommendation that authorises (or
blocks) the production rollout.

## Prerequisites

- Completed [Challenge 02](../challenge-02-solution-design/) (`work/hld.md`) and
  [Challenge 03](../challenge-03-well-architected-review/) (`work/waf-review.md` — the risks to
  retire).
- The deployable lab landing zone in [`infra/`](../../infra/) (tiny footprint).
- Cost guardrails from Challenge 00 still in place.

## The agentic way (do this first)

1. **Agent:** adopt [`avd-pilot-lead`](../../.github/agents/avd-pilot-lead.agent.md) — ask it to
   *"design the B.2.3 pilot from `hld.md` and `waf-review.md`: pick a representative slice, set
   quantitative success criteria with measurement methods, and a go/no-go."*
2. **Skill:** it draws on [`avd-personas-sizing`](../../.github/skills/avd-personas-sizing/SKILL.md)
   (which personas best exercise the design) and
   [`avd-cost-guardrails`](../../.github/skills/avd-cost-guardrails/SKILL.md) (keep the pilot tiny
   and teardownable).
3. **MCP:** **`azure`** to pull AVD Insights / Log Analytics metrics for the results table;
   **`microsoft-learn`** for the KQL on `WVDConnections` (logon-time measurement).

> The pilot is a paper-and-lab exercise here: define it rigorously and, if a lab is deployed,
> capture real metrics. The discipline — measurable criteria, evidence-backed results — is the point.

## Steps

### 1. Scope the pilot (in / out)

Pick a **representative slice** that exercises the riskiest parts of the design and the WAF
findings: e.g. a small group of **knowledge workers** (pooled multi-session + FSLogix logon storm)
plus a couple of **power users** (personal). State pilot **user count**, **duration**, and the
**lab footprint** (1–2 hosts). List what is explicitly **out of scope**.

### 2. Define quantitative success criteria

Every criterion needs a **target** and a **measurement method** — no "performs well". For example:

| # | Criterion | Target | Method |
|---|---|---|---|
| 1 | Logon time (P95) | < 30 s | KQL on `WVDConnections` (AVD Insights) |
| 2 | App launch (LOB CRM) | < 8 s | Stopwatch / scripted |
| 3 | FSLogix profile load | < 15 s | FSLogix logs / event timing |
| 4 | Host CPU at target density | < 75 % | AVD Insights host metrics |
| 5 | P1 incidents in window | 0 | Incident log |

### 3. Build the test plan — map each test to a WAF finding

Each test scenario retires a specific **WAF risk** from Challenge 03 (e.g. "logon storm vs FSLogix
IOPS" retires the Performance finding on profile storage). No orphan tests.

### 4. Run and capture results (if a lab is deployed)

Stand up / reuse the small lab from [`infra/`](../../infra/), run the validation and light-load
scripts (delivered under `scripts/validate/` and `scripts/load-test/`), and pull metrics via the
**`azure`** MCP. Record **actual vs target** for every criterion with the evidence source. **Tear
down afterwards** (`scripts/reset/`).

### 5. Make the call

Write an explicit **go / go-with-conditions / no-go**, the conditions/required fixes before B.3.1,
and the residual risks. Produce the artifact:

```bash
mkdir -p work
cp ../../.github/skills/avd-evidence-pack/templates/pilot.md work/pilot.md
```

Complete every section of
[`templates/pilot.md`](../../.github/skills/avd-evidence-pack/templates/pilot.md).

## Definition of done (acceptance criteria)

- [ ] `work/pilot.md` exists and follows the template.
- [ ] Scope lists in-scope personas/apps/users **and** explicit out-of-scope; footprint is tiny.
- [ ] **Every success criterion is quantitative** with a target **and** a measurement method.
- [ ] Each test maps to a **WAF finding** being retired (traceable to Challenge 03).
- [ ] Results table shows **actual vs target** per criterion (or clearly marks "to be measured in
      the lab" where no deployment was run).
- [ ] **Go/no-go is explicit and justified**, with conditions and residual risks.
- [ ] If a lab was deployed, it is **torn down** (`scripts/reset/`) and cost guardrails confirmed.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md)
      prompt (or by `avd-pilot-lead`) → **PASS**.

## Stretch goals

- Add a **rollback trigger** to each criterion (the actual value that would flip the go to no-go).
- Capture the **KQL** you used for logon time so it can be reused in Challenge 06 (Validation).

<details>
<summary>Trainer notes</summary>

- **Timing:** ~10 min scope, ~20 min criteria + test plan, ~15 min results + go/no-go. If the class
  is running a lab, demo the `WVDConnections` KQL live; otherwise mark results "to be measured".
- **Common pitfalls:** vague criteria with no method; tests that don't map to a WAF risk; a
  go-decision with no conditions; forgetting teardown and leaving hosts billing overnight.
- **Talking points:** the pilot is the **risk gate** between design and production — a defensible
  go/no-go with measurable evidence is exactly what the auditor wants to see for B.2.3.
- **Solution key:** [`solutions/challenge-04/`](../../solutions/challenge-04/).

</details>

## What's next

→ Challenge 05 — Deploy to production (B.3.1). With a **go**, the design becomes real AVD
infrastructure via the Bicep or Terraform track in [`infra/`](../../infra/).
