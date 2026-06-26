// PAPER-SCALE REFERENCE ONLY — do NOT deploy in the MicroHack classroom.
// These values illustrate the full Contoso production sizing from the HLD (Challenge 02).
// A real rollout deploys per-persona host pools in waves (see scripts/ and the migration
// cutover skill), not a single 1,000-user host pool. sessionHostCount is capped at 50 here
// purely as a token of scale for static validation.
using './main.bicep'

param location = 'swedencentral'
param environment = 'prod'
param namePrefix = 'avd'
param sessionHostCount = 40
param sessionHostSize = 'Standard_D8as_v5'
param hostPoolType = 'Pooled'
param maxSessionLimit = 12
param profileStorageQuotaGb = 1024
param deployScalingPlan = true

param adminObjectId = ''

param tags = {
  owner: 'avd-platform-team'
}

param sessionHostAdminUsername = 'avdadmin'
param sessionHostAdminPassword = readEnvironmentVariable('AVD_LOCAL_ADMIN_PASSWORD', '')
param deploySessionHosts = true

param vnetAddressSpace = '10.20.0.0/16'
param sessionHostSubnetPrefix = '10.20.0.0/22'
param privateEndpointSubnetPrefix = '10.20.4.0/24'

param logAnalyticsRetentionDays = 90
param budgetAmount = 5000
param budgetContactEmails = []
