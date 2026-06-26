# Terraform track — AVD landing zone

> **Status:** scaffolded — implemented by the Terraform workstream. Build to the contract in
> [`../README.md`](../README.md).

Azure Verified Modules (Terraform) deployment of the Contoso AVD landing zone.

## Planned layout

```text
terraform/
  main.tf            # AVM module composition
  variables.tf       # inputs (match the infra contract names)
  outputs.tf         # outputs (match the infra contract names)
  providers.tf       # pinned azurerm / azuread / random
  lab.tfvars         # lab footprint (1–2 hosts, small SKUs) — default
  prod.tfvars        # paper-scale reference values
```

## Usage (target)

```bash
# 1. Guardrails first (see scripts/setup/)

cd infra/terraform
terraform init

# 2. Preview
terraform plan -var-file=lab.tfvars

# 3. Deploy
terraform apply -var-file=lab.tfvars

# 4. Tear down
terraform destroy -var-file=lab.tfvars   # and/or scripts/reset/
```

Must satisfy the [input variables and outputs](../README.md) and pass `terraform fmt -check`,
`terraform validate`, and `tflint` (enforced in CI). Pin the `azurerm` provider and every AVM
module version. Look up modules via the **`terraform` MCP**.
