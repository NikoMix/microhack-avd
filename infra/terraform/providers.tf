###############################################################################
# providers.tf — provider + version pinning for the AVD landing zone (Terraform)
#
# Pins are intentionally explicit (quality bar: reproducible, vuln-free builds).
#   * terraform >= 1.10  — required floor of avm-res-compute-virtualmachine 0.21.0
#   * azurerm   ~> 4.36  — required floor of avm-res-operationalinsights-workspace
#                          0.5.1; all other AVM modules cap at < 5.0.0
#   * random    ~> 3.6   — used for storage/Key Vault global-uniqueness suffixes
#                          and the break-glass local-admin password
#
# azapi / modtm are pulled in transitively by the AzAPI-based AVM modules
# (resource group, virtual network, storage account, private DNS zone). Terraform
# installs and default-configures them automatically; no root provider block is
# required for them.
###############################################################################

terraform {
  required_version = ">= 1.10, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.36"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  # Data-plane access to Storage is authenticated with Microsoft Entra ID rather
  # than shared keys, matching the AzAPI storage module's secure default.
  storage_use_azuread = true

  features {
    resource_group {
      # Safety net for classroom teardown: never silently delete an RG that still
      # contains resources — the reset scripts own deletion explicitly.
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
