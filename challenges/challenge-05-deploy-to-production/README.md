# Challenge 05 — Deploy to production

> **Module B control:** B.3.1 — Deploy to Production · **Time-box:** 75 min ·
> **Lead agent:** `avd-deployment-engineer` · **Evidence:** `work/deployment.md`

## Objective

Deploy a **real AVD landing zone** to your Azure subscription from the [`infra/`](../../infra/)
AVM-based IaC — **previewed before applied**, cost-capped, and tagged for safe teardown — then
record the deployment, configuration baseline, and a wave-based cutover + rollback plan. You build
a **tiny lab slice (1–2 session hosts)**; Contoso's full ~1,000-user design stays on paper.

## Prerequisites

- Completed [Challenge 04](../challenge-04-poc-pilot/) — a **go** decision and `pilot.md`.
- The HLD from [Challenge 02](../challenge-02-solution-design/) (`work/hld.md`) to drive parameters.
- **Guardrails in place:** budget + auto-shutdown from [`scripts/setup/`](../../scripts/setup/).
- Signed in to **your own** Azure subscription; region + vCPU quota confirmed.
- One IaC track chosen: **Bicep** or **Terraform** (see [`infra/README.md`](../../infra/README.md)).

## The agentic way (do this first)

1. **Agent:** adopt **`avd-deployment-engineer`** — ask it to preview, deploy, and baseline the
   landing zone for your chosen track, and to draft the cutover + rollback plan.
2. **Skill:** it draws on `avd-landing-zone` (the AVM module map), `avd-cost-guardrails`
   (small SKUs, budget, teardown), and `avd-migration-cutover` (wave plan + rollback).
3. **MCP:** `azure` for `what-if`/quota/cost and to read back created resources; `terraform` for
   module/version lookups; `microsoft-learn` for AVD deployment docs; `github` for the task board.

> The point of this MicroHack is the agentic workflow. Use the agent to draft, then **you** apply
> the consulting judgement and verify.

## Steps

### 1. Guardrails first

```bash
# Re-confirm the budget + auto-shutdown before creating anything billable
pwsh ./scripts/setup/New-AvdLabGuardrails.ps1 -Location swedencentral -BudgetAmount 50
```

### 2. Set parameters from the HLD

Pick your track under [`infra/`](../../infra/) and set the parameters / `tfvars` from `hld.md`:
**lab-sized SKUs, 1–2 session hosts**, FSLogix on Azure Files Premium, the required tags
(`workload=avd-microhack`, `env`, `owner`, `costCenter=training`, `autoDelete=true`).

### 3. Preview (what-if / plan) — before apply

```bash
# Bicep
az deployment sub what-if --location swedencentral --template-file infra/bicep/main.bicep --parameters @infra/bicep/main.bicepparam

# Terraform
terraform -chdir=infra/terraform plan
```

Summarise the preview (resource count, names, cost shape) into `deployment.md` **§2**.

### 4. Deploy

Apply the **same** template/plan you previewed. Capture the deployment / run ID and the created
resources (read them back with the `azure` MCP) into `deployment.md` **§3**.

### 5. Configuration baseline

Verify and tick each item in `deployment.md` **§4**: host pool RDP properties (RDP Shortpath,
redirections), FSLogix settings, scaling plan assignment, Conditional Access targeting, and
AVD Insights / monitoring enabled.

### 6. Cutover & rollback

With `avd-migration-cutover`, complete `deployment.md` **§5–6**: the wave plan (pilot → groups),
entry/validation criteria per wave, comms, and the **per-wave rollback** to legacy RDS/Citrix plus
the teardown procedure ([`scripts/reset/`](../../scripts/reset/)).

### 7. Produce the evidence

Copy [`.github/skills/avd-evidence-pack/templates/deployment.md`](../../.github/skills/avd-evidence-pack/templates/deployment.md)
into `work/` and complete every section.

## Definition of done (acceptance criteria)

- [ ] `work/deployment.md` exists and follows the template.
- [ ] **Previewed** (`what-if` / `plan`) **before** apply, and the preview is summarised in §2.
- [ ] Deployment succeeded; created resources are listed and carry the **required tags**.
- [ ] Footprint is a **1–2 host lab slice** — not Contoso scale.
- [ ] Configuration baseline (§4) verified item-by-item.
- [ ] Wave cutover **and** rollback documented (§5–6), including teardown via `scripts/reset/`.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md) prompt → **PASS**.

## Stretch goals

- Deploy the **other** IaC track into a second resource group and compare the `what-if` output.
- Wire up the AVD Insights workbook and confirm session-host data is flowing.
- Add a second session host and watch the scaling plan ramp logic.

<details>
<summary>Trainer notes</summary>

- **Timing:** the deploy wait is the long pole. Kick off `what-if` early and narrate it while the
  apply runs; image building is out of scope for the lab (use the gallery image).
- **Common pitfalls:** skipping `scripts/setup/` (no budget); deploying full Contoso scale instead
  of 1–2 hosts; region without vCPU quota; missing identity prerequisites (Entra Kerberos for
  FSLogix); applying something different from what was previewed.
- **Talking points:** *preview before apply* is non-negotiable in production; tags are what make
  teardown safe; the lab is a token-scale slice of a paper design — keep that distinction explicit.
- **Solution key:** [`solutions/challenge-05/`](../../solutions/challenge-05/).

</details>

## What's next

→ Challenge 06 — Service validation (B.4.1).
