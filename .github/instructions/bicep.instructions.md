---
applyTo: "infra/bicep/**/*.bicep"
---
# Bicep authoring rules (AVD landing zone)

- **AVM-first.** Use Azure Verified Modules (`br/public:avm/res/...`) for every resource that has
  one. Pin the module version explicitly (`:x.y.z`). Do not hand-roll a resource an AVM module
  covers. Discover modules at <https://azure.github.io/Azure-Verified-Modules/>.
- **Structure:** `main.bicep` (subscription or resourceGroup scope) orchestrates modules; keep
  reusable wrappers under `modules/`. Use `.bicepparam` files per environment (`lab`, `prod`).
- **Parameters:** strongly typed, with `@description` and sensible `@allowed`/defaults. Default
  to the **small/lab** footprint (1–2 hosts, small SKUs). Expose a `location` defaulting to
  `swedencentral`.
- **Naming & tags:** follow `<type>-avd-<env>-<region>`; apply the required tags
  (`workload=avd-microhack`, `env`, `owner`, `costCenter=training`, `autoDelete=true`) on every
  resource via a shared `tags` object.
- **Outputs:** export the IDs/names the challenges and the `azure` MCP need (host pool name,
  workspace name, storage account, resource group) — keep them aligned with `infra/README.md`.
- **Safety:** never embed secrets; use Key Vault references / secure params. Code must pass
  `az bicep build` and `az bicep lint` with no errors. Always design for a `what-if` preview.
- **No drift from the HLD:** parameter names and topology must match
  `challenges/challenge-02-design` and the Terraform track's variables 1:1.
