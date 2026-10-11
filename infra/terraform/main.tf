###############################################################################
# main.tf — AVD landing zone (Azure Verified Modules, Terraform track)
#
# Deploys, in dependency order:
#   resource group → Log Analytics → NSG → virtual network (+subnets) →
#   private DNS zone → FSLogix storage (Azure Files Premium, Entra Kerberos) →
#   Key Vault (break-glass secret) → host pool → application group → workspace →
#   workspace/app-group association → scaling plan → session host(s) →
#   cost guardrails (budget + per-VM auto-shutdown).
#
# Every module version is pinned (providers.tf documents the why). All names and
# tags come from locals.tf so the Terraform and Bicep tracks stay interchangeable.
###############################################################################

data "azurerm_client_config" "current" {}

# 4-char lowercase/numeric suffix for the globally-unique storage + Key Vault names.
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Break-glass local-admin password for the session hosts. Stored only in Key Vault;
# the override set avoids characters that trip up Windows unattended provisioning.
resource "random_password" "vm" {
  length           = 24
  special          = true
  override_special = "!#%*_-+="
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

# Storage private endpoint is only created when private endpoints are enabled. The
# conditional short-circuits the private_dns_zone[0] index when disabled (count 0).
locals {
  storage_private_endpoints = local.deploy_private_endpoint ? {
    file = {
      name                          = local.names.private_endpoint
      subnet_resource_id            = module.vnet.subnets["pe"].resource_id
      subresource_name              = "file"
      private_dns_zone_resource_ids = [module.private_dns_zone[0].resource_id]
    }
  } : {}
}

#==============================================================================
# Resource group (AVM, AzAPI-based)
#==============================================================================

module "rg" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = local.names.resource_group
  location         = var.location
  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Log Analytics workspace — single sink for all diagnostic settings
#==============================================================================

module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                = local.names.log_analytics
  location            = var.location
  resource_group_name = module.rg.name

  log_analytics_workspace_retention_in_days = var.logAnalyticsRetentionDays

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Network security group for the session-host subnet
#
# AVD session hosts use the reverse-connect transport, so they need no inbound
# rules from the internet; the NSG default rules (deny internet inbound, allow
# intra-VNet) are the correct secure baseline. Tighten egress in production.
#==============================================================================

module "nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = local.names.nsg
  location            = var.location
  resource_group_name = module.rg.name

  diagnostic_settings = local.diagnostics_to_law

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Virtual network + subnets (AVM, AzAPI-based)
#   - avd subnet: session hosts; carries a Microsoft.Storage service endpoint so
#     the FSLogix account can be reached even when public access is locked down.
#   - pe subnet:  private endpoints for the storage account.
#==============================================================================

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = local.names.virtual_network
  location      = var.location
  parent_id     = module.rg.resource_id
  address_space = [var.vnetAddressSpace]

  subnets = {
    avd = {
      name             = local.names.avd_subnet
      address_prefixes = [var.sessionHostSubnetPrefix]
      network_security_group = {
        id = module.nsg.resource_id
      }
      service_endpoints_with_location = [
        {
          service = "Microsoft.Storage"
        }
      ]
    }
    pe = {
      name                              = local.names.pe_subnet
      address_prefixes                  = [var.privateEndpointSubnetPrefix]
      private_endpoint_network_policies = "Disabled"
    }
  }

  diagnostic_settings = local.diagnostics_to_law

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Private DNS zone for the FSLogix storage account (privatelink.file...)
# Only created when private endpoints are enabled.
#==============================================================================

module "private_dns_zone" {
  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"
  count   = local.deploy_private_endpoint ? 1 : 0

  domain_name = local.names.private_dns_zone
  parent_id   = module.rg.resource_id

  virtual_network_links = {
    avd = {
      name               = local.names.vnet_link
      virtual_network_id = module.vnet.resource_id
    }
  }

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# FSLogix profile storage — Azure Files Premium with Entra Kerberos
#   - FileStorage / Premium SKU, share sized for peak-logon IOPS.
#   - Identity-based access via AADKERB (Entra-joined hosts); shared keys off.
#   - Network locked to the avd subnet (service endpoint) + optional private
#     endpoint; public network access disabled when private endpoints are on.
#==============================================================================

module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name      = local.names.storage_account
  location  = var.location
  parent_id = module.rg.resource_id

  account_kind                  = "FileStorage"
  account_sku_name              = var.profileStorageSku
  public_network_access_enabled = !local.deploy_private_endpoint
  shared_access_key_enabled     = false

  azure_files_authentication = {
    directory_type = "AADKERB"
  }

  network_rules = {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [module.vnet.subnets["avd"].resource_id]
  }

  shares = {
    profiles = {
      name        = local.names.profile_share
      quota       = var.profileStorageQuotaGb
      access_tier = "Premium"
    }
  }

  private_endpoints                       = local.storage_private_endpoints
  private_endpoints_manage_dns_zone_group = local.deploy_private_endpoint

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Key Vault — stores the break-glass local-admin password
#==============================================================================

module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.11.0"

  name                = local.names.key_vault
  location            = var.location
  resource_group_name = module.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                      = "standard"
  public_network_access_enabled = true
  purge_protection_enabled      = false # lab: allow clean teardown. Enable in prod.
  soft_delete_retention_days    = 7

  role_assignments = local.key_vault_role_assignments

  secrets = {
    vmadmin = {
      name = local.names.local_admin_secret
    }
  }
  secrets_value = {
    vmadmin = local.admin_password
  }

  diagnostic_settings = local.diagnostics_to_law

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# AVD host pool (pooled multi-session by default, Entra-joined session hosts)
#==============================================================================

module "hostpool" {
  source  = "Azure/avm-res-desktopvirtualization-hostpool/azurerm"
  version = "0.4.0"

  resource_group_name = module.rg.name

  virtual_desktop_host_pool_resource_group_name = module.rg.name
  virtual_desktop_host_pool_name                = local.names.host_pool
  virtual_desktop_host_pool_location            = var.location
  virtual_desktop_host_pool_type                = var.hostPoolType
  virtual_desktop_host_pool_load_balancer_type  = local.load_balancer_type

  virtual_desktop_host_pool_maximum_sessions_allowed         = local.maximum_sessions
  virtual_desktop_host_pool_preferred_app_group_type         = "Desktop"
  virtual_desktop_host_pool_start_vm_on_connect              = true
  virtual_desktop_host_pool_custom_rdp_properties            = local.custom_rdp_properties
  virtual_desktop_host_pool_personal_desktop_assignment_type = local.personal_assignment

  diagnostic_settings = local.diagnostics_to_law

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Desktop application group + workspace, then their association
#==============================================================================

module "application_group" {
  source  = "Azure/avm-res-desktopvirtualization-applicationgroup/azurerm"
  version = "0.2.1"

  virtual_desktop_application_group_host_pool_id        = module.hostpool.resource_id
  virtual_desktop_application_group_location            = var.location
  virtual_desktop_application_group_name                = local.names.application_group
  virtual_desktop_application_group_resource_group_name = module.rg.name
  virtual_desktop_application_group_type                = "Desktop"

  role_assignments                       = local.application_group_role_assignments
  virtual_desktop_application_group_tags = local.tags
  enable_telemetry                       = var.enableTelemetry
}

module "workspace" {
  source  = "Azure/avm-res-desktopvirtualization-workspace/azurerm"
  version = "0.2.2"

  virtual_desktop_workspace_location            = var.location
  virtual_desktop_workspace_name                = local.names.workspace
  virtual_desktop_workspace_resource_group_name = module.rg.name

  diagnostic_settings            = local.diagnostics_to_law
  public_network_access_enabled  = true
  virtual_desktop_workspace_tags = local.tags
  enable_telemetry               = var.enableTelemetry
}

# The AVM workspace module does not manage the workspace↔app-group link.
resource "azurerm_virtual_desktop_workspace_application_group_association" "this" {
  workspace_id         = module.workspace.resource_id
  application_group_id = module.application_group.resource_id
}

#==============================================================================
# Autoscale scaling plan (pooled host pools only)
#==============================================================================

module "scaling_plan" {
  source  = "Azure/avm-res-desktopvirtualization-scalingplan/azurerm"
  version = "0.2.1"
  count   = local.deploy_scaling_plan ? 1 : 0

  virtual_desktop_scaling_plan_location            = var.location
  virtual_desktop_scaling_plan_name                = local.names.scaling_plan
  virtual_desktop_scaling_plan_resource_group_name = module.rg.name
  virtual_desktop_scaling_plan_time_zone           = var.timeZone
  virtual_desktop_scaling_plan_schedule            = local.scaling_plan_schedule

  virtual_desktop_scaling_plan_host_pool = [
    {
      hostpool_id          = module.hostpool.resource_id
      scaling_plan_enabled = true
    }
  ]

  virtual_desktop_scaling_plan_tags = local.tags
  enable_telemetry                  = var.enableTelemetry
}

#==============================================================================
# Session hosts (lab: 1-2; Contoso's full fleet stays a paper design)
#   - Entra-joined (AADLoginForWindows) + registered to the host pool (AVD DSC).
#   - System-assigned managed identity; OS disk per var.osDiskStorageType.
#==============================================================================

module "session_host" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"
  count   = local.session_host_count

  name                = format("%s%02d", local.names.session_host_prefix, count.index)
  location            = var.location
  resource_group_name = module.rg.name
  zone                = var.availabilityZone

  os_type  = "Windows"
  sku_size = var.sessionHostSize

  # Trusted Launch (Gen2): Secure Boot + vTPM. Matches the Win11 multi-session
  # Gen2 image and mirrors the Bicep track's security baseline.
  secure_boot_enabled = true
  vtpm_enabled        = true

  account_credentials = {
    admin_credentials = {
      username                           = var.sessionHostAdminUsername
      password                           = local.admin_password
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = false
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = var.osDiskStorageType
  }

  source_image_reference = {
    publisher = var.imagePublisher
    offer     = var.imageOffer
    sku       = var.imageSku
    version   = var.imageVersion
  }

  network_interfaces = {
    primary = {
      name = "nic-${format("%s%02d", local.names.session_host_prefix, count.index)}"
      ip_configurations = {
        ipconfig1 = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.vnet.subnets["avd"].resource_id
        }
      }
    }
  }

  managed_identities = {
    system_assigned = true
  }

  extensions = {
    aad_login = {
      name                       = "AADLoginForWindows"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADLoginForWindows"
      type_handler_version       = "2.0"
      auto_upgrade_minor_version = true
      deploy_sequence            = 1
    }
    avd_dsc = {
      name                       = "AddSessionHost"
      publisher                  = "Microsoft.Powershell"
      type                       = "DSC"
      type_handler_version       = "2.73"
      auto_upgrade_minor_version = true
      deploy_sequence            = 2
      provision_after_extensions = ["AADLoginForWindows"]
      settings = jsonencode({
        modulesUrl            = var.avdAgentDscUrl
        configurationFunction = "Configuration.ps1\\AddSessionHost"
        properties = {
          hostPoolName = local.names.host_pool
          aadJoin      = true
        }
      })
      protected_settings = jsonencode({
        properties = {
          registrationInfoToken = module.hostpool.registrationinfo_token
        }
      })
    }
  }

  tags             = local.tags
  enable_telemetry = var.enableTelemetry
}

#==============================================================================
# Cost guardrails (native azurerm — no AVM module exists)
#   - Monthly resource-group budget with 80% actual / 100% forecast alerts.
#   - Daily auto-shutdown schedule per session host.
# Deploy these BEFORE creating session hosts in any real run (see README).
#==============================================================================

resource "azurerm_consumption_budget_resource_group" "this" {
  name              = local.names.budget
  resource_group_id = module.rg.resource_id
  amount            = var.budgetAmount
  time_grain        = "Monthly"

  time_period {
    start_date = var.budgetStartDate
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Actual"
    contact_emails = var.budgetContactEmails
    contact_roles  = ["Owner"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThanOrEqualTo"
    threshold_type = "Forecasted"
    contact_emails = var.budgetContactEmails
    contact_roles  = ["Owner"]
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "this" {
  count = var.enableAutoShutdown ? local.session_host_count : 0

  virtual_machine_id    = module.session_host[count.index].resource_id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.autoShutdownTime
  timezone              = var.autoShutdownTimeZone

  notification_settings {
    enabled = false
  }

  tags = local.tags
}
