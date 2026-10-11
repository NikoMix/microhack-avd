---
marp: true
theme: microhack
paginate: true
footer: "C02 · Solution design (HLD) · B.2.1"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Challenge 02 — Solution design (HLD)

## B.2.1 · `avd-architect` · `hld.md`

Turn the assessment into a **buildable High-Level Design** — topology, identity, FSLogix,
networking, golden image, autoscaling and BCDR — mapped to **Azure Verified Modules**.

---

## Why this matters

The HLD is the **contract** between assessment and build.

- It must be **traceable** to C01's numbers and **directly buildable** in `infra/`.
- Auditors want **decisions, not descriptions** — options considered + a justification each.
- AVM-first: every component names the **module** that will deploy it, with a **pinned version**.

---

## Design surface

| Area | Contoso default |
|---|---|
| Topology | Host pools per persona; pooled multi-session + personal; workspace + app groups |
| Identity | **Entra join + Intune**; hybrid only where on-prem AD apps demand it |
| Profiles | **FSLogix on Azure Files Premium** (Kerberos); ANF only >1,000 / latency-bound |
| Network | Hub/spoke, private endpoints, **ExpressRoute decision**, region Sweden Central |
| Image | Golden image pipeline (Azure Compute Gallery) |
| Scale | Autoscale plans — time-based (call centre) + demand |
| BCDR | Zones / multi-region, profile + image resilience |

---

## The agentic way

- **Agent** — adopt [`avd-architect`](../.github/agents/avd-architect.agent.md): *"draft the HLD
  from `work/assessment.md`, AVM-first, with a decision for every component."*
- **Skill** — [`avd-landing-zone`](../.github/skills/avd-landing-zone/SKILL.md) (AVM map),
  [`avd-fslogix`](../.github/skills/avd-fslogix/SKILL.md),
  [`avd-personas-sizing`](../.github/skills/avd-personas-sizing/SKILL.md).
- **MCP** — **`microsoft-learn`** for AVD reference architecture; **`azure`** for region/SKU/quota
  reality; **`terraform`** for AVM module versions.

---

## Demo beats

```text
"avd-architect: produce the HLD — topology, identity, FSLogix, network,
 image, autoscale, BCDR — each with options + justification, mapped to AVM."
```

1. Architecture per persona, traced back to the assessment counts.
2. **AVM module map** — name + pin the modules that build it (host pool, storage, network…).
3. Decision register entries — e.g. *Files Premium vs ANF*, *Entra join vs hybrid*.
4. Fill [`templates/hld.md`](../.github/skills/avd-evidence-pack/templates/hld.md);
   it maps straight to [`infra/`](../infra/).

---

<!-- _class: gate -->

## Definition of done

- [ ] Every component has **options considered + a justification** (not just a description).
- [ ] **AVM modules named and version-pinned** for each deployable resource.
- [ ] Identity, FSLogix, network, image, scaling, BCDR all covered and **traceable to C01**.
- [ ] Reviewed with `/review-evidence` → **PASS**.

---

## Trainer cue

- **Demo live** — ask `avd-architect` for the **AVM module map**, then open
  [`infra/bicep/`](../infra/bicep/) / [`infra/terraform/`](../infra/terraform/) so learners see
  design → code.
- **Pitfalls** — a design that doesn't trace to the assessment; defaulting to ANF when Premium
  Files fits; hand-wave on networking; no decision register.
- **Timing (60 min)** — protect time for FSLogix + networking; those drive the build.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Next

### 03 · Well-Architected review — B.2.2

Pressure-test the HLD with [`avd-waf-reviewer`](../.github/agents/avd-waf-reviewer.agent.md).
