###############################################################################
# variables.tf — input contract for the AVD landing zone (Terraform track)
#
# The first block reproduces the cross-track contract in infra/README.md exactly
# (same names, types, and lab defaults as the Bicep track) so the two tracks are
# interchangeable. The second block adds optional, fully-defaulted knobs — they
# never change the contract because the same *.tfvars works on both tracks.
###############################################################################

#==============================================================================
# Contract inputs (identical on the Bicep track)
#==============================================================================

variable "location" {
  type        = string
  default     = "swedencentral"
  description = "Azure region for the AVD landing zone. AVD metadata objects use a supported metadata region; session hosts colocate with users."
}

variable "environment" {
  type        = string
  default     = "lab"
  description = "Deployment environment. Drives naming and sizing. Use 'lab' for the classroom footprint and 'prod' for the production design."

  validation {
    condition     = contains(["lab", "prod"], var.environment)
    error_message = "environment must be either 'lab' or 'prod'."
  }
}

variable "namePrefix" {
  type        = string
  default     = "avd"
  description = "Workload segment used in every resource name (<type>-<namePrefix>-<environment>-<regionShort>)."

  validation {
    condition     = can(regex("^[a-z0-9]{2,8}$", var.namePrefix))
    error_message = "namePrefix must be 2-8 lowercase alphanumeric characters (keeps the 24-char storage account name within limits)."
  }
}

variable "sessionHostCount" {
  type        = number
  default     = 1
  description = "Number of session hosts to deploy. Keep this tiny (1-2) in the classroom; the full Contoso fleet stays a paper design."

  validation {
    condition     = var.sessionHostCount >= 0 && var.sessionHostCount <= 10 && floor(var.sessionHostCount) == var.sessionHostCount
    error_message = "sessionHostCount must be a whole number between 0 and 10 (classroom guardrail)."
  }
}

variable "sessionHostSize" {
  type        = string
  default     = "Standard_D4as_v5"
  description = "Session host VM SKU. D-series v5 is the default; downshift in lab.tfvars to control cost."
}

variable "hostPoolType" {
  type        = string
  default     = "Pooled"
  description = "AVD host pool type. 'Pooled' = multi-session (knowledge/call-centre); 'Personal' = persistent (power users/developers)."

  validation {
    condition     = contains(["Pooled", "Personal"], var.hostPoolType)
    error_message = "hostPoolType must be 'Pooled' or 'Personal'."
  }
}

variable "maxSessionLimit" {
  type        = number
  default     = 8
  description = "Maximum concurrent sessions per pooled host. Ignored for Personal pools."

  validation {
    condition     = var.maxSessionLimit >= 1 && var.maxSessionLimit <= 999
    error_message = "maxSessionLimit must be between 1 and 999."
  }
}

variable "profileStorageQuotaGb" {
  type        = number
  default     = 128
  description = "Provisioned size (GiB) of the FSLogix Azure Files Premium share. Premium FileStorage requires > 100 GiB."

  validation {
    condition     = var.profileStorageQuotaGb >= 100 && var.profileStorageQuotaGb <= 102400
    error_message = "profileStorageQuotaGb must be between 100 and 102400 (Premium FileStorage range)."
  }
}

variable "deployScalingPlan" {
  type        = bool
  default     = true
  description = "Attach an autoscale (scaling) plan to the host pool. Only applied to Pooled host pools."
}

variable "adminObjectId" {
  type        = string
  default     = ""
  description = "Entra (Azure AD) object ID of the user or group granted desktop access (Desktop Virtualization User) and Key Vault admin. Leave empty to skip those role assignments (e.g. for `terraform validate`)."

  validation {
    condition     = var.adminObjectId == "" || can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", var.adminObjectId))
    error_message = "adminObjectId must be empty or a valid GUID."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Extra tags merged onto every resource, on top of the mandatory workload/env/owner/costCenter/autoDelete tags."
}

#==============================================================================
# Optional inputs (defaulted; keep both tracks interchangeable)
#==============================================================================

variable "owner" {
  type        = string
  default     = "avd-platform-team"
  description = "Value for the mandatory 'owner' tag."
}

variable "localAdminUsername" {
  type        = string
  default     = "avdadmin"
  description = "Break-glass local administrator username for the session hosts. Hosts are Entra-joined; this account is for emergency access only and its password is stored in Key Vault."

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,19}$", var.localAdminUsername)) && !contains(["admin", "administrator", "guest", "root"], lower(var.localAdminUsername))
    error_message = "localAdminUsername must be 2-20 chars, start with a letter, and not be a reserved name (admin/administrator/guest/root)."
  }
}

variable "enablePrivateEndpoints" {
  type        = bool
  default     = true
  description = "Deploy a private endpoint + private DNS zone for the FSLogix storage account and lock down public network access. Recommended (security baseline)."
}

variable "enableTelemetry" {
  type        = bool
  default     = false
  description = "Enable Azure Verified Module deployment telemetry (an anonymous module-usage ping; unrelated to AVD/diagnostic logging). Off by default for the lab."
}

