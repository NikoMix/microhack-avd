metadata name = 'Contoso AVD landing zone (Bicep / AVM)'
metadata description = '''
Azure Virtual Desktop landing zone for the Contoso MicroHack, built entirely from Azure
Verified Modules (AVM). Deploys (lab footprint by default) a resource group, Log Analytics,
networking (NSG + VNet + subnets), FSLogix profile storage on Azure Files Premium with Entra
Kerberos and a private endpoint, an AVD host pool + desktop application group + workspace,
Entra-joined session hosts, an optional autoscale plan, RBAC, and cost guardrails (consumption
budget + per-VM auto-shutdown). Implements the cross-track contract in infra/README.md.
'''

targetScope = 'subscription'

// ===================== //
//  Parameters (contract) //
// ===================== //

@description('Optional. Azure region for the AVD landing zone. Defaults to Sweden Central.')
param location string = 'swedencentral'

@allowed([
  'lab'
  'prod'
])
@description('Optional. Deployment environment. Drives naming and sizing. Defaults to lab.')
param environment string = 'lab'

@minLength(2)
@maxLength(10)
@description('Optional. Workload segment used in every resource name. Defaults to avd.')
param namePrefix string = 'avd'

@minValue(0)
@maxValue(50)
@description('Optional. Number of session hosts to deploy. Keep tiny (1-2) in labs.')
param sessionHostCount int = 1

@description('Optional. Session host VM size (SKU).')
param sessionHostSize string = 'Standard_D4as_v5'

@allowed([
  'Pooled'
  'Personal'
])
@description('Optional. Host pool type. Defaults to Pooled multi-session.')
param hostPoolType string = 'Pooled'

@minValue(1)
@maxValue(999)
@description('Optional. Max sessions per pooled host. Ignored for Personal pools.')
param maxSessionLimit int = 8

@minValue(100)
@maxValue(102400)
@description('Optional. FSLogix Azure Files Premium share quota in GB.')
param profileStorageQuotaGb int = 128

@description('Optional. Deploy an autoscale (scaling) plan for the host pool. Pooled only.')
param deployScalingPlan bool = true

@description('Optional. Entra object ID (user or group) granted access to the desktop application group and the FSLogix share. Leave empty to skip the role assignments.')
param adminObjectId string = ''

@description('Optional. Extra tags merged with the required MicroHack tags and applied to every resource.')
param tags object = {
  owner: 'avd-platform-team'
}

// ============================================ //
//  Parameters (track-aligned extensions)       //
//  Identical variables exist on the Terraform  //
//  track; all optional with safe lab defaults. //
// ============================================ //

@description('Optional. Local administrator user name for the session hosts.')
param sessionHostAdminUsername string = 'avdadmin'

@secure()
@description('Optional. Local administrator password for the session hosts. NEVER commit a real value - pass at deploy time (env var / Key Vault). Required when deploySessionHosts is true.')
param sessionHostAdminPassword string = ''

@description('Optional. Deploy the session host VMs. Set false for an infrastructure-only deployment (e.g. what-if without a password).')
param deploySessionHosts bool = true

@description('Optional. Address space for the AVD virtual network.')
param vnetAddressSpace string = '10.10.0.0/16'

@description('Optional. Address prefix for the session host subnet.')
param sessionHostSubnetPrefix string = '10.10.1.0/24'

@description('Optional. Address prefix for the private endpoint subnet.')
param privateEndpointSubnetPrefix string = '10.10.2.0/24'

@minValue(7)
@maxValue(730)
@description('Optional. Log Analytics data retention in days.')
param logAnalyticsRetentionDays int = 30

@minValue(1)
@description('Optional. Monthly consumption budget amount (billing currency) for the lab.')
param budgetAmount int = 200

@description('Optional. Email addresses notified at each budget threshold.')
param budgetContactEmails array = []

// ============== //
//  Variables     //
// ============== //

var regionShortCodes = {
  swedencentral: 'sec'
  westeurope: 'weu'
  northeurope: 'neu'
  uksouth: 'uks'
  eastus: 'eus'
  eastus2: 'eus2'
  westus2: 'wus2'
  centralus: 'cus'
  australiaeast: 'aue'
  southeastasia: 'sea'
}
var regionShort = regionShortCodes[?toLower(location)] ?? substring(toLower(location), 0, 3)

var naming = '${namePrefix}-${environment}-${regionShort}'
var resourceGroupName = 'rg-${naming}'
var logAnalyticsName = 'law-${naming}'
var nsgName = 'nsg-${naming}'
var vnetName = 'vnet-${naming}'
var hostPoolName = 'hp-${naming}'
var applicationGroupName = 'ag-${naming}-desktop'
var workspaceName = 'ws-${naming}'
var scalingPlanName = 'sp-${naming}'
var budgetName = 'budget-${naming}'
var sessionHostSubnetName = 'snet-${naming}-hosts'
var privateEndpointSubnetName = 'snet-${naming}-pe'
var profileShareName = 'profiles'
var storageAccountName = take(toLower('st${replace(namePrefix, '-', '')}${environment}${regionShort}${uniqueString(subscription().id, resourceGroupName)}'), 24)

