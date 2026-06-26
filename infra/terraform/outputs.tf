###############################################################################
# outputs.tf — cross-track contract outputs (identical names on the Bicep track)
#
# The first block is the exact contract from infra/README.md. The second block
# adds operational extras the deploy/validation challenges consume.
###############################################################################

#==============================================================================
# Contract outputs (must match the Bicep track exactly)
#==============================================================================

output "resourceGroupName" {
  description = "Name of the resource group containing the AVD landing zone."
  value       = module.rg.name
}

output "hostPoolName" {
  description = "Name of the AVD host pool."
  value       = local.names.host_pool
}

output "workspaceName" {
  description = "Name of the AVD workspace."
  value       = local.names.workspace
}

output "applicationGroupName" {
  description = "Name of the AVD desktop application group."
  value       = local.names.application_group
}

output "storageAccountName" {
  description = "Name of the FSLogix profile storage account."
  value       = module.storage.name
}

output "profileShareName" {
  description = "Name of the FSLogix profile file share."
  value       = local.names.profile_share
}

output "logAnalyticsWorkspaceId" {
  description = "Resource ID of the Log Analytics workspace collecting AVD diagnostics."
  value       = module.log_analytics.resource_id
}

#==============================================================================
# Operational extras (consumed by the deploy / validation challenges)
#==============================================================================

output "resourceGroupId" {
  description = "Resource ID of the AVD resource group."
  value       = module.rg.resource_id
}

output "hostPoolId" {
  description = "Resource ID of the AVD host pool."
  value       = module.hostpool.resource_id
}

output "hostPoolRegistrationToken" {
  description = "Host pool registration token used to join session hosts. Sensitive and short-lived."
  value       = module.hostpool.registrationinfo_token
  sensitive   = true
}

output "workspaceId" {
  description = "Resource ID of the AVD workspace."
  value       = module.workspace.resource_id
}

output "applicationGroupId" {
  description = "Resource ID of the AVD desktop application group."
  value       = module.application_group.resource_id
}

output "storageAccountId" {
  description = "Resource ID of the FSLogix profile storage account."
  value       = module.storage.resource_id
}

output "virtualNetworkId" {
  description = "Resource ID of the AVD virtual network."
  value       = module.vnet.resource_id
}

output "avdSubnetId" {
  description = "Resource ID of the session-host subnet."
  value       = module.vnet.subnets["avd"].resource_id
}

output "keyVaultName" {
  description = "Name of the Key Vault holding the break-glass local-admin secret."
  value       = module.key_vault.name
}

output "keyVaultUri" {
  description = "URI of the Key Vault holding the break-glass local-admin secret."
  value       = module.key_vault.uri
}

output "sessionHostNames" {
  description = "Computer names of the deployed session hosts."
  value       = [for vm in module.session_host : vm.name]
}

output "scalingPlanName" {
  description = "Name of the autoscale scaling plan, or null when not deployed."
  value       = local.deploy_scaling_plan ? local.names.scaling_plan : null
}
