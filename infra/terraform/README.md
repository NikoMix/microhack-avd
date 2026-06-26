# Terraform track — AVD landing zone

Azure Verified Modules (AVM) deployment of the Contoso Azure Virtual Desktop landing zone,
built to the cross-track contract in [`../README.md`](../README.md). This track is
**feature-equivalent** to the [Bicep track](../bicep/README.md): identical input variable
names, identical output names, identical naming convention and tags, so the challenges,
the reset scripts, and the `azure` MCP behave the same regardless of which track you pick.

> Deploy the **lab footprint by default** (one small session host). Contoso's full
> ~1,000-user design stays on paper — see the sizing reconciliation below and
> [`.github/skills/avd-cost-guardrails`](../../.github/skills/avd-cost-guardrails/SKILL.md).

## What this deploys

A single, self-contained AVD landing zone in one resource group:

- **Resource group** — holds every resource; tagged for auto-cleanup.
- **Networking** — virtual network, session-host subnet, private-endpoint subnet, and a
  network security group.
- **Identity-ready host pool** — Pooled multi-session, Windows 11 Enterprise multi-session,
  Entra-joined, with Entra single sign-on RDP properties.
- **Application group** (Desktop) + **workspace**, associated together.
- **Session host(s)** — Entra-joined, **Trusted Launch** (Secure Boot + vTPM), registered to
  the host pool via the AADLoginForWindows and AVD agent (DSC) extensions; OS-disk type and
  count are lab-trimmed. Deployment is toggleable (`deploySessionHosts`).
- **FSLogix profile storage** — Azure Files Premium (`FileStorage`) share with Entra
  Kerberos (`AADKERB`), a private endpoint, and a private DNS zone; public network access and
  shared-key (account-key) access are both disabled.
- **Monitoring** — Log Analytics workspace with diagnostic settings wired from the host
  pool, workspace, NSG, virtual network, Key Vault, and storage account.
- **Key Vault** — stores the break-glass local-admin password (RBAC authorization).
- **Autoscale scaling plan** — optional; only attached to Pooled pools (off in the lab).
- **Cost guardrails** — a resource-group budget (alerts at 80% actual / 100% forecast) and a
  daily VM auto-shutdown schedule.

### Pinned module and provider versions

Every module is pinned to an exact version and every provider to a constraint. Versions are
recorded for all platforms in the committed `.terraform.lock.hcl`.

| Component | Source | Version |
|---|---|---|
| Resource group | `Azure/avm-res-resources-resourcegroup/azurerm` | `0.4.0` |
| Log Analytics | `Azure/avm-res-operationalinsights-workspace/azurerm` | `0.5.1` |
| Virtual network | `Azure/avm-res-network-virtualnetwork/azurerm` | `0.19.0` |
| Network security group | `Azure/avm-res-network-networksecuritygroup/azurerm` | `0.5.1` |
| Private DNS zone | `Azure/avm-res-network-privatednszone/azurerm` | `0.5.0` |
| Storage account (FSLogix) | `Azure/avm-res-storage-storageaccount/azurerm` | `0.7.3` |
| Host pool | `Azure/avm-res-desktopvirtualization-hostpool/azurerm` | `0.4.0` |
| Application group | `Azure/avm-res-desktopvirtualization-applicationgroup/azurerm` | `0.2.1` |
| Workspace | `Azure/avm-res-desktopvirtualization-workspace/azurerm` | `0.2.2` |
| Scaling plan | `Azure/avm-res-desktopvirtualization-scalingplan/azurerm` | `0.2.1` |
| Session host VM | `Azure/avm-res-compute-virtualmachine/azurerm` | `0.21.0` |
| Key Vault | `Azure/avm-res-keyvault-vault/azurerm` | `0.10.2` |
| Budget + auto-shutdown | native `azurerm` resources (no AVM module exists) | provider `~> 4.36` |

Provider constraints (`providers.tf`): Terraform `>= 1.10, < 2.0`; `hashicorp/azurerm`
`~> 4.36`; `hashicorp/random` `~> 3.6`. The `azure/azapi`, `azure/modtm`, `hashicorp/time`,
and `hashicorp/tls` providers are pulled in transitively by the AVM modules.

## Prerequisites

1. **Terraform** `>= 1.10` (CI pins `latest`; any 1.10+ release works).
2. **Azure CLI**, authenticated to the target subscription: `az login` then
   `az account set --subscription <id>`. Terraform uses that context.
3. **Permissions** — Contributor on the subscription/resource group, plus **User Access
   Administrator** (or Owner) because the deployment creates RBAC role assignments
   (Key Vault and the desktop application group).
4. **Guardrails first.** Apply the budget + auto-shutdown from `scripts/` before you create
   session hosts. The budget and auto-shutdown in this stack are a backstop, not a
   replacement for the workshop guardrail scripts.