// az.environment() is used (not environment()) because the contract parameter is named `environment`.
var filePrivateDnsZoneName = 'privatelink.file.${az.environment().suffixes.storage}'

// Required MicroHack tags are authoritative; `owner` falls back when the caller omits it.
var ownerFallback = contains(tags, 'owner') ? {} : { owner: 'avd-platform-team' }
var requiredTags = {
  workload: 'avd-microhack'
  env: environment
  costCenter: 'training'
  autoDelete: 'true'
}
var allTags = union(tags, ownerFallback, requiredTags)

// Built-in role definition IDs (bare GUIDs resolve regardless of the AVM role-name map).
var roleDesktopVirtualizationUser = '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
var roleStorageFileDataSmbShareContributor = '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'

// AVD load balancing + assignment derived from the host pool type.
var loadBalancerType = hostPoolType == 'Pooled' ? 'BreadthFirst' : 'Persistent'
var effectiveMaxSessionLimit = hostPoolType == 'Pooled' ? maxSessionLimit : 1
var deployScaling = deployScalingPlan && hostPoolType == 'Pooled'
var deployHosts = deploySessionHosts && sessionHostCount > 0

// Single Log Analytics diagnostic target reused across modules.
var lawDiagnostics = [
  {
    name: 'send-to-law'
    workspaceResourceId: monitoring.outputs.resourceId
  }
]

// Conditional role assignments (only when an admin object ID is supplied).
var appGroupRoleAssignments = empty(adminObjectId)
  ? null
  : [
      {
        roleDefinitionIdOrName: roleDesktopVirtualizationUser
        principalId: adminObjectId
        description: 'Desktop Virtualization User on the desktop application group.'
      }
    ]
var storageRoleAssignments = empty(adminObjectId)
  ? null
  : [
      {
        roleDefinitionIdOrName: roleStorageFileDataSmbShareContributor
        principalId: adminObjectId
        description: 'Storage File Data SMB Share Contributor on the FSLogix profile share.'
      }
    ]

// Pooled host pool weekday autoscale schedule.
var pooledScalingSchedules = [
  {
    name: 'weekdays'
    daysOfWeek: [
      'Monday'
      'Tuesday'
      'Wednesday'
      'Thursday'
      'Friday'
    ]
    rampUpStartTime: {
      hour: 7
      minute: 0
    }
    rampUpLoadBalancingAlgorithm: 'BreadthFirst'
    rampUpMinimumHostsPct: 20
    rampUpCapacityThresholdPct: 60
    peakStartTime: {
      hour: 9
      minute: 0
    }
    peakLoadBalancingAlgorithm: 'BreadthFirst'
    rampDownStartTime: {
      hour: 18
      minute: 0
    }
    rampDownLoadBalancingAlgorithm: 'DepthFirst'
    rampDownMinimumHostsPct: 10
    rampDownCapacityThresholdPct: 90
    rampDownForceLogoffUsers: false
    rampDownWaitTimeMinutes: 30
    rampDownNotificationMessage: 'You will be logged off soon. Please save your work.'
    rampDownStopHostsWhen: 'ZeroSessions'
    offPeakStartTime: {
      hour: 20
      minute: 0
    }
    offPeakLoadBalancingAlgorithm: 'DepthFirst'
  }
]

// ================= //
//  Resource group   //
// ================= //

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'deploy-rg-${naming}'
  params: {
    name: resourceGroupName
    location: location
    tags: allTags
    enableTelemetry: false
  }
}

// ================= //
//  Cost guardrail   //
// ================= //

