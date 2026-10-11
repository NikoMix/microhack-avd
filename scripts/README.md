# Scripts — lab automation (contract)

> **Status:** delivered by the deployment workstream. Cross-platform
> **PowerShell 7+**; see [`.github/instructions/powershell.instructions.md`](../.github/instructions/powershell.instructions.md).

Helper scripts for the live-deploy challenges. Each folder has one job. All scripts are
idempotent, support `-WhatIf`/`-Confirm` for anything that creates or deletes Azure resources,
take the subscription/region as parameters (never hardcoded), and must pass `PSScriptAnalyzer`.

## Folders & interface

| Folder | Purpose | Key script (target) | Notes |
|---|---|---|---|
| [`setup/`](setup/) | **Guardrails first.** Create a Consumption budget with alerts + session-host auto-shutdown | `New-AvdLabGuardrails.ps1` | Run before any deploy (C00/C05) |
| [`validate/`](validate/) | Service-validation helpers: logon-time KQL, app-launch, FSLogix integrity, scaling/failover checks | `Test-AvdService.ps1` | Feeds C06 evidence |
| [`load-test/`](load-test/) | Lightweight, classroom-scale logon/density generation | `Invoke-AvdLoadTest.ps1` | Small scale only — never Contoso-scale |
| [`reset/`](reset/) | **Teardown.** Delete the lab resource group / AVD objects and confirm nothing remains | `Remove-AvdLab.ps1` | Confirms target RG before deleting |
| `lib/` | Shared functions (auth, naming, tagging, Azure helpers) | `Common.psm1` | Imported by the others |

## Conventions

- Names + tags follow the [infra contract](../infra/README.md).
- Cost-safe defaults: small SKUs, 1–2 hosts; budget required before deploy; teardown verified.
- Output objects (not formatted strings); progress via `Write-Verbose`/`Write-Information`.
- Comment-based help (`.SYNOPSIS`/`.PARAMETER`/`.EXAMPLE`) on every script.

## Target usage

```powershell
# Guardrails (C00 / before C05)
./scripts/setup/New-AvdLabGuardrails.ps1 -SubscriptionId <id> -Location swedencentral -BudgetAmount 50

# Validate (C06)
./scripts/validate/Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec

# Tear down (end of day)
./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Confirm
```
