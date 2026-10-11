---
marp: true
theme: microhack
paginate: true
footer: "C03 · Well-Architected review · B.2.2"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 03 — Well-Architected review

## B.2.2 · `avd-waf-reviewer` · `waf-review.md`

Pressure-test the HLD against the **Azure Well-Architected Framework** through an **AVD lens** —
**Cost, Performance Efficiency and Reliability first** — and log the decisions.

---

## Why this matters

A design is only audit-grade once it has **survived a structured review**.

- The WAF review proves you considered trade-offs **before** spending money on Azure.
- For AVD, the highest-leverage pillars are **Cost**, **Performance**, and **Reliability**.
- Output is a **prioritised findings list + a decision register** — accept, mitigate, or redesign.

---

## The five pillars, AVD lens

| Pillar | Sample AVD question |
|---|---|
| Cost Optimization | Is autoscale right-sized? Premium Files only where IOPS needs it? |
| Performance Efficiency | Density vs experience; FSLogix IOPS at logon storm? |
| Reliability | Host-pool + storage + profile resilience; zone/region strategy? |
| Security | Conditional Access, Entra join, network isolation? |
| Operational Excellence | Image pipeline, monitoring, autoscale operations? |

---

## The agentic way

- **Agent** — adopt [`avd-waf-reviewer`](../.github/agents/avd-waf-reviewer.agent.md): *"review
  `work/hld.md` against WAF, AVD lens, Cost/Perf/Reliability first."*
- **Skill** — [`avd-waf-lens`](../.github/skills/avd-waf-lens/SKILL.md) supplies the AVD-specific
  checklist so findings are **specific, not generic**.
- **MCP** — **`azure`** Well-Architected + pricing tools; **`microsoft-learn`** for guidance.

---

## Demo beats

```text
"avd-waf-reviewer: produce prioritised findings against the HLD with
 severity, impact and a recommendation; log each as a decision."
```

1. Walk the three priority pillars; each **finding has severity + impact + recommendation**.
2. Build a **decision register**: accept / mitigate / redesign, with an owner.
3. Feed material findings **back into the HLD** before pilot.
4. Fill [`templates/waf-review.md`](../.github/skills/avd-evidence-pack/templates/waf-review.md).

---

<!-- _class: gate -->

## Definition of done

- [ ] Findings are **prioritised** and **specific to this design** (no boilerplate).
- [ ] Each finding has **impact + recommendation + owner**.
- [ ] A **decision register** records accept / mitigate / redesign.
- [ ] Traceable to `work/hld.md`; reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — ask for findings, then challenge a **generic** one and have the agent make it
  AVD-specific (cite the pillar + the HLD decision it touches).
- **Pitfalls** — generic WAF advice; no prioritisation; findings that never loop back to the HLD.
- **Timing (45 min)** — timebox to the top three pillars; depth over breadth.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 04 · PoC / Pilot — B.2.3

Turn the reviewed design into a measurable pilot with
[`avd-pilot-lead`](../.github/agents/avd-pilot-lead.agent.md).
