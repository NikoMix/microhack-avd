# Trainer Solution Key — Challenge 05 (B.3.1 Deploy to Production)

This folder holds the worked **B.3.1** evidence artifact (`deployment.md`) and this trainer
rationale. It is a **paper/lab key**: nothing is deployed live, sample IDs and GUIDs are
illustrative. Use it to grade learner submissions and to explain *why* the deployment is done
this way.

## What "good" looks like

A passing submission proves three things, in order:

1. **Preview was run and read back** before any apply (`what-if` / `terraform plan`).
2. **Deployment succeeded** and the resources match the HLD — names and tags follow the
   `<type>-<workload>-<env>-<region>` convention and carry the required tag set.
3. **Configuration baseline** items are each individually verified, and **cutover + rollback**
   are documented (waves, gates, fallback, teardown).

## Why a token lab slice, not 1,000 users

The canonical design reconciles to exactly **1,000 users** across four personas (700 knowledge
workers, 200 call centre, 60 power users, 40 developers). That is the **paper** architecture the
learner sizes and costs. What we actually **build** is a 2-host slice (`vmavdlab0` / `vmavdlab1`)
that runs the *identical* IaC, baseline, and guardrails.

Rationale:

- A classroom subscription cannot (and should not) absorb ~1,000-user run-rate.
- The slice still exercises every control that matters: host-pool RDP props, FSLogix on Azure
  Files with Entra Kerberos, scaling-plan assignment, Conditional Access, AVD Insights.
- Skills transfer because the templates are the same; only the **count** and **SKU** scale up.

If a learner deploys anything approaching full scale, that is a **fail** on the guardrails
criterion — stop them and point at the budget.

## Cost-guardrails-first principle

Guardrails are deployed **before** the workload, and the engineer **refuses to apply** without
them:

- **Budget** `budget-avd-lab-sec` — 50 USD/month with 50/80/100% alerts.
- **Auto-shutdown** — per-VM at 19:00 `W. Europe Standard Time`.

Both come from `scripts/setup/New-AvdLabGuardrails.ps1`. The teardown
(`scripts/reset/Remove-AvdLab.ps1`) is **tag-guarded**, so the same tags that make resources
auditable also make deletion safe.

## Why preview-before-apply is non-negotiable

`what-if` / `plan` is the last cheap moment to catch a mistake before money is spent and state
changes. The learner must:

1. Run the preview.
2. **Read it back** — resource count (~14 + child resources), names, SKUs, and the cost shape.
3. Apply **the same template/parameters** that were previewed.

Applying something different from what was previewed (different params, edited template, a
re-pinned module version) defeats the control entirely and is a common, serious mistake.

> Note: `what-if` does **not** validate **vCPU quota**. Quota is a separate pre-flight check
> (`azure` MCP / portal). A clean preview can still fail at apply if the `Standard_DASv5` family
> quota is short.

## How tags drive safe teardown

Every resource carries:

```text
workload   = avd-microhack
env        = lab
owner      = <consultant-upn>
costCenter = training
autoDelete = true
```

`Remove-AvdLab.ps1` only deletes resources matching `workload=avd-microhack` + `env=lab`. This is
why missing or wrong tags is not a cosmetic nit: it breaks the safety mechanism that keeps cleanup
from touching anything else in the subscription. Always preview teardown with `-WhatIf` first.

## Wave-ordering logic and the no-downtime constraint

Cutover is wave-based, reversible, and **lowest-risk first**, with legacy RDS/Citrix kept warm as
the fallback the entire time:

1. **Wave 1 — KW pilot subset (~25):** smallest blast radius, validates the pooled pattern and the
   baseline end-to-end before scale.
2. **Wave 2 — Call centre (200):** predictable shift hours make autoscale-on-schedule easy to
   validate; pooled like the KWs, so it reuses proven config.
3. **Wave 3 — KW bulk (~675):** only after the pattern is proven and capacity is validated at 70%
   concurrency.
4. **Wave 4 — Power users (60, Personal):** personal desktops + Finance Suite — moved later because
   Finance Suite is downtime-sensitive and personal hosts are 1:1.
5. **Wave 5 — Developers (40, Personal):** most custom (nested virt / Docker, admin rights, premium
   disk, 30 GB profiles) — highest variability, so last.

**No-downtime constraint:** LOB **CRM** and **Finance Suite** must stay available throughout.
Coexistence makes this possible — users are *routed* to AVD by Conditional Access + app-group
assignment, and legacy publishes the same apps until a wave is signed off. Rollback is therefore a
**routing reversal**, not a rebuild.

## Cost-shape derivation (show the math)

- **Compute:** 2 × `Standard_D4as_v5` at ~0.20 USD/host/hr pay-as-you-go = **~0.40 USD/hr** with
  both hosts on. With auto-shutdown (19:00) and the scaling plan (ramp-down 18:00, drain on
  shutdown), hosts are deallocated off-hours — realistically <10 host-hours/day, so roughly
  **~2–4 USD/day** of compute, not 24×7.
- **Storage:** Azure Files Premium (FileStorage, ZRS), 100 GiB provisioned at ~0.16 USD/GiB/month
  ≈ **~16 USD/month** if held a full month; a short-lived lab pro-rates to a few USD.
- **Logs:** AVD Insights ingest for 2 hosts is light — within the first few GB, **a few USD/month**
  at most.
- **Conclusion:** comfortably **under the 50 USD budget** *for a short-lived lab that is torn
  down*. Auto-shutdown + the scaling plan are the two controls that keep run-rate low; the budget
  is the backstop.

## Common ways learners go wrong

1. **Deploying full scale** — spinning up host counts/SKUs for the 1,000-user paper design instead
   of the 2-host slice. Burns budget fast.
2. **Skipping `scripts/setup/`** — applying the workload with no budget and no auto-shutdown. The
   engineer must **refuse to deploy** in this state.
3. **Applying something different from the preview** — editing the template/params after `what-if`,
   or never reading the preview back. The apply must match what was previewed.
4. **Region without vCPU quota** — picking `swedencentral` but never checking the `Standard_DASv5`
   family quota; `what-if` passes, apply fails.
5. **Missing the Entra Kerberos prerequisite** — FSLogix on Azure Files with Entra Kerberos auth
   needs Kerberos enabled on the tenant **and** the storage account, plus share-level RBAC + NTFS
   perms. Skip it and profile containers won't mount.
6. **Forgetting teardown** — leaving the lab running. Always finish at `scripts/reset/` and remind
   the learner; add `-RemoveBudget` only when fully done.

## Handoff

`deployment.md` reports to `avd-engagement-lead`. The live lab then goes to `avd-test-engineer`
for **B.4.1** validation, whose test cases are pre-wired to the §5 validation gates.
