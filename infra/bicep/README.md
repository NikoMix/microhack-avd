# Bicep track — AVD landing zone

> **Status:** scaffolded — implemented by the Bicep workstream. Build to the contract in
> [`../README.md`](../README.md).

Azure Verified Modules (Bicep) deployment of the Contoso AVD landing zone.

## Planned layout

```text
bicep/
  main.bicep            # subscription-scope orchestration of the AVM modules
  main.lab.bicepparam   # lab footprint (1–2 hosts, small SKUs) — default
  main.prod.bicepparam  # paper-scale reference params
  modules/              # thin wrappers where an AVM module needs composing
```

## Usage (target)

```bash
# 1. Guardrails first
#    (see scripts/setup/)

# 2. Preview
az deployment sub what-if \
  --location swedencentral \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.lab.bicepparam

# 3. Deploy
az deployment sub create \
  --location swedencentral \
  --template-file infra/bicep/main.bicep \
  --parameters infra/bicep/main.lab.bicepparam

# 4. Tear down → scripts/reset/
```

Must satisfy the [input parameters and outputs](../README.md) and pass `az bicep build` +
`az bicep lint` (enforced in CI). Pin every AVM module version.
