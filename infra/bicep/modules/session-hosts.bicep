metadata name = 'AVD session hosts'
metadata description = '''
Deploys N Entra-joined Azure Virtual Desktop session hosts and registers them with an
existing host pool via the AVD (DSC) Host Pool Registration extension. A thin, lab-scale
wrapper around the AVM `avm/res/compute/virtual-machine` module: Trusted Launch, a
system-assigned identity (required for Entra join), Premium OS disk, and a built-in
per-VM daily auto-shutdown schedule for cost control.
'''

// ============== //
//  Parameters    //
// ============== //

@description('Required. Azure region for the session hosts.')
param location string

@minLength(2)
@maxLength(10)
@description('Required. Workload segment used in resource names (e.g. avd).')
param namePrefix string

@description('Required. Environment short name (lab|prod) used in resource names.')
param environment string

@description('Required. Region short code used in resource names (e.g. sec).')
param regionShort string

@minValue(1)
@maxValue(50)
@description('Required. Number of session hosts to deploy.')
param sessionHostCount int

@description('Required. Session host VM size (SKU).')
param sessionHostSize string

@description('Required. Resource ID of the subnet to attach the session host NICs to.')
param subnetResourceId string

@description('Required. Name of the AVD host pool to register the session hosts with (must be in this resource group).')
param hostPoolName string

@secure()
@description('Required. Host pool registration token used by the AVD agent to join the pool.')
param hostPoolRegistrationToken string

@description('Required. Local administrator user name for the session hosts.')
param adminUsername string

@secure()
@description('Required. Local administrator password for the session hosts. Supply at deploy time; never commit.')
param adminPassword string

@description('Optional. Marketplace image for the session hosts. Defaults to Windows 11 24H2 multi-session + Microsoft 365 Apps.')
param imageReference object = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'office-365'
  sku: 'win11-24h2-avd-m365'
  version: 'latest'
}

@description('Optional. URL of the AVD agent DSC configuration package used to register session hosts.')
#disable-next-line no-hardcoded-env-urls
param avdAgentPackageUrl string = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_1.0.02990.697.zip'

@allowed([
  -1
  1
  2
  3
])
@description('Optional. Availability zone for the session hosts. -1 deploys with no zone (lab default).')
param availabilityZone int = -1

@minValue(64)
@maxValue(2048)
@description('Optional. OS disk size in GB.')
param osDiskSizeGb int = 128

@description('Optional. Daily auto-shutdown time (24h HHmm, schedule time zone) for cost control.')
param autoShutdownTime string = '1900'

@description('Optional. Time zone ID for the auto-shutdown schedule.')
param autoShutdownTimeZone string = 'W. Europe Standard Time'

@description('Optional. Tags applied to every session host resource.')
param tags object = {}

// ============== //
//  Variables     //
// ============== //

// Windows computer name must be <= 15 chars; keep the base at 13 so a 2-digit index fits.
var hostBaseName = take(toLower('vm${replace(namePrefix, '-', '')}${environment}${regionShort}'), 13)

// ============== //
//  Session hosts //
// ============== //

module sessionHost 'br/public:avm/res/compute/virtual-machine:0.22.2' = [
  for index in range(0, sessionHostCount): {
    name: 'deploy-sh-${namePrefix}-${environment}-${regionShort}-${index}'
    params: {
      name: '${hostBaseName}${padLeft(string(index), 2, '0')}'
      location: location
      vmSize: sessionHostSize
      osType: 'Windows'
      availabilityZone: availabilityZone
      adminUsername: adminUsername
      adminPassword: adminPassword
      encryptionAtHost: false
      securityType: 'TrustedLaunch'
      secureBootEnabled: true
      vTpmEnabled: true
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
        deleteOption: 'Delete'
        diskSizeGB: osDiskSizeGb
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      nicConfigurations: [
        {
          name: 'nic-${hostBaseName}${padLeft(string(index), 2, '0')}'
          deleteOption: 'Delete'
          ipConfigurations: [
            {
              name: 'ipconfig01'
              subnetResourceId: subnetResourceId
            }
          ]
        }
      ]
      managedIdentities: {
        systemAssigned: true
      }
      extensionAadJoinConfig: {
        enabled: true
        typeHandlerVersion: '1.0'
        autoUpgradeMinorVersion: true
      }
      extensionHostPoolRegistration: {
        enabled: true
        modulesUrl: avdAgentPackageUrl
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        hostPoolName: hostPoolName
        registrationInfoToken: hostPoolRegistrationToken
      }
      autoShutdownConfig: {
        status: 'Enabled'
        timeZone: autoShutdownTimeZone
        dailyRecurrenceTime: autoShutdownTime
        notificationSettings: {
          status: 'Disabled'
        }
      }
      bootDiagnostics: true
      enableTelemetry: false
      tags: tags
    }
  }
]

// ============== //
//  Outputs       //
// ============== //

@description('The resource names of the deployed session hosts.')
output sessionHostNames array = [for index in range(0, sessionHostCount): sessionHost[index].outputs.name]

@description('The resource IDs of the deployed session hosts.')
output sessionHostResourceIds array = [for index in range(0, sessionHostCount): sessionHost[index].outputs.resourceId]
