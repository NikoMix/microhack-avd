# Infrastructure — the AVD landing zone (contract)

Two **equal, feature-equivalent** Infrastructure-as-Code tracks deploy the **same** Contoso AVD
landing zone:

- [`bicep/`](bicep/) — Azure Verified Modules in Bicep.
- [`terraform/`](terraform/) — Azure Verified Modules in Terraform.

Pick either in the deploy/validate challenges. Both **must** honour the contract below so the
challenges, scripts, and the `azure` MCP work identically regardless of track.

> Build to the **lab footprint by default** (1–2 session hosts, small SKUs). The full Contoso
> ~1,000-user design from the HLD stays on paper — see `.github/skills/avd-cost-guardrails`.

## Design source

Implement the High-Level Design produced in
[Challenge 02](../challenges/challenge-02-solution-design/) using the AVM module map in
[`.github/skills/avd-landing-zone`](../.github/skills/avd-landing-zone/SKILL.md).

## Required input parameters (same names on both tracks)

| Parameter | Type | Default (lab) | Purpose |
|---|---|---|---|
| `location` | string | `swedencentral` | Azure region |
| `environment` | string | `lab` | `lab` or `prod`; drives naming + sizing |
| `namePrefix` | string | `avd` | Workload segment in resource names |
| `sessionHostCount` | int | `1` | Number of session hosts (keep tiny in labs) |
| `sessionHostSize` | string | `Standard_D4as_v5` | Session host VM SKU |
| `hostPoolType` | string | `Pooled` | `Pooled` or `Personal` |
| `maxSessionLimit` | int | `8` | Max sessions per pooled host |
| `profileStorageQuotaGb` | int | `128` | Azure Files Premium share size |
| `deployScalingPlan` | bool | `true` | Attach an autoscale plan |
| `adminObjectId` | string | — | Entra object ID granted app-group access |
| `tags` | object/map | see below | Applied to every resource |

**Required tags on every resource:** `workload=avd-microhack`, `env=<environment>`, `owner`,
`costCenter=training`, `autoDelete=true`.

## Required outputs (same names on both tracks)

| Output | Example | Used by |
|---|---|---|
| `resourceGroupName` | `rg-avd-lab-sec` | reset/validate scripts, azure MCP |
| `hostPoolName` | `hp-avd-lab-sec` | validation, registration |
| `workspaceName` | `ws-avd-lab-sec` | client connection |
| `applicationGroupName` | `ag-avd-lab-sec-desktop` | assignment checks |
| `storageAccountName` | `stavdlabsec<unique>` | FSLogix checks |
| `profileShareName` | `profiles` | FSLogix path |
| `logAnalyticsWorkspaceId` | `/subscriptions/.../...` | AVD Insights / KQL |

## Naming convention

`<type>-<namePrefix>-<environment>-<regionShort>` — e.g. `hp-avd-lab-sec`,
`vnet-avd-lab-sec`. Region short codes in
[`.github/skills/avd-landing-zone/references/regions.md`](../.github/skills/avd-landing-zone/references/regions.md).

## Workflow (both tracks)

1. **Guardrails first** — `scripts/setup/` (budget + auto-shutdown). Never deploy without them.
2. **Preview** — `az deployment sub what-if` (Bicep) / `terraform plan` (Terraform). Read it.
3. **Apply** — deploy the lab footprint.
4. **Verify** — outputs above resolve; tags present; baseline config applied.
5. **Tear down** — `scripts/reset/` and confirm the resource group is empty.

Each track's own `README.md` documents the exact commands and parameter files.
