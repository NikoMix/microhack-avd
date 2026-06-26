---
applyTo: "infra/terraform/**/*.tf"
---
# Terraform authoring rules (AVD landing zone)

- **AVM-first.** Use Azure Verified Modules (`source = "Azure/avm-res-.../azurerm"`) for every
  resource that has one, with a pinned `version`. Look up modules/inputs via the **`terraform`
  MCP** and the Terraform Registry. Don't hand-roll what an AVM module covers.
- **Providers:** pin `azurerm` (and `azuread`/`random` as needed) in `terraform.required_providers`
  with a `~>` constraint on a current major. Pin `required_version` for Terraform itself.
- **Structure:** `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`; per-env `*.tfvars`
  (`lab.tfvars`, `prod.tfvars`). Keep state local for the lab (document remote state for prod).
- **Variables:** typed, described, with lab-safe defaults (1–2 hosts, small SKUs);
  `location` defaults to `swedencentral`.
- **Naming & tags:** `<type>-avd-<env>-<region>`; a shared `tags` local/variable applied to every
  resource (`workload=avd-microhack`, `env`, `owner`, `costCenter=training`, `autoDelete=true`).
- **Outputs:** mirror the Bicep track and `infra/README.md` (host pool, workspace, storage,
  resource group) so challenges work identically on either track.
- **Quality:** must pass `terraform fmt -check`, `terraform validate`, and `tflint`. No secrets in
  code or state-visible plaintext; use Key Vault data sources / variables marked `sensitive`.
- **Always `terraform plan` before apply.**
