---
name: avd-landing-zone
description: Reference architecture and Azure Verified Module (AVM) map for an enterprise-scale Azure Virtual Desktop landing zone. Use when designing or deploying AVD infrastructure (host pools, app groups, workspaces, scaling plans, FSLogix storage, networking, monitoring) so choices stay AVM-first and consistent across the Bicep and Terraform tracks.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# AVD landing zone (AVM reference)

Use this when designing or building the AVD platform. **Prefer Azure Verified Modules** for
every resource that has one; pin versions; keep Bicep and Terraform feature-equivalent.

## Layers

1. **Identity & governance** — Entra ID (join + Conditional Access + RBAC), subscription/RG
   layout, budgets, policy, tags (`workload=avd-microhack`, `env`, `owner`, `autoDelete=true`).
2. **Network** — hub/spoke vNet, AVD subnet(s), private DNS, private endpoints (Files, Key
   Vault), RDP Shortpath (UDP), peering to on-prem during migration.
3. **Storage / profiles** — Azure Files **Premium** share for FSLogix (Kerberos); ANF if
   > 1,000 users / latency-sensitive.
4. **Compute / image** — Azure Image Builder → Compute Gallery; session-host VMs per persona.
5. **AVD objects** — host pools (pooled multi-session + personal), application groups,
   workspace, scaling plans.
6. **Monitoring** — Log Analytics, AVD Insights, alerts (logon time, host health).

## AVM module map (name the module in designs)

| Resource | AVM module (Bicep `avm/res/...` ≈ Terraform `Azure/avm-res-...`) |
|---|---|
| Host pool | `desktop-virtualization/host-pool` |
| Application group | `desktop-virtualization/application-group` |
| Workspace | `desktop-virtualization/workspace` |
| Scaling plan | `desktop-virtualization/scaling-plan` |
| Virtual network | `network/virtual-network` |
| Storage (Files) | `storage/storage-account` |
| Key Vault | `key-vault/vault` |
| Log Analytics | `operational-insights/workspace` |
| Compute Gallery | `compute/gallery` |
| Session host VMs | `compute/virtual-machine` (or a pattern module) |

> Look up current module versions/inputs via the **`terraform` MCP** (registry) and the AVM
> index (`https://azure.github.io/Azure-Verified-Modules/`). Ground AVD product behaviour in the
> **`microsoft-learn` MCP**.

## Conventions

- Names: `<type>-avd-<env>-<region>` (e.g. `hp-avd-lab-sec`). Region short codes in
  `references/regions.md`.
- Classroom footprint: **1–2 session hosts, small SKUs**. Full Contoso scale is paper design.
- Always `what-if` / `plan` before apply; always pair a deploy with `scripts/reset/` teardown.

See `references/architecture.md` for the layered diagram and `infra/README.md` for the concrete
parameter/output contract the IaC implements.
