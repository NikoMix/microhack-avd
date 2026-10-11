<!-- TEMPLATE — copy to challenges/challenge-05-deploy/work/deployment.md and fill in.
     Control B.3.1 Deploy to Production. Preview (what-if/plan) BEFORE apply. -->
# Contoso AVD — Production Deployment (B.3.1)

> Author · Date · IaC track (Bicep | Terraform)

## 1. Pre-flight

- [ ] Budget + auto-shutdown deployed (`scripts/setup/`)
- [ ] Region + vCPU quota confirmed (azure MCP)
- [ ] Parameters / tfvars set from the HLD
- [ ] Identity prerequisites in place (Entra / Intune / Kerberos)

## 2. Preview (what-if / plan)
<!-- Paste/summarise `az deployment ... what-if` or `terraform plan`: what will be created,
     resource count, cost shape. -->

```text
<preview output summary>
```

## 3. Deploy

- Deployment / run ID:
- Resources created (from azure MCP):

| Resource | Name | SKU/Tier | Tags OK? |
|---|---|---|---|
|  |  |  |  |

## 4. Configuration baseline (verify each)

- [ ] Host pool RDP properties (Shortpath, redirections)
- [ ] FSLogix settings applied
- [ ] Scaling plan assigned
- [ ] Conditional Access targeted
- [ ] Monitoring / AVD Insights on

## 5. Go-Live & cutover (waves)

| Wave | Persona(s) | Entry criteria | Validation gate | Comms |
|---|---|---|---|---|
| 1 | Pilot |  |  |  |

## 6. Rollback
<!-- Per-wave fallback to legacy RDS/Citrix; trigger conditions; exact steps; teardown
     procedure (scripts/reset/). -->
