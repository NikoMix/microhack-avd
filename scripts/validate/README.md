# `validate/` — service-validation helpers

Read-only checks that feed the **control B.4.1** evidence in
[challenge-06](../../challenges/challenge-06-service-validation/). Nothing here changes Azure
state — it measures what the deployment is actually doing and tables it up for
`work/validation.md`.

## `Test-AvdService.ps1`

Resolves the lab the same way regardless of IaC track (resource group, Bicep deployment, or
Terraform state) and runs five checks:

| Check | Signal | Pass condition |
|---|---|---|
| Logon performance | P50/P95 from `WVDConnections` (KQL) | P95 ≤ `-TargetLogonSeconds` (default 30) |
| Application launch | App groups present + assigned | ≥ 1 app group with ≥ 1 assignment |
| FSLogix integrity | Premium Files share + redundancy | Premium share reachable |
| Autoscaling | Scaling plan enabled + host-pool ref | Enabled plan referencing the host pool |
| Failover / resilience | Storage replication + host count | Redundant storage; ≥ 1 host |

Each returns `Test / Method / Target / Actual / Status / Evidence`. `Status` is
`Pass | Fail | Inconclusive | Skipped` (Inconclusive when the resource is not deployed yet —
generate signals first with [`../load-test/`](../load-test/)).

### Examples

```powershell
# Resource-group discovery, objects to the pipeline
./Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec

# Terraform track, emit the Markdown table for work/validation.md
./Test-AvdService.ps1 -TerraformDir ../../infra/terraform -AsMarkdown

# Bicep track, custom logon target and lookback window
./Test-AvdService.ps1 -BicepDeploymentName avd-lab -TargetLogonSeconds 25 -LookbackHours 4
```

> Tip: run [`../load-test/Invoke-AvdLoadTest.ps1`](../load-test/) first so the logon-performance
> KQL has connections to measure, then re-run with `-AsMarkdown` and paste the table into the
> evidence artifact.
