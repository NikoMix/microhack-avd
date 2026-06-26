# `reset/` — teardown

The **end-of-day teardown**. Deletes the lab and confirms nothing remains, while honouring the
cost guardrails. Every live-deploy challenge ends here.

> **Refuses to delete anything untagged.** The script only ever touches a resource group tagged
> as a disposable MicroHack lab (`workload=avd-microhack` or `autoDelete=true`), so it can never
> delete a real environment.

## `Remove-AvdLab.ps1`

Idempotent and gated by `ShouldProcess` with `ConfirmImpact=High` (so `-Confirm` prompts by
default and `-WhatIf` shows exactly what would go).

### Scopes

| `-Scope` | Deletes | Keeps |
|---|---|---|
| `ResourceGroup` (default) | The entire lab resource group; polls until gone | Nothing (budget goes with the RG — re-run `setup` to recreate guardrails) |
| `AvdObjects` | AVD objects + session-host compute (VMs, disks, NICs) | Resource group, network, storage (FSLogix profiles), and budget (unless `-RemoveBudget`) |

`AvdObjects` deletes in a dependency-safe order (scaling plans → VMs → app groups → workspaces →
host pools → disks → NICs) so a partial reset for redeploy succeeds cleanly.

### Behaviour

- A missing resource group reports success (`Deleted=$true`, `RemainingResourceCount=0`).
- Returns `ResourceGroup`, `Scope`, `Safe`, `Deleted`, `RemainingResourceCount`, `Reason`.

### Examples

```powershell
# Full teardown (prompts to confirm)
./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Confirm

# Keep the RG, network and FSLogix profiles; delete AVD + compute only
./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Scope AvdObjects

# Preview only — change nothing
./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf
```

Recreate the guardrails for the next run with [`../setup/`](../setup/).
