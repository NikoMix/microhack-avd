###############################################################################
# locals.tf — naming, tagging, and derived values
#
# Naming convention (infra/README.md): <type>-<namePrefix>-<environment>-<regionShort>
#   rg-avd-lab-sec · vnet-avd-lab-sec · hp-avd-lab-sec · ws-avd-lab-sec
#   ag-avd-lab-sec-desktop · stavdlabsec<unique>
###############################################################################

locals {
  # Canonical region short codes (.github/skills/avd-landing-zone/references/regions.md).
  region_short_codes = {
    swedencentral = "sec"
    westeurope    = "weu"
    northeurope   = "neu"
    uksouth       = "uks"
    eastus        = "eus"
    eastus2       = "eus2"
    westus2       = "wus2"
    centralus     = "cus"
    australiaeast = "aue"
    southeastasia = "sea"
  }

  # Fall back to the first six characters of the region if it is not in the table.
  region_short = lookup(local.region_short_codes, var.location, substr(var.location, 0, 6))

  # <namePrefix>-<environment>-<regionShort> — e.g. "avd-lab-sec".
  base_name = "${var.namePrefix}-${var.environment}-${local.region_short}"

  # Short, dash-free token for the globally-unique / 15-char-limited names.
  compact = lower("${var.namePrefix}${var.environment}${local.region_short}")

  names = {
    resource_group      = "rg-${local.base_name}"
    log_analytics       = "log-${local.base_name}"
    virtual_network     = "vnet-${local.base_name}"
    nsg                 = "nsg-${local.base_name}"
    avd_subnet          = "snet-avd-${local.base_name}"
    pe_subnet           = "snet-pe-${local.base_name}"
    host_pool           = "hp-${local.base_name}"
    application_group   = "ag-${local.base_name}-desktop"
    workspace           = "ws-${local.base_name}"
    scaling_plan        = "sp-${local.base_name}"
    key_vault           = substr("kv-${local.compact}-${random_string.suffix.result}", 0, 24)
    budget              = "budget-${local.base_name}"
    private_dns_zone    = "privatelink.file.core.windows.net"
    private_endpoint    = "pe-st-${local.base_name}-file"
    storage_account     = substr("st${local.compact}${random_string.suffix.result}", 0, 24)
    session_host_prefix = substr("vm${local.compact}", 0, 13)
    profile_share       = "profiles"
    vnet_link           = "vnl-${local.base_name}"
    local_admin_secret  = "vm-local-admin-password"
  }

  # Mandatory tags (infra/README.md) merged with caller-supplied tags.
  required_tags = {
    workload   = "avd-microhack"
    env        = var.environment
    owner      = var.owner
    costCenter = "training"
    autoDelete = "true"
  }
  tags = merge(local.required_tags, var.tags)

  # Pooled vs Personal behaviour.
  is_pooled               = var.hostPoolType == "Pooled"
  load_balancer_type      = local.is_pooled ? "BreadthFirst" : "Persistent"
  maximum_sessions        = local.is_pooled ? var.maxSessionLimit : null
  deploy_scaling_plan     = var.deployScalingPlan && local.is_pooled
  personal_assignment     = local.is_pooled ? null : "Automatic"
  deploy_private_endpoint = var.enablePrivateEndpoints

  # Standard AVM diagnostic-settings block pointing at the workspace ("allLogs"
  # + "AllMetrics"). Reused across the host pool, workspace, NSG, and Key Vault.
  diagnostics_to_law = {
    toLaw = {
      name                  = "diag-to-law"
      workspace_resource_id = module.log_analytics.resource_id
    }
  }

  # Custom RDP properties: multi-monitor, device/clipboard redirection tuned for
  # knowledge workers; credential security and Entra single sign-on. The host pool
  # AVM module renders this typed object into the Azure RDP property string; extra
  # properties (camera, audio capture, Entra SSO) go through custom_properties as
  # "name" => "type:value" pairs.
  custom_rdp_properties = {
    drivestoredirect     = ""
    audiomode            = 0
    videoplaybackmode    = 1
    redirectclipboard    = 1
    redirectprinters     = 1
    devicestoredirect    = "*"
    redirectcomports     = 1
    redirectsmartcards   = 1
    usbdevicestoredirect = "*"
    enablecredsspsupport = 1
    use_multimon         = 1
    custom_properties = {
      audiocapturemode  = "i:1"
      camerastoredirect = "s:*"
      enablerdsaadauth  = "i:1"
    }
  }

  # Single weekday autoscale schedule (call-centre / knowledge-worker peak hours,
  # Europe business day). Tune per persona in the production design.
  scaling_plan_schedule = [
    {
      name                                 = "weekday"
      days_of_week                         = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
      ramp_up_start_time                   = "07:00"
      ramp_up_load_balancing_algorithm     = "BreadthFirst"
      ramp_up_minimum_hosts_percent        = 20
      ramp_up_capacity_threshold_percent   = 60
      peak_start_time                      = "09:00"
      peak_load_balancing_algorithm        = "BreadthFirst"
      ramp_down_start_time                 = "18:00"
      ramp_down_load_balancing_algorithm   = "DepthFirst"
      ramp_down_minimum_hosts_percent      = 10
      ramp_down_capacity_threshold_percent = 90
      ramp_down_force_logoff_users         = false
      ramp_down_wait_time_minutes          = 30
      ramp_down_notification_message       = "You will be logged off in 30 minutes. Please save your work."
      ramp_down_stop_hosts_when            = "ZeroSessions"
      off_peak_start_time                  = "20:00"
      off_peak_load_balancing_algorithm    = "DepthFirst"
    }
  ]

  # Key Vault administrator role assignments: always the deploying principal (so
  # the break-glass secret can be written), plus the named admin when supplied.
  key_vault_role_assignments = merge(
    {
      deployer = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = data.azurerm_client_config.current.object_id
      }
    },
    var.adminObjectId == "" ? {} : {
      admin = {
        role_definition_id_or_name = "Key Vault Administrator"
        principal_id               = var.adminObjectId
        principal_type             = "Group"
      }
    }
  )

  # Desktop Virtualization User on the application group for the named admin.
  application_group_role_assignments = var.adminObjectId == "" ? {} : {
    desktopUsers = {
      role_definition_id_or_name = "Desktop Virtualization User"
      principal_id               = var.adminObjectId
      principal_type             = "Group"
    }
  }
}