## Inputs (cross-track contract)

Same names, types, and lab defaults as the Bicep track. Override per environment with a
`-var-file`.

| Variable | Type | Default (lab) | Purpose |
|---|---|---|---|
| `location` | string | `swedencentral` | Azure region |
| `environment` | string | `lab` | `lab` or `prod`; drives naming and sizing |
| `namePrefix` | string | `avd` | Workload segment in resource names |
| `sessionHostCount` | number | `1` | Number of session hosts (capped at 10) |
| `deploySessionHosts` | bool | `true` | Deploy the session hosts, or just the control plane |
| `sessionHostSize` | string | `Standard_D4as_v5` | Session host VM SKU |
| `hostPoolType` | string | `Pooled` | `Pooled` or `Personal` |
| `maxSessionLimit` | number | `8` | Max sessions per pooled host |
| `profileStorageQuotaGb` | number | `128` | Azure Files Premium share size (GiB) |
| `deployScalingPlan` | bool | `true` | Attach an autoscale plan (Pooled only) |
| `adminObjectId` | string | `""` | Entra object ID granted desktop + Key Vault access |
| `tags` | map(string) | `{}` | Extra tags merged onto every resource |

Optional, fully-defaulted extension knobs keep both tracks interchangeable; leaving them
unset is fine. They are documented inline in [`variables.tf`](variables.tf) and include:

