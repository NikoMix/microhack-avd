---
marp: true
theme: microhack
paginate: true
footer: "C05 · Deploy to production · B.3.1"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 05 — Deploy to production

## B.3.1 · `avd-deployment-engineer` · `deployment.md`

Deploy the AVD landing zone to **real Azure** with **Azure Verified Modules** (Bicep **or**
Terraform) — preview, deploy, baseline, **Go-Live**, and a **cutover + rollback** plan.

---

<!-- _class: gate -->

## Guardrails first — non-negotiable

This challenge spends **real money** on **your** subscription.

- **Budget + alerts** and **auto-shutdown** must already exist (from C00).
- **`what-if` (Bicep) / `plan` (Terraform) before every apply** — read the cost shape back.
- **Small SKUs, 1–2 session hosts.** The 1,000-user footprint stays a **paper design**.
- End by pointing at `scripts/reset/` ([`scripts/`](../scripts/)) — **tear down today**.

---

## What you deliver

| Step | Output |
|---|---|
| Preview | `what-if` / `plan` output reviewed for cost + change |
| Deploy | Live host pool, workspace, app group, FSLogix storage (token scale) |
| Baseline | Configuration baseline recorded |
| Go-Live | A dated **Go-Live record** of what went live |
| Cutover | Wave plan to move users off RDS/Citrix, with **rollback** |

---

## The agentic way

- **Agent** — adopt
  [`avd-deployment-engineer`](../.github/agents/avd-deployment-engineer.agent.md): *"deploy the
  AVM landing zone at token scale; what-if first; record as-built."*
- **Skill** — [`avd-landing-zone`](../.github/skills/avd-landing-zone/SKILL.md),
  [`avd-cost-guardrails`](../.github/skills/avd-cost-guardrails/SKILL.md),
  [`avd-migration-cutover`](../.github/skills/avd-migration-cutover/SKILL.md).
- **MCP** — **`azure`** for deploy / cost / quota; **`terraform`** for module versions;
  **`github`** to track the Go-Live.

---

## Demo beats

```text
# Bicep
az deployment sub what-if ...      # review BEFORE apply
# Terraform
terraform plan                     # review BEFORE apply
```

1. Confirm the **budget exists** and quota is sufficient in Sweden Central.
2. Run **what-if / plan**; talk through the cost and the change set.
3. Apply the **tiny slice**; capture the **as-built** via the `azure` MCP.
4. Record Go-Live + cutover/rollback in
   [`templates/deployment.md`](../.github/skills/avd-evidence-pack/templates/deployment.md).

---

<!-- _class: gate -->

## Definition of done

- [ ] A **budget exists** before any session host is created.
- [ ] **what-if / plan was reviewed** before apply (evidence captured).
- [ ] AVD is live at **1–2 hosts**; `deployment.md` records the **as-built reality**.
- [ ] **Cutover + rollback** documented; teardown path is clear.

---

## Trainer cue

- **Demo live** — the **what-if → apply** moment is the headline. Show the cost shape, then deploy.
- **Pitfalls** — deploying with **no budget**; skipping what-if; scaling toward the full footprint;
  Docker not running breaks the Terraform MCP.
- **Timing (75 min)** — the longest slot and the **most likely to overrun**. Protect it; keep the
  footprint tiny; have a pre-deployed fallback ready (see the facilitator guide).

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 06 · Service validation — B.4.1

Prove it works with measured evidence using
[`avd-test-engineer`](../.github/agents/avd-test-engineer.agent.md).
