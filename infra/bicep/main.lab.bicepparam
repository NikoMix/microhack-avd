// Lab footprint (DEFAULT) — token scale: 1 small session host, guardrails on.
// Deploy:
//   $env:AVD_LOCAL_ADMIN_PASSWORD = '<strong-password>'   # never commit a real value
//   az deployment sub create --location swedencentral \
//     --template-file infra/bicep/main.bicep --parameters infra/bicep/main.lab.bicepparam
using './main.bicep'

param location = 'swedencentral'
param environment = 'lab'
param namePrefix = 'avd'
param sessionHostCount = 1
param sessionHostSize = 'Standard_D4as_v5'
param hostPoolType = 'Pooled'
param maxSessionLimit = 8
param profileStorageQuotaGb = 128
param deployScalingPlan = true

// Entra object ID (user or group) granted desktop + FSLogix share access. Empty = skip RBAC.
param adminObjectId = ''

param tags = {
  owner: 'avd-platform-team'
}

// Session host local admin. Password is read from an environment variable at build/deploy time
// so no secret is committed. Set AVD_LOCAL_ADMIN_PASSWORD before deploying session hosts.
param sessionHostAdminUsername = 'avdadmin'
param sessionHostAdminPassword = readEnvironmentVariable('AVD_LOCAL_ADMIN_PASSWORD', '')
param deploySessionHosts = true

param vnetAddressSpace = '10.10.0.0/16'
param sessionHostSubnetPrefix = '10.10.1.0/24'
param privateEndpointSubnetPrefix = '10.10.2.0/24'

param logAnalyticsRetentionDays = 30
param budgetAmount = 200
param budgetContactEmails = []
