# `lib/` — shared script library

`Common.psm1` is the shared PowerShell module imported by every lab script
(`setup`, `validate`, `load-test`, `reset`). It centralises the things that must be **identical**
across scripts and across the two IaC tracks, so the challenge scripts stay short and consistent.

> Cross-platform **PowerShell 7+**. Read-only — anything that mutates Azure lives in the scripts
> and supports `-WhatIf`/`-Confirm`. Passes `PSScriptAnalyzer` (Warning + Error clean).

## What it provides

| Area | Functions |
|---|---|
| Logging | `Write-AvdLog` (Information/Verbose/Warning — never `Write-Host`) |
| Azure CLI | `Invoke-AzCommand` (`-Json`, `-AllowFailure`), `Get-AvdAzContext` |
| Naming & tags | `Get-AvdRegionShortCode`, `Get-AvdResourceName`, `Get-AvdRequiredTag`, `ConvertTo-AvdTagArgument` |
| Track-agnostic context | `Get-AvdLabContext` — resolves the [infra contract](../../infra/README.md) outputs from Terraform state, a Bicep deployment, a resource group, or tag discovery |
| Teardown guard | `Test-AvdSafeToDelete` — refuses anything not tagged `workload=avd-microhack` / `autoDelete=true` |
| Validation checks | `Get-AvdLogonPerformance`, `Test-AvdAppDelivery`, `Test-AvdFsLogixIntegrity`, `Test-AvdScalingPlan`, `Test-AvdResilience` |
| Output | `ConvertTo-AvdMarkdownTable` (for the evidence artifacts) |

## The track-agnostic context object

`Get-AvdLabContext` returns one object whose property names match `infra/README.md`, so the
scripts behave identically whether the lab was built with Bicep or Terraform:

```text
Track, ResourceGroupName, Location, HostPoolName, WorkspaceName, ApplicationGroupName,
StorageAccountName, ProfileShareName, LogAnalyticsWorkspaceId, ScalingPlanName
```

```powershell
Import-Module ./Common.psm1
Get-AvdLabContext -ResourceGroup     rg-avd-lab-sec        # discovery
Get-AvdLabContext -BicepDeploymentName avd-lab             # Bicep outputs
Get-AvdLabContext -TerraformDir      ../../infra/terraform # Terraform state
```

## Validation check shape

Every check returns a uniform object so the validate orchestrator can table them up:

```text
Test, Method, Target, Actual, Status (Pass | Fail | Inconclusive | Skipped), Evidence
```

See the [scripts contract](../README.md) for the folder interface and conventions.