- **Break-glass admin** — `sessionHostAdminUsername` (default `avdadmin`) and the **sensitive**
  `sessionHostAdminPassword` (never defaulted/committed — supply via `TF_VAR_…` or leave empty
  to auto-generate; see [Session-host admin password](#session-host-admin-password)).
- **Networking** — `vnetAddressSpace`, `sessionHostSubnetPrefix`, `privateEndpointSubnetPrefix`.
- **Monitoring** — `logAnalyticsRetentionDays`.
- **Cost guardrails** — `budgetAmount`, `budgetContactEmails`, plus `budgetStartDate`,
  `autoShutdownTime`, and `enableAutoShutdown`.
- **Image / storage / disk SKUs** and private-endpoint and telemetry toggles.

## Outputs (cross-track contract)

| Output | Example | Used by |
|---|---|---|
| `resourceGroupName` | `rg-avd-lab-sec` | reset/validate scripts, azure MCP |
| `hostPoolName` | `hp-avd-lab-sec` | validation, registration |
| `workspaceName` | `ws-avd-lab-sec` | client connection |
| `applicationGroupName` | `ag-avd-lab-sec-desktop` | assignment checks |
| `storageAccountName` | `stavdlabsec<unique>` | FSLogix checks |
| `profileShareName` | `profiles` | FSLogix path |
| `logAnalyticsWorkspaceId` | `/subscriptions/.../...` | AVD Insights / KQL |

Operational extras (resource IDs, the sensitive host-pool registration token, Key Vault
name/URI, session-host names, scaling-plan name) are exported too — see
[`outputs.tf`](outputs.tf).

## Naming and tags

Names follow `<type>-<namePrefix>-<environment>-<regionShort>` (region short codes in
[`.github/skills/avd-landing-zone/references/regions.md`](../../.github/skills/avd-landing-zone/references/regions.md)),
so the lab resolves to `rg-avd-lab-sec`, `vnet-avd-lab-sec`, `hp-avd-lab-sec`,
`ws-avd-lab-sec`, `ag-avd-lab-sec-desktop`, and a globally-unique `stavdlabsec<suffix>`.

Every resource carries the mandatory tags `workload=avd-microhack`, `env=<environment>`,
`owner`, `costCenter=training`, and `autoDelete=true`, merged with any `tags` you pass.

## Usage

State is **local** (no backend block), which is correct for a throwaway classroom lab. Run
all commands from this directory (`infra/terraform`).

```bash
# 0. Guardrails first — budget + auto-shutdown (see scripts/).

# 1. Initialise (downloads pinned modules + providers).
terraform init

# 2. Preview — read every change before applying.
terraform plan -var-file=lab.tfvars

# 3. Apply the lab footprint.
terraform apply -var-file=lab.tfvars

# 4. Tear down when finished (and/or run scripts/ reset).
terraform destroy -var-file=lab.tfvars
```

For desktop access to work end-to-end, set a real `adminObjectId` (a user or, preferably, a
group GUID) before `apply`:

```bash
terraform apply -var-file=lab.tfvars -var 'adminObjectId=00000000-0000-0000-0000-000000000000'
```

The `prod.tfvars` file is a **production-shaped reference** (zonal premium storage, larger
hosts, autoscale on) for the High-Level / Low-Level Design. It still caps `sessionHostCount`
small so a curious `apply` cannot run up a bill — never scale it to Contoso's real fleet in
the shared subscription.

### Session-host admin password

The break-glass local-admin password is a **sensitive** variable that is never defaulted or
committed. Leave `sessionHostAdminPassword` empty to auto-generate a strong 24-character
password (written to Key Vault), or supply your own through the environment so it never lands
in a file:

```bash
export TF_VAR_sessionHostAdminPassword='<complex-password>'   # bash/zsh
$env:TF_VAR_sessionHostAdminPassword = '<complex-password>'   # PowerShell
terraform apply -var-file=lab.tfvars
```

Either way the effective password is stored in Key Vault under RBAC authorization.

### Provider lock file

`.terraform.lock.hcl` **is committed** and carries provider checksums for `linux_amd64`,
`linux_arm64`, `darwin_amd64`, `darwin_arm64`, and `windows_amd64`, so the Linux CI runner
and every learner workstation resolve identical provider versions. Regenerate it after a
provider bump with:

```bash
terraform providers lock \
  -platform=linux_amd64 -platform=linux_arm64 \
  -platform=darwin_amd64 -platform=darwin_arm64 -platform=windows_amd64
```

## Quality gates

CI (and your local loop) must pass these. No real deployment is run in CI — `validate` uses
`-backend=false` and checks the configuration against the real module schemas.

```bash
terraform fmt -check -recursive
terraform init -backend=false -input=false
terraform validate
```

`terraform validate` emits one **warning** that originates inside the
`avm-res-operationalinsights-workspace` module (a deprecated provider attribute the module
maintainers will retire). It is informational, does not fail validation, and cannot be fixed
without editing vendored module code.

## FSLogix profile storage

Profiles live in **FSLogix containers on Azure Files Premium** with **Entra Kerberos**
(`directory_type = "AADKERB"`), reached over a **private endpoint** with public network access
and shared-key (account-key) access both disabled — Entra Kerberos is the only path in. This
is the default for Entra-joined hosts up to ~1,000 users; move to Azure NetApp Files only
beyond that or when latency demands it — see
[`.github/skills/avd-fslogix`](../../.github/skills/avd-fslogix/SKILL.md). After `apply`, set
the share-level RBAC (`Storage File Data SMB Share Contributor`) and NTFS ACLs as part of the
configuration baseline.

## Cost guardrails

- **Budget** — a resource-group budget (`budgetAmount`, default 100 in the lab) with alerts
  at 80% actual and 100% forecast; resource-group Owners are always notified.
- **Auto-shutdown** — a daily VM shutdown schedule (`autoShutdownTime`, default `1900`) on
  every session host.
- **Footprint** — `lab.tfvars` deploys one `Standard_D2as_v5` host with LRS storage and a
  StandardSSD OS disk, scaling plan off. Tear down with `terraform destroy` and the workshop
  reset scripts when you are done.

## Sizing reconciliation (paper design)

The deployed lab is token scale. Contoso's production design — recorded in the assessment
([`../../scenario/personas.csv`](../../scenario/personas.csv)) — totals **1,000 users**
across four personas, delivered with per-persona host pools:

| Persona | Profile | Users | Host pool |
|---|---|---|---|
| Knowledge workers | Pooled multi-session | 700 | Win 11 Enterprise multi-session |
| Call centre | Pooled multi-session (time-based scaling) | 200 | High density, predictable hours |
| Power users | Personal | 60 | Persistent, heavier apps |
| Developers | Personal | 40 | Custom installs, premium disk |
| **Total** | | **1,000** | |

This module parameterises a **single** host pool; the production rollout instantiates it once
per persona (or extends it) with capacity derived from the sizing math, not hard-coded here.

## Caveats

- **`budgetStartDate`** must be the first day of a month (`YYYY-MM-01T00:00:00Z`). Set it to
  the first of the current month before `apply`, or Azure rejects the budget.
- **`avdAgentDscUrl`** points at the AVD agent DSC artifact, which Microsoft rotates. Confirm
  the current URL before `apply` if host registration fails.
- **`adminObjectId`** is empty by default so `validate`/`plan` work without it; the desktop
  and Key Vault role assignments are skipped until you supply a GUID.
- **Key Vault** uses RBAC authorization — the deploying principal needs Key Vault
  Administrator (granted automatically) to write the break-glass secret.

## Related

- [Infrastructure contract](../README.md) — the source of truth for inputs/outputs.
- [Bicep track](../bicep/README.md) — the feature-equivalent alternative.
- [AVD landing zone skill](../../.github/skills/avd-landing-zone/SKILL.md) — the AVM map.
- [Scenario data](../../scenario/README.md) — Contoso personas and app inventory.
- [Scripts](../../scripts/README.md) — guardrail and reset tooling.