variable "vnetAddressSpace" {
  type        = string
  default     = "10.20.0.0/22"
  description = "CIDR for the AVD virtual network."

  validation {
    condition     = can(cidrhost(var.vnetAddressSpace, 0))
    error_message = "vnetAddressSpace must be a valid CIDR block."
  }
}

variable "avdSubnetPrefix" {
  type        = string
  default     = "10.20.0.0/24"
  description = "CIDR for the session-host subnet."

  validation {
    condition     = can(cidrhost(var.avdSubnetPrefix, 0))
    error_message = "avdSubnetPrefix must be a valid CIDR block."
  }
}

variable "privateEndpointSubnetPrefix" {
  type        = string
  default     = "10.20.1.0/24"
  description = "CIDR for the private-endpoint subnet."

  validation {
    condition     = can(cidrhost(var.privateEndpointSubnetPrefix, 0))
    error_message = "privateEndpointSubnetPrefix must be a valid CIDR block."
  }
}

variable "profileStorageSku" {
  type        = string
  default     = "Premium_ZRS"
  description = "Storage account SKU for the FSLogix profile share. Premium FileStorage required; ZRS for resilience, LRS to trim lab cost."

  validation {
    condition     = contains(["Premium_ZRS", "Premium_LRS"], var.profileStorageSku)
    error_message = "profileStorageSku must be 'Premium_ZRS' or 'Premium_LRS' (FSLogix requires Premium FileStorage)."
  }
}

variable "osDiskStorageType" {
  type        = string
  default     = "Premium_LRS"
  description = "Managed-disk type for the session host OS disk. Downshift to StandardSSD_LRS in lab.tfvars for cost."

  validation {
    condition     = contains(["Premium_LRS", "Premium_ZRS", "StandardSSD_LRS", "StandardSSD_ZRS", "Standard_LRS"], var.osDiskStorageType)
    error_message = "osDiskStorageType must be a supported managed-disk type."
  }
}

variable "imagePublisher" {
  type        = string
  default     = "microsoftwindowsdesktop"
  description = "Marketplace image publisher for the session hosts."
}

variable "imageOffer" {
  type        = string
  default     = "windows-11"
  description = "Marketplace image offer for the session hosts."
}

variable "imageSku" {
  type        = string
  default     = "win11-24h2-avd"
  description = "Marketplace image SKU. The '-avd' multi-session SKUs are required for Pooled host pools."
}

variable "imageVersion" {
  type        = string
  default     = "latest"
  description = "Marketplace image version."
}

variable "availabilityZone" {
  type        = string
  default     = "1"
  description = "Availability zone for each session host (WAF: intentionally selected). Set to null for regions without zones."
}

variable "avdAgentDscUrl" {
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02990.697.zip"
  description = "URL of the AVD Agent DSC Configuration.zip used to register session hosts to the host pool. Microsoft rotates this artifact; confirm the current URL before applying (see README)."
}

variable "timeZone" {
  type        = string
  default     = "W. Europe Standard Time"
  description = "Windows time-zone name for the autoscale scaling plan schedule."
}

variable "logRetentionDays" {
  type        = number
  default     = 30
  description = "Retention (days) for the Log Analytics workspace."

  validation {
    condition     = var.logRetentionDays >= 30 && var.logRetentionDays <= 730
    error_message = "logRetentionDays must be between 30 and 730."
  }
}

#==============================================================================
# Cost-guardrail inputs
#==============================================================================

variable "budgetAmount" {
  type        = number
  default     = 200
  description = "Monthly budget (in the subscription's billing currency) for the resource group. Alerts fire at 80% actual and 100% forecast."

  validation {
    condition     = var.budgetAmount > 0
    error_message = "budgetAmount must be greater than 0."
  }
}

variable "budgetStartDate" {
  type        = string
  default     = "2025-01-01T00:00:00Z"
  description = "Budget start date (RFC3339). Must be the first day of a month at 00:00:00Z."

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-01T00:00:00Z$", var.budgetStartDate))
    error_message = "budgetStartDate must be the first of a month in the form YYYY-MM-01T00:00:00Z."
  }
}

variable "budgetContactEmails" {
  type        = list(string)
  default     = []
  description = "Email addresses notified on budget thresholds. Owners on the RG are always notified via contact roles even when this is empty."
}

variable "autoShutdownTime" {
  type        = string
  default     = "1900"
  description = "Daily auto-shutdown time for session hosts in 24h HHmm format (cost guardrail)."

  validation {
    condition     = can(regex("^([01][0-9]|2[0-3])[0-5][0-9]$", var.autoShutdownTime))
    error_message = "autoShutdownTime must be a 24-hour HHmm value, e.g. 1900."
  }
}

variable "autoShutdownTimeZone" {
  type        = string
  default     = "W. Europe Standard Time"
  description = "Windows time-zone name for the session host auto-shutdown schedule."
}

variable "enableAutoShutdown" {
  type        = bool
  default     = true
  description = "Create a daily auto-shutdown schedule for each session host. Strongly recommended in the classroom."
}