module budget 'br/public:avm/res/consumption/budget:0.3.8' = {
  name: 'deploy-budget-${naming}'
  params: {
    name: budgetName
    amount: budgetAmount
    category: 'Cost'
    resetPeriod: 'Monthly'
    thresholdType: 'Actual'
    thresholds: [
      50
      75
      90
      100
    ]
    contactEmails: budgetContactEmails
    contactRoles: [
      'Owner'
    ]
    resourceGroupFilter: [
      resourceGroupName
    ]
    location: location
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

// ================= //
//  Monitoring       //
// ================= //

module monitoring 'br/public:avm/res/operational-insights/workspace:0.15.1' = {
  name: 'deploy-law-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: logAnalyticsName
    location: location
    skuName: 'PerGB2018'
    dataRetention: logAnalyticsRetentionDays
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

// ================= //
//  Networking       //
// ================= //

module nsg 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: 'deploy-nsg-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: nsgName
    location: location
    // AVD session hosts use the reverse-connect transport (outbound 443 only); no inbound
    // rules are required. The default NSG rules deny inbound Internet traffic.
    securityRules: []
    diagnosticSettings: lawDiagnostics
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

module vnet 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: 'deploy-vnet-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      vnetAddressSpace
    ]
    subnets: [
      {
        name: sessionHostSubnetName
        addressPrefix: sessionHostSubnetPrefix
        networkSecurityGroupResourceId: nsg.outputs.resourceId
      }
      {
        name: privateEndpointSubnetName
        addressPrefix: privateEndpointSubnetPrefix
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
    diagnosticSettings: lawDiagnostics
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

module fileDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: 'deploy-pdnsz-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: filePrivateDnsZoneName
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnet.outputs.resourceId
        registrationEnabled: false
      }
    ]
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

// ================= //
//  FSLogix storage  //
// ================= //

module storage 'br/public:avm/res/storage/storage-account:0.32.1' = {
  name: 'deploy-st-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: storageAccountName
    location: location
    kind: 'FileStorage'
    skuName: 'Premium_LRS'
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    azureFilesIdentityBasedAuthentication: {
      directoryServiceOptions: 'AADKERB'
      defaultSharePermission: 'StorageFileDataSmbShareContributor'
    }
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
    fileServices: {
      diagnosticSettings: lawDiagnostics
      shares: [
        {
          name: profileShareName
          accessTier: 'Premium'
          enabledProtocols: 'SMB'
          shareQuota: profileStorageQuotaGb
        }
      ]
    }
    privateEndpoints: [
      {
        service: 'file'
        subnetResourceId: vnet.outputs.subnetResourceIds[1]
        privateDnsZoneGroup: {
          privateDnsZoneGroupConfigs: [
            {
              privateDnsZoneResourceId: fileDnsZone.outputs.resourceId
            }
          ]
        }
        tags: allTags
      }
    ]
    diagnosticSettings: lawDiagnostics
    roleAssignments: storageRoleAssignments
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

// ================= //
//  AVD control plane //
// ================= //

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = {
  name: 'deploy-hp-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: hostPoolName
    location: location
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: effectiveMaxSessionLimit
    personalDesktopAssignmentType: hostPoolType == 'Personal' ? 'Automatic' : null
    startVMOnConnect: true
    managementType: 'Standard'
    tokenValidityLength: 'PT8H'
    diagnosticSettings: lawDiagnostics
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

module applicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = {
  name: 'deploy-ag-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: applicationGroupName
    location: location
    applicationGroupType: 'Desktop'
    hostpoolName: hostPoolName
    friendlyName: 'Contoso AVD Desktop'
    diagnosticSettings: lawDiagnostics
    roleAssignments: appGroupRoleAssignments
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
    hostPool
  ]
}

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.2' = {
  name: 'deploy-ws-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: workspaceName
    location: location
    friendlyName: 'Contoso AVD'
    applicationGroupReferences: [
      applicationGroup.outputs.resourceId
    ]
    diagnosticSettings: lawDiagnostics
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

module scalingPlan 'br/public:avm/res/desktop-virtualization/scaling-plan:0.5.0' = if (deployScaling) {
  name: 'deploy-sp-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    name: scalingPlanName
    location: location
    hostPoolType: 'Pooled'
    timeZone: 'W. Europe Standard Time'
    schedules: pooledScalingSchedules
    hostPoolReferences: [
      {
        hostPoolResourceId: hostPool.outputs.resourceId
        scalingPlanEnabled: true
      }
    ]
    diagnosticSettings: lawDiagnostics
    tags: allTags
    enableTelemetry: false
  }
  dependsOn: [
    rg
  ]
}

// ================= //
//  Session hosts    //
// ================= //

module sessionHosts 'modules/session-hosts.bicep' = if (deployHosts) {
  name: 'deploy-sh-${naming}'
  scope: resourceGroup(resourceGroupName)
  params: {
    location: location
    namePrefix: namePrefix
    environment: environment
    regionShort: regionShort
    sessionHostCount: max(sessionHostCount, 1)
    sessionHostSize: sessionHostSize
    subnetResourceId: vnet.outputs.subnetResourceIds[0]
    hostPoolName: hostPoolName
    hostPoolRegistrationToken: hostPool.outputs.registrationToken!
    adminUsername: sessionHostAdminUsername
    adminPassword: sessionHostAdminPassword
    tags: allTags
  }
  dependsOn: [
    rg
    storage
  ]
}

// ============== //
//  Outputs       //
// ============== //

@description('Name of the resource group that contains the AVD landing zone.')
output resourceGroupName string = resourceGroupName

@description('Name of the AVD host pool.')
output hostPoolName string = hostPool.outputs.name

@description('Name of the AVD workspace.')
output workspaceName string = workspace.outputs.name

@description('Name of the AVD desktop application group.')
output applicationGroupName string = applicationGroup.outputs.name

@description('Name of the FSLogix storage account.')
output storageAccountName string = storage.outputs.name

@description('Name of the FSLogix profile file share.')
output profileShareName string = profileShareName

@description('Resource ID of the Log Analytics workspace used by AVD Insights / KQL.')
output logAnalyticsWorkspaceId string = monitoring.outputs.resourceId

@description('Names of the deployed session hosts (empty when none are deployed).')
output sessionHostNames array = deployHosts ? sessionHosts!.outputs.sessionHostNames : []
