# `load-test/` — classroom-scale load

A **license-free** synthetic load generator so the validation signals (logon time, density,
FSLogix IO) have data to measure in [challenge-06](../../challenges/challenge-06-service-validation/).
No paid SaaS, no agents to install.

> **Token scale only.** This is a signal generator for the lab, never a Contoso-scale stress
> test. Concurrency and duration are range-validated and the workload self-terminates.

## `Invoke-AvdLoadTest.ps1`

Resolves the lab's Windows session hosts (resource group, Bicep, or Terraform) and dispatches an
in-guest PowerShell workload via `az vm run-command invoke`. Each targeted host spins up a small
number of worker jobs that mix light CPU work with FSLogix-style profile file IO for a capped
duration, then clean up after themselves.

### Parameters

| Parameter | Default | Range | Notes |
|---|---|---|---|
| `-ConcurrentUsers` | `3` | 1–25 | Worker sessions per host |
| `-DurationMinutes` | `3` | 1–30 | Blocks ~this long per host |
| `-MaxHosts` | `2` | 1–10 | Caps fan-out (cost/time) |
| `-ResourceGroup` / `-BicepDeploymentName` / `-TerraformDir` | — | — | Track-agnostic resolution |

Returns a result object per host (`Host`, `ConcurrentUsers`, `DurationMinutes`, `Status`,
`Detail`). With no session hosts it returns a single `Skipped` result instead of failing.

### Examples

```powershell
# Five synthetic users for five minutes across up to two hosts
./Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -ConcurrentUsers 5 -DurationMinutes 5

# Preview what would run without touching a host
./Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf
```

After a run, collect the signals with [`../validate/Test-AvdService.ps1`](../validate/) and tear
the lab down with [`../reset/`](../reset/).
