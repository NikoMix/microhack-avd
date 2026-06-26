---
marp: true
theme: microhack
paginate: true
footer: "C07 · Handover documentation · B.4.2"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 07 — Handover documentation

## B.4.2 · `avd-handover-writer`

Assemble the **operational handover** — an as-built **LLD**, an operations **runbook**, a
**knowledge-transfer** plan, a **hypercare** plan, customer **sign-off**, and **lessons learned**.

---

## Why this matters

Module B closes when the customer can **run the service without you**.

- The handover turns the whole engagement's evidence into a **coherent operational pack**.
- The LLD must reflect **as-built reality** (from Azure), not the original design intent.
- Sign-off + hypercare are what an auditor reads as **"the engagement actually landed."**

---

## The handover pack

| Artifact | Purpose |
|---|---|
| `lld.md` | **As-built** low-level design — what is actually deployed |
| `runbook.md` | Day-2 operations: scale, patch, image, profile, monitor |
| `kt-plan.md` | Knowledge transfer to the customer's operators |
| `hypercare.md` | Post-go-live support window + escalation |
| `signoff.md` | Customer acceptance |
| `lessons-learned.md` | What to do differently next time |

---

## The agentic way

- **Agent** — adopt [`avd-handover-writer`](../.github/agents/avd-handover-writer.agent.md):
  *"assemble the handover pack; build the LLD from the as-built Azure state."*
- **Skill** — [`avd-evidence-pack`](../.github/skills/avd-evidence-pack/SKILL.md) supplies every
  template under `templates/handover/`.
- **MCP** — **`azure`** to read the **as-built** resources for the LLD; **`github`** to attach the
  pack to the engagement.

---

## Demo beats

```text
"avd-handover-writer: build the LLD from the deployed Azure resources,
 then the runbook, KT plan, hypercare plan, sign-off and lessons."
```

1. Generate the **LLD from live Azure state** — emphasise *as-built, not as-designed*.
2. Draft the **runbook** for day-2 operations (scale / patch / image / profile / monitor).
3. Produce KT, hypercare, sign-off and lessons from
   [`templates/handover/`](../.github/skills/avd-evidence-pack/templates/handover/lld.md).

---

<!-- _class: gate -->

## Definition of done

- [ ] **LLD reflects as-built reality** (pulled from Azure), consistent with C05/C06.
- [ ] **Runbook** covers the core day-2 operations.
- [ ] **Sign-off** present; **hypercare** window + escalation defined.
- [ ] **Lessons learned** captured; reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — show the agent reading **live Azure** to build the LLD; contrast as-built vs the
  C02 design intent. That gap is a teaching moment.
- **Pitfalls** — LLD that is just the HLD again; missing runbook; no sign-off; lessons skipped.
- **Timing (45 min)** — lean on the templates; the value is **accuracy and completeness**, not prose.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Engagement complete

### Eight controls · eight evidence artifacts

Debrief, **teardown check**, and Train-the-Trainer tips →
[`08-train-the-trainer.md`](08-train-the-trainer.md).
