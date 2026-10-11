---
marp: true
theme: microhack
paginate: true
footer: "C04 · PoC / Pilot · B.2.3"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 04 — PoC / Pilot

## B.2.3 · `avd-pilot-lead` · `pilot.md`

De-risk the production rollout with a **bounded pilot** that has **quantitative success
criteria**, a test plan, and a clear **go / no-go** decision rule.

---

## Why this matters

The pilot is where the design **meets reality** — at small scale, reversibly.

- It converts opinion (*"AVD will be fine"*) into **measured evidence**.
- The success criteria you set here become the **pass/fail bar** for C06 validation.
- A good pilot is **representative but small** — enough to prove the risky parts, no more.

---

## Pilot shape

| Element | Contoso pilot |
|---|---|
| Scope (in) | A slice of knowledge workers + call centre on **pooled multi-session** |
| Scope (out) | Full personal-pool rollout; all 1,000 users |
| Success criteria | **Quantitative** — logon time, app launch, FSLogix attach, autoscale |
| Test plan | Steps + tooling + who runs each |
| Decision | A written **go / no-go** rule, agreed up front |

---

## The agentic way

- **Agent** — adopt [`avd-pilot-lead`](../.github/agents/avd-pilot-lead.agent.md): *"design a
  pilot with quantitative success criteria and a go/no-go rule, from the HLD + WAF findings."*
- **Skill** — draws on [`avd-personas-sizing`](../.github/skills/avd-personas-sizing/SKILL.md)
  to pick a representative slice and on the validation expectations of C06.
- **MCP** — **`azure`** for what a token-scale pilot will cost; **`microsoft-learn`** for AVD
  experience baselines.

---

## Demo beats

```text
"avd-pilot-lead: define pilot scope (in/out), quantitative success
 criteria with target numbers, a test plan, and a go/no-go rule."
```

1. Bound the scope — representative personas, **token host count**, fixed window.
2. Write criteria with **numbers** — e.g. logon < target s, app launch < target s,
   FSLogix attach success ≥ target %, autoscale ramps on schedule.
3. Define the **go / no-go** rule before testing — no moving goalposts.
4. Fill [`templates/pilot.md`](../.github/skills/avd-evidence-pack/templates/pilot.md).

---

<!-- _class: gate -->

## Definition of done

- [ ] Scope is **bounded** (explicit in / out) and representative.
- [ ] Success criteria are **quantitative and measurable** (targets, not adjectives).
- [ ] A written **go / no-go decision rule** exists and is agreed.
- [ ] Reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — push the agent to replace any vague *"it works"* criterion with a **number and a
  way to measure it**. That rigour is the whole point of the pilot.
- **Pitfalls** — pilot too big / too costly; criteria that can't be measured; no decision rule.
- **Timing (45 min)** — most value is in nailing the **criteria**; keep scope debate short.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 05 · Deploy to production — B.3.1

Build it for real (token scale) with
[`avd-deployment-engineer`](../.github/agents/avd-deployment-engineer.agent.md).
