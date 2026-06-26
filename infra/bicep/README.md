# Bicep track — AVD landing zone

Azure Verified Modules (AVM) deployment of the Contoso Azure Virtual Desktop landing zone for
the Module B MicroHack. One subscription-scope template composes every resource from pinned AVM
modules and implements the cross-track contract in [`../README.md`](../README.md) **exactly** —
the Terraform track in [`../terraform/`](../terraform/) exposes the identical parameters and
outputs.

> **Cost & safety:** this deploys real, billable Azure resources. Stand up the guardrails in
> [`../../scripts/setup/`](../../scripts/README.md) **first**, keep the lab footprint tiny
> (1–2 small session hosts — the default), and **tear down** with
> [`../../scripts/reset/`](../../scripts/README.md) when you are done. Never scale this to
> Contoso's full ~1,000-user footprint in the classroom; that is a paper design (see
> [Sizing](#scenario-sizing-paper-design-vs-lab)).

## Layout

```text
bicep/
  main.bicep              # subscription-scope orchestration of every AVM module
  main.lab.bicepparam     # lab footprint (1 small host, guardrails on) — DEFAULT
  main.prod.bicepparam    # paper-scale reference params (do NOT deploy in class)
  bicepconfig.json        # linter ruleset (security rules at error)
  modules/
    session-hosts.bicep   # VM loop: Entra join + host-pool registration + auto-shutdown
```

## What it deploys

| Layer | Resource | AVM module | Version |
|---|---|---|---|
| Resource group | `rg-avd-<env>-sec` | `avm/res/resources/resource-group` | `0.4.3` |
| Monitoring | Log Analytics workspace `law-avd-<env>-sec` | `avm/res/operational-insights/workspace` | `0.15.1` |
| Network | NSG `nsg-avd-<env>-sec` | `avm/res/network/network-security-group` | `0.5.3` |
| Network | VNet `vnet-avd-<env>-sec` (`snet-hosts`, `snet-pe`) | `avm/res/network/virtual-network` | `0.9.0` |
| Network | Private DNS zone `privatelink.file.*` | `avm/res/network/private-dns-zone` | `0.8.1` |
| Profiles | FSLogix storage `stavd<env>sec<unique>` + Files Premium share | `avm/res/storage/storage-account` | `0.32.1` |
| AVD | Host pool `hp-avd-<env>-sec` | `avm/res/desktop-virtualization/host-pool` | `0.8.1` |
| AVD | Desktop app group `ag-avd-<env>-sec-desktop` | `avm/res/desktop-virtualization/application-group` | `0.4.2` |
| AVD | Workspace `ws-avd-<env>-sec` | `avm/res/desktop-virtualization/workspace` | `0.9.2` |
| AVD | Scaling plan `sp-avd-<env>-sec` (Pooled only) | `avm/res/desktop-virtualization/scaling-plan` | `0.5.0` |
| Compute | Session hosts `vmavd<env>secNN` | `avm/res/compute/virtual-machine` | `0.22.2` |
| Cost | Subscription consumption budget | `avm/res/consumption/budget` | `0.3.8` |

All module versions are pinned in `main.bicep`. RBAC uses each module's built-in
`roleAssignments` (no standalone module): the optional `adminObjectId` is granted **Desktop
Virtualization User** on the app group and **Storage File Data SMB Share Contributor** on the
profile share.

## Parameters (contract)

These match the [contract](../README.md) and the Terraform track 1:1.

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `location` | string | `swedencentral` | Azure region (region short `sec`). |
| `environment` | string | `lab` | `lab` \| `prod`. Drives naming + sizing. |
| `namePrefix` | string | `avd` | Workload segment in every name. |
| `sessionHostCount` | int | `1` | Session hosts to deploy (0–50; keep 1–2 in labs). |
| `sessionHostSize` | string | `Standard_D4as_v5` | Session host VM SKU. |
| `hostPoolType` | string | `Pooled` | `Pooled` \| `Personal`. |
| `maxSessionLimit` | int | `8` | Max sessions per pooled host. |
| `profileStorageQuotaGb` | int | `128` | FSLogix Files Premium share quota (GB). |
| `deployScalingPlan` | bool | `true` | Deploy the autoscale plan (Pooled only). |
| `adminObjectId` | string | `''` | Entra user/group object ID for RBAC. Empty = skip. |
| `tags` | object | `{ owner: 'avd-platform-team' }` | Extra tags merged with the required tags. |

### Track-aligned extension parameters

Optional, with safe lab defaults; mirrored as variables on the Terraform track.

| Parameter | Default | Purpose |
|---|---|---|
| `sessionHostAdminUsername` | `avdadmin` | Local admin user on the session hosts. |
| `sessionHostAdminPassword` | `''` (`@secure()`) | Local admin password — **pass at deploy time**, never commit. |
| `deploySessionHosts` | `true` | Set `false` for an infra-only deploy (no password needed). |
| `vnetAddressSpace` | `10.10.0.0/16` | VNet address space. |
| `sessionHostSubnetPrefix` | `10.10.1.0/24` | Session host subnet. |
| `privateEndpointSubnetPrefix` | `10.10.2.0/24` | Private endpoint subnet. |
| `logAnalyticsRetentionDays` | `30` | Log Analytics retention. |
| `budgetAmount` | `200` | Monthly consumption budget. |
| `budgetContactEmails` | `[]` | Budget alert recipients. |

## Outputs

| Output | Description |
|---|---|
| `resourceGroupName` | The AVD resource group. |
| `hostPoolName` | Host pool name. |
| `workspaceName` | Workspace name. |
| `applicationGroupName` | Desktop application group name. |
| `storageAccountName` | FSLogix storage account name. |
| `profileShareName` | FSLogix profile file share name. |
| `logAnalyticsWorkspaceId` | Log Analytics workspace resource ID. |
| `sessionHostNames` | Names of the deployed session hosts (empty when none). |

## Usage

> **Prerequisites:** Azure CLI with the Bicep tooling (`az bicep version`), `Owner` or
> `Contributor` + `User Access Administrator` on the target subscription, and an Entra ID
> tenant with the AVD resource providers registered.

### 0. Guardrails first

```powershell
# Budget + auto-shutdown BEFORE any session host exists.
./scripts/setup/New-AvdLabGuardrails.ps1 -SubscriptionId <id> -Location swedencentral -BudgetAmount 50
```

### 1. Supply the session host password (never committed)

The local admin password is read from an environment variable at build/deploy time, so no
secret lands in source control:

```powershell
$env:AVD_LOCAL_ADMIN_PASSWORD = '<strong-unique-password>'
```

Leave it unset to validate or deploy infrastructure only — set `deploySessionHosts = false`.

### 2. Preview (what-if) — always before apply

```powershell
az deployment sub what-if `
  --location swedencentral `
  --template-file infra/bicep/main.bicep `
  --parameters infra/bicep/main.lab.bicepparam
```

### 3. Deploy

```powershell
az deployment sub create `
  --location swedencentral `
  --template-file infra/bicep/main.bicep `
  --parameters infra/bicep/main.lab.bicepparam
```

### 4. Tear down

```powershell
# Delete the lab resource group / AVD objects and confirm nothing remains.
./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Confirm
```

See [`../../scripts/README.md`](../../scripts/README.md) for the guardrail and teardown script
contracts.

## Local validation (no Azure required)

CI and the quality bar require a clean build and lint. Run the same checks locally:

```powershell
# Compile + lint the template and its module (zero warnings expected).
az bicep build --file infra/bicep/main.bicep
az bicep build --file infra/bicep/modules/session-hosts.bicep

# Compile the parameter files.
az bicep build-params --file infra/bicep/main.lab.bicepparam --stdout
az bicep build-params --file infra/bicep/main.prod.bicepparam --stdout
```

`bicepconfig.json` keeps the security analyzers (`secure-parameter-default`,
`outputs-should-not-contain-secrets`, `adminusername-should-not-be-literal`) at **error**.

## Security notes

- **No public data plane.** The storage account sets `publicNetworkAccess: 'Disabled'`,
  `allowSharedKeyAccess: false`, and `networkAcls.defaultAction: 'Deny'`. FSLogix reaches the
  Files share over a **private endpoint** in `snet-pe`, resolved by the
  `privatelink.file.*` private DNS zone linked to the VNet.
- **Entra Kerberos identity.** Profiles authenticate with Azure Files **Entra Kerberos**
  (`azureFilesIdentityBasedAuthentication`), so no on-prem AD or domain join is needed.
- **Entra-joined session hosts** with Trusted Launch, a system-assigned managed identity, the
  AAD login extension, and host-pool registration via the AVD DSC extension. The registration
  token is the host pool module's `registrationToken` output, passed as a `@secure()` value —
  it never appears in an output.
- **Secrets stay out of git.** The admin password is `@secure()` with an empty default and is
  sourced from `AVD_LOCAL_ADMIN_PASSWORD` in the `.bicepparam` files via
  `readEnvironmentVariable`.
- **Diagnostics everywhere.** Host pool, app group, workspace, the storage file service, and
  the session host platform send logs/metrics to Log Analytics.

## Scenario sizing (paper design vs lab)

The Contoso estate (see [`../../scenario/`](../../scenario/)) reconciles to **1,000 users**:

| Persona | Pool | Users |
|---|---|---|
| Knowledge workers | Pooled multi-session | 700 |
| Call centre | Pooled multi-session (time-based scaling) | 200 |
| Power users | Personal | 60 |
| Developers | Personal | 40 |
| **Total** | | **1,000** |

`main.prod.bicepparam` is a **paper-scale reference only** — a real rollout deploys per-persona
host pools in migration waves, not one 1,000-user pool. In the classroom always use
`main.lab.bicepparam` (token scale: a single small session host with guardrails on).

## Conventions

- **Naming:** `<type>-<namePrefix>-<environment>-<regionShort>` (e.g. `hp-avd-lab-sec`).
  Storage is `stavd<env>sec<unique>` (lowercase, ≤24 chars, no dashes).
- **Required tags** on every resource: `workload=avd-microhack`, `env`, `owner`,
  `costCenter=training`, `autoDelete=true`. Extra `tags` are merged in; an `owner` fallback is
  applied when none is supplied.
- **AVM-first**, every module version pinned. License-free / OSS only.
