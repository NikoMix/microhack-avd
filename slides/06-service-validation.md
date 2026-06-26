---
marp: true
theme: microhack
paginate: true
footer: "C06 · Service validation · B.4.1"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 06 — Service validation

## B.4.1 · `avd-test-engineer` · `validation.md`

Prove the deployed service meets the **pilot success criteria** — logon performance, app launch,
autoscale, failover and **FSLogix profile integrity** — with **measured evidence, not assertions**.

---

## Why this matters

Validation is where you **earn the auditor's trust**.

- The bar was set in **C04**; here you **measure against it** and record pass/fail.
- *"It works"* is not evidence. **Numbers + how they were measured** is evidence.
- Pull the **as-built reality** from Azure, not the design intent.

---

## Validation matrix

| Test | Measure | Source |
|---|---|---|
| Logon performance | Logon time vs target (logon storm) | Monitor / Log Analytics |
| App launch | LOB CRM + Finance suite launch time | Host + agent timing |
| Autoscale | Ramp on schedule / demand | Scaling plan + `azure` MCP |
| Failover / resilience | Behaviour on host / zone loss | Controlled test |
| FSLogix integrity | Profile attach success, no corruption | Profile container checks |

---

## The agentic way

- **Agent** — adopt [`avd-test-engineer`](../.github/agents/avd-test-engineer.agent.md): *"run
  validation against the pilot criteria and record pass/fail with measurements."*
- **Skill** — [`avd-fslogix`](../.github/skills/avd-fslogix/SKILL.md) for profile-integrity checks;
  load tooling lives in [`scripts/`](../scripts/).
- **MCP** — **`azure`** Monitor / Log Analytics for the numbers; **`microsoft-learn`** for the
  metrics that matter.

---

## Demo beats

```text
"avd-test-engineer: validate against work/pilot.md criteria; for each,
 record the measured value, the method, and pass/fail."
```

1. Run each test; capture the **measured value** and the **method**.
2. Compare to the **C04 target** → **pass / fail** per criterion.
3. Verify **FSLogix attach success** and profile integrity explicitly.
4. Fill [`templates/validation.md`](../.github/skills/avd-evidence-pack/templates/validation.md).

---

<!-- _class: gate -->

## Definition of done

- [ ] **Every pilot criterion** has a measured result + method + **pass/fail**.
- [ ] **FSLogix profile integrity** verified (attach success, no corruption).
- [ ] Results pulled from the **as-built** environment, traceable to C04/C05.
- [ ] Reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — make the agent **show the measurement**, not just claim a pass. Tie each result
  back to the exact C04 criterion.
- **Pitfalls** — asserting instead of measuring; no numbers; skipping FSLogix integrity;
  validating the design rather than the deployment.
- **Timing (45 min)** — pre-stage the tests in your dry-run so live time is spent on results.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 07 · Handover documentation — B.4.2

Make it operable and signed-off with
[`avd-handover-writer`](../.github/agents/avd-handover-writer.agent.md).
