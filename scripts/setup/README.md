# `setup/` — guardrails first

Create the **cost guardrails** before any session hosts exist. Run this in
[challenge-00](../../challenges/challenge-00-setup/) and again before
[challenge-05](../../challenges/challenge-05-deploy-to-production/).

> **Guardrails before resources.** This is a paid Azure subscription — a budget and
> auto-shutdown are the difference between a lab and a surprise bill.

## `New-AvdLabGuardrails.ps1`

Idempotent and safe to re-run. It:

1. Ensures the lab resource group exists and carries the required tags
   (`workload=avd-microhack`, `env`, `owner`, `costCenter=training`, `autoDelete=true`).
2. Creates / updates a **monthly, resource-group-scoped Consumption budget** with **50 / 80 / 100 %**
   alerts, deployed via an ARM template (`az deployment group create`) so it upserts cleanly on
   both the Bicep and Terraform tracks.
3. Applies **auto-shutdown** to every VM already in the group (re-run after deploying session
   hosts to protect them; cleanly skips when no VMs exist yet).

### Parameters (most common)

| Parameter | Default | Notes |
|---|---|---|
| `-SubscriptionId` | signed-in sub | Never hardcoded |
| `-Location` | `swedencentral` | Drives the naming short code |
| `-ResourceGroup` | `rg-avd-<env>-<region>` | Contract name when omitted |
| `-BudgetAmount` | `50` | Monthly ceiling |
| `-Owner` | signed-in user | `owner` tag + budget contact |
| `-ShutdownTime` / `-ShutdownTimeZone` | `1900` / `W. Europe Standard Time` | Per-VM auto-shutdown |
| `-SkipAutoShutdown` | off | Budget + tags only |

### Examples

```powershell
# Before any deploy (challenge-00 / challenge-05)
./New-AvdLabGuardrails.ps1 -SubscriptionId <id> -Location swedencentral -BudgetAmount 50

# Preview the budget change without applying it
./New-AvdLabGuardrails.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf

# Re-run after deploying session hosts to apply auto-shutdown to them
./New-AvdLabGuardrails.ps1 -ResourceGroup rg-avd-lab-sec
```

When you are done with the lab, tear it down with [`../reset/`](../reset/).
