# Challenge 02 — Solution design (HLD)

> **Module B control:** B.2.1 — Solution Design · **Time-box:** 60 min ·
> **Lead agent:** `avd-architect` · **Evidence:** `work/hld.md`

## Objective

Turn the B.1.1 assessment into an **audit-grade, directly buildable High-Level Design**: host
pools and application groups per persona, identity, FSLogix profiles, networking, golden image,
autoscaling, monitoring, and BCDR — each mapped to an **Azure Verified Module** so the Bicep and
Terraform tracks can implement it 1:1.

## Prerequisites

- Completed [Challenge 01](../challenge-01-workload-assessment/) — `work/assessment.md` with
  personas, density, and the app strategy.
- Familiarity with the infra contract: [`infra/README.md`](../../infra/README.md) (parameter and
  output names your design must match) and the
  [`avd-landing-zone`](../../.github/skills/avd-landing-zone/SKILL.md) AVM module map.

## The agentic way (do this first)

1. **Agent:** adopt [`avd-architect`](../../.github/agents/avd-architect.agent.md) — ask it to
   *"produce the B.2.1 HLD from `work/assessment.md`, name the AVM module for every domain, and
   keep it consistent with `infra/README.md`."*
2. **Skill:** it draws on [`avd-landing-zone`](../../.github/skills/avd-landing-zone/SKILL.md)
   (layers + AVM map), [`avd-fslogix`](../../.github/skills/avd-fslogix/SKILL.md) (profile share)
   and [`avd-personas-sizing`](../../.github/skills/avd-personas-sizing/SKILL.md) (carry the
   numbers forward).
3. **MCP:** **`microsoft-learn`** for AVD product behaviour (load balancing, Shortpath, scaling
   plans); **`terraform`** for current AVM module versions/inputs; **`azure`** to confirm region
   and SKU availability in Sweden Central.

> Draft with the agent, then **you** make the architectural calls — every domain decision must
> reconcile with the assessment numbers and the infra contract.

## Steps

### 1. Carry the assessment forward

Map each persona to concrete **pools, SKUs, and a scaling plan**. Knowledge workers + call centre
→ pooled multi-session host pools; power users + developers → personal host pools. Keep the
density and FSLogix numbers identical to `work/assessment.md`.

### 2. Design each of the eight domains

1. **Host pools & app groups** — pooled + personal per persona; workspace layout; desktop vs
   RemoteApp; breadth- vs depth-first load balancing; `maxSessionLimit` from the assessment.
2. **Identity** — Entra join + Intune default; Conditional Access (MFA on the AVD app);
   least-privilege RBAC; **Entra Kerberos** for Azure Files; where (if anywhere) hybrid join is
   genuinely required and why.
3. **Profiles (FSLogix)** — Azure Files **Premium** share design, Kerberos auth, redirections,
   Cloud Cache (justify or omit), the **ANF threshold**; quota and IOPS sized to the assessment.
4. **Networking** — hub/spoke, AVD subnet(s), **RDP Shortpath (UDP)**, private endpoints for
   Files/Key Vault, DNS, egress, peering to on-prem during migration.
5. **Golden image** — Azure Image Builder pipeline, source, customisations (VDOT), versioning,
   Compute Gallery distribution.
6. **Scaling** — AVD scaling plans per persona (time- and demand-based); ramp schedules tuned to
   call-centre shifts vs the knowledge-worker morning storm.
7. **Monitoring** — AVD Insights, Log Analytics, alerts on logon time / host health.
8. **BCDR** — region strategy, image/profile resilience, realistic RTO/RPO.

### 3. Name the AVM module for every domain

Fill the **AVM module map** table — `desktop-virtualization/host-pool`,
`.../application-group`, `.../workspace`, `.../scaling-plan`, `network/virtual-network`,
`storage/storage-account`, `operational-insights/workspace`, etc. **Pin a version** for each (look
it up via the `terraform` MCP / the AVM index).

### 4. Diagram + decisions register

Include a **Mermaid architecture diagram** (start from
[`avd-landing-zone/references/architecture.md`](../../.github/skills/avd-landing-zone/references/architecture.md))
and a **decisions table** — each significant choice with options considered, the choice, and the
justification.

### 5. Produce the evidence artifact

```bash
mkdir -p work
cp ../../.github/skills/avd-evidence-pack/templates/hld.md work/hld.md
```

Complete every section of
[`templates/hld.md`](../../.github/skills/avd-evidence-pack/templates/hld.md).

## Definition of done (acceptance criteria)

- [ ] `work/hld.md` exists and follows the template (diagram + 8 domains + AVM map + decisions).
- [ ] All **8 design domains** are covered; convention defaults (naming, tags, Entra join, Files
      Premium, `swedencentral`) are honoured or each deviation is justified.
- [ ] **Every domain names the AVM module** that builds it, with a pinned version.
- [ ] Design **reconciles with the assessment** numbers (personas, density, profile sizing) and
      with the [`infra/README.md`](../../infra/README.md) parameter/output names.
- [ ] Mermaid diagram and decisions register present.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md)
      prompt (or by `avd-architect`) → **PASS**.

## Stretch goals

- Add a **cost-shape** note per persona (autoscale ramp vs reserved capacity) to pre-empt the WAF
  review's Cost findings.
- Specify the **Conditional Access** policy set (device, MFA, session controls) you'd attach to the
  AVD enterprise app.

<details>
<summary>Trainer notes</summary>

- **Timing:** ~10 min carry-forward, ~35 min domain design, ~15 min diagram + decisions. Don't let
  learners redesign the assessment here — the numbers are fixed inputs.
- **Common pitfalls:** vague domains with no AVM module named; FSLogix re-sized differently from
  C01; forgetting RDP Shortpath / private endpoints; no BCDR objectives; design that the infra
  contract can't implement (different names/params).
- **Talking points:** "directly buildable" is the bar — the HLD is the contract the deployment
  workstream codes against. AVM-first keeps both IaC tracks feature-equivalent.
- **Solution key:** [`solutions/challenge-02/`](../../solutions/challenge-02/).

</details>

## What's next

→ [Challenge 03 — Well-Architected review](../challenge-03-well-architected-review/) (B.2.2).
