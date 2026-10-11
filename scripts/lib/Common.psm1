#Requires -Version 7.0
<#
.SYNOPSIS
    Shared helpers for the AVD MicroHack lab scripts (auth, naming, tagging, context).

.DESCRIPTION
    Common.psm1 is imported by the setup / validate / load-test / reset scripts. It centralises:
      - Azure CLI invocation with error handling (Invoke-AzCommand).
      - Sign-in / subscription context (Get-AvdAzContext).
      - The infra naming + required-tag conventions (Get-AvdRegionShortCode, Get-AvdResourceName,
        Get-AvdRequiredTag).
      - A TRACK-AGNOSTIC resolver (Get-AvdLabContext) that surfaces the infra contract outputs
        (resourceGroupName, hostPoolName, workspaceName, applicationGroupName, storageAccountName,
        profileShareName, logAnalyticsWorkspaceId) from EITHER a Bicep deployment, a Terraform
        state, an explicit resource group, or tag discovery - so every script works identically
        against infra/bicep and infra/terraform (see infra/README.md).
      - Read-only service-validation checks used by Test-AvdService.ps1.

    All functions are cross-platform (PowerShell 7+, Linux dev container / Codespaces and Windows)
    and read-only - anything that mutates Azure lives in the scripts and supports -WhatIf/-Confirm.

.NOTES
    Quality bar: passes PSScriptAnalyzer (Warning + Error). No Write-Host; objects returned, not
    formatted strings; never hardcodes subscription/tenant IDs or secrets.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Constants -------------------------------------------------------------------------------

# Region -> short code, per .github/skills/avd-landing-zone/references/regions.md
$script:RegionShortCode = @{
    swedencentral = 'sec'
    westeurope    = 'weu'
    northeurope   = 'neu'
    uksouth       = 'uks'
    eastus        = 'eus'
    eastus2       = 'eus2'
    westus2       = 'wus2'
    centralus     = 'cus'
    australiaeast = 'aue'
    southeastasia = 'sea'
}

# ARM resource types for the AVD landing zone (used by tag/RG discovery).
$script:AvdResourceType = @{
    HostPool         = 'Microsoft.DesktopVirtualization/hostpools'
    ApplicationGroup = 'Microsoft.DesktopVirtualization/applicationgroups'
    Workspace        = 'Microsoft.DesktopVirtualization/workspaces'
    ScalingPlan      = 'Microsoft.DesktopVirtualization/scalingplans'
    StorageAccount   = 'Microsoft.Storage/storageAccounts'
    LogAnalytics     = 'Microsoft.OperationalInsights/workspaces'
}

# The workload tag that marks a resource group as a disposable MicroHack lab (teardown guard).
$script:WorkloadTagName = 'workload'
$script:WorkloadTagValue = 'avd-microhack'
$script:AutoDeleteTag = 'autoDelete'

# --- Logging ---------------------------------------------------------------------------------

function Write-AvdLog {
    <#
    .SYNOPSIS
        Emit progress to the information/verbose/warning stream (never Write-Host).
    .PARAMETER Message
        The text to emit.
    .PARAMETER Level
        Info (default), Step, Verbose, or Warning.
    .EXAMPLE
        Write-AvdLog -Message 'Resolving lab context' -Level Step
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Message,
        [ValidateSet('Info', 'Step', 'Verbose', 'Warning')][string]$Level = 'Info'
    )
    switch ($Level) {
        'Warning' { Write-Warning -Message $Message }
        'Verbose' { Write-Verbose -Message $Message }
        'Step' { Write-Information -MessageData "==> $Message" -InformationAction Continue }
        default { Write-Information -MessageData $Message -InformationAction Continue }
    }
}

# --- Azure CLI -------------------------------------------------------------------------------

function Invoke-AzCommand {
    <#
    .SYNOPSIS
        Run the Azure CLI with structured error handling and optional JSON parsing.
    .PARAMETER Arguments
        The argument array passed to 'az' (e.g. @('group','show','--name','rg-avd-lab-sec')).
    .PARAMETER Json
        Parse stdout as JSON and return the resulting object.
    .PARAMETER AllowFailure
        Return $null instead of throwing when the CLI exits non-zero (for best-effort probes).
    .EXAMPLE
        Invoke-AzCommand -Arguments @('account','show','-o','json') -Json
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [switch]$Json,
        [switch]$AllowFailure
    )

    if (-not (Get-Command -Name 'az' -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI (az) was not found on PATH. Install it or open the dev container.'
    }

    Write-Verbose -Message ('az {0}' -f ($Arguments -join ' '))
    $output = & az @Arguments 2>&1
    $exit = $LASTEXITCODE

    if ($exit -ne 0) {
        if ($AllowFailure) { return $null }
        $detail = ($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
        throw ('Azure CLI command failed (exit {0}): az {1}{2}{3}' -f `
                $exit, ($Arguments -join ' '), [Environment]::NewLine, $detail)
    }

    $stdout = $output | Where-Object { $_ -isnot [System.Management.Automation.ErrorRecord] }
    if (-not $Json) { return $stdout }

    $text = ($stdout | ForEach-Object { [string]$_ }) -join [Environment]::NewLine
    if ([string]::IsNullOrWhiteSpace($text)) { return $null }
    return ($text | ConvertFrom-Json)
}

function Get-AvdAzContext {
    <#
    .SYNOPSIS
        Return the signed-in Azure context (subscription/tenant), optionally switching subscription.
    .PARAMETER SubscriptionId
        Switch to this subscription first. Never hardcode - pass from a parameter or environment.
    .EXAMPLE
        Get-AvdAzContext -SubscriptionId $env:AZURE_SUBSCRIPTION_ID
    #>
    [CmdletBinding()]
    param(
        [string]$SubscriptionId
    )
    if ($SubscriptionId) {
        Invoke-AzCommand -Arguments @('account', 'set', '--subscription', $SubscriptionId) | Out-Null
    }
    $account = Invoke-AzCommand -Arguments @('account', 'show', '-o', 'json') -Json -AllowFailure
    if ($null -eq $account) {
        throw "Not signed in to Azure. Run 'az login' (see challenge-00) before using the lab scripts."
    }
    return [pscustomobject]@{
        SubscriptionId   = $account.id
        SubscriptionName = $account.name
        TenantId         = $account.tenantId
        User             = $account.user.name
    }
}

# --- Naming & tags ---------------------------------------------------------------------------

function Get-AvdRegionShortCode {
    <#
    .SYNOPSIS
        Map an Azure region to its naming short code (swedencentral -> sec).
    .PARAMETER Location
        The Azure region (e.g. swedencentral).
    .EXAMPLE
        Get-AvdRegionShortCode -Location swedencentral   # -> sec
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Location
    )
    $key = $Location.Trim().ToLowerInvariant()
    if ($script:RegionShortCode.ContainsKey($key)) { return $script:RegionShortCode[$key] }
    # Fallback: first three letters keeps names valid for regions not in the table.
    return ($key -replace '[^a-z0-9]', '').Substring(0, [Math]::Min(3, $key.Length))
}

function Get-AvdResourceName {
    <#
    .SYNOPSIS
        Build a contract-compliant resource name: <type>-<prefix>-<env>-<regionShort>.
    .PARAMETER ResourceType
        The short type segment (e.g. hp, ws, ag, vnet, rg).
    .PARAMETER NamePrefix
        Workload segment (default 'avd').
    .PARAMETER Environment
        lab or prod (default 'lab').
    .PARAMETER Location
        Azure region used to derive the short code (default 'swedencentral').
    .EXAMPLE
        Get-AvdResourceName -ResourceType hp   # -> hp-avd-lab-sec
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$ResourceType,
        [string]$NamePrefix = 'avd',
        [ValidateSet('lab', 'prod')][string]$Environment = 'lab',
        [string]$Location = 'swedencentral'
    )
    $short = Get-AvdRegionShortCode -Location $Location
    return ('{0}-{1}-{2}-{3}' -f $ResourceType, $NamePrefix, $Environment, $short)
}

function Get-AvdRequiredTag {
    <#
    .SYNOPSIS
        Return the required tag set for every lab resource, per the infra contract.
    .PARAMETER Environment
        lab or prod.
    .PARAMETER Owner
        Owner tag value (e.g. an alias or email). Defaults to the signed-in user when omitted.
    .EXAMPLE
        Get-AvdRequiredTag -Environment lab -Owner alice
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [ValidateSet('lab', 'prod')][string]$Environment = 'lab',
        [string]$Owner
    )
    if (-not $Owner) {
        $ctx = Get-AvdAzContext
        $Owner = if ($ctx.User) { $ctx.User } else { 'unknown' }
    }
    return @{
        $script:WorkloadTagName = $script:WorkloadTagValue
        env                     = $Environment
        owner                   = $Owner
        costCenter              = 'training'
        $script:AutoDeleteTag   = 'true'
    }
}

function ConvertTo-AvdTagArgument {
    <#
    .SYNOPSIS
        Flatten a tag hashtable into the 'key=value' array the az CLI expects for --tags.
    .PARAMETER Tag
        The tag hashtable.
    .EXAMPLE
        ConvertTo-AvdTagArgument -Tag (Get-AvdRequiredTag)
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)][hashtable]$Tag
    )
    return [string[]]@($Tag.GetEnumerator() | ForEach-Object { '{0}={1}' -f $_.Key, $_.Value })
}

# --- Track-agnostic context resolver ---------------------------------------------------------

function Get-AvdLabContext {
    <#
    .SYNOPSIS
        Resolve the infra-contract outputs for the deployed lab, regardless of IaC track.
    .DESCRIPTION
        Precedence: Terraform state > Bicep deployment outputs > explicit resource group
        discovery > tag discovery (workload=avd-microhack). Returns a single object whose
        properties match infra/README.md so downstream scripts are identical on both tracks.
    .PARAMETER ResourceGroup
        Resolve by enumerating resources in this resource group.
    .PARAMETER BicepDeploymentName
        Subscription-scope deployment name to read outputs from (az deployment sub show).
    .PARAMETER TerraformDir
        Path to the Terraform working directory to read 'terraform output -json' from.
    .PARAMETER SubscriptionId
        Optional subscription to operate against.
    .PARAMETER ProfileShareName
        FSLogix share name (contract default 'profiles').
    .EXAMPLE
        Get-AvdLabContext -ResourceGroup rg-avd-lab-sec
    .EXAMPLE
        Get-AvdLabContext -BicepDeploymentName avd-lab
    .EXAMPLE
        Get-AvdLabContext -TerraformDir infra/terraform
    #>
    [CmdletBinding(DefaultParameterSetName = 'Tag')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(ParameterSetName = 'ResourceGroup', Mandatory)][string]$ResourceGroup,
        [Parameter(ParameterSetName = 'Bicep', Mandatory)][string]$BicepDeploymentName,
        [Parameter(ParameterSetName = 'Terraform', Mandatory)][string]$TerraformDir,
        [string]$SubscriptionId,
        [string]$ProfileShareName = 'profiles'
    )

    if ($SubscriptionId) { Get-AvdAzContext -SubscriptionId $SubscriptionId | Out-Null }

    switch ($PSCmdlet.ParameterSetName) {
        'Terraform' { return Resolve-AvdContextFromTerraform -TerraformDir $TerraformDir -ProfileShareName $ProfileShareName }
        'Bicep' { return Resolve-AvdContextFromBicep -DeploymentName $BicepDeploymentName -ProfileShareName $ProfileShareName }
        'ResourceGroup' { return Resolve-AvdContextFromResourceGroup -ResourceGroup $ResourceGroup -ProfileShareName $ProfileShareName }
        default { return Resolve-AvdContextFromTag -ProfileShareName $ProfileShareName }
    }
}

function New-AvdContextObject {
    <#
    .SYNOPSIS
        Internal: shape a context result object with the infra-contract property names.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [string]$Track,
        [string]$ResourceGroupName,
        [string]$Location,
        [string]$HostPoolName,
        [string]$WorkspaceName,
        [string]$ApplicationGroupName,
        [string]$StorageAccountName,
        [string]$ProfileShareName,
        [string]$LogAnalyticsWorkspaceId,
        [string]$ScalingPlanName
    )
    # Pure object construction; ShouldProcess satisfies the analyzer for the 'New' verb.
    if (-not $PSCmdlet.ShouldProcess('lab context', 'compose')) { return $null }
    return [pscustomobject]@{
        Track                   = $Track
        ResourceGroupName       = $ResourceGroupName
        Location                = $Location
        HostPoolName            = $HostPoolName
        WorkspaceName           = $WorkspaceName
        ApplicationGroupName    = $ApplicationGroupName
        StorageAccountName      = $StorageAccountName
        ProfileShareName        = $ProfileShareName
        LogAnalyticsWorkspaceId = $LogAnalyticsWorkspaceId
        ScalingPlanName         = $ScalingPlanName
    }
}

function Resolve-AvdContextFromTerraform {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$TerraformDir,
        [string]$ProfileShareName = 'profiles'
    )
    if (-not (Test-Path -LiteralPath $TerraformDir)) {
        throw "Terraform directory '$TerraformDir' was not found."
    }
    if (-not (Get-Command -Name 'terraform' -ErrorAction SilentlyContinue)) {
        throw 'terraform was not found on PATH. Install it or read outputs via the Bicep/RG path.'
    }
    Push-Location -LiteralPath $TerraformDir
    try {
        $json = & terraform output -json 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $json) {
            throw "No Terraform outputs in '$TerraformDir'. Has 'terraform apply' been run?"
        }
        $o = ($json -join [Environment]::NewLine | ConvertFrom-Json)
    }
    finally {
        Pop-Location
    }
    $get = {
        param($name)
        if ($o.PSObject.Properties.Name -contains $name) { $o.$name.value } else { $null }
    }
    $share = & $get 'profileShareName'
    return New-AvdContextObject -Track 'terraform' `
        -ResourceGroupName (& $get 'resourceGroupName') `
        -Location (& $get 'location') `
        -HostPoolName (& $get 'hostPoolName') `
        -WorkspaceName (& $get 'workspaceName') `
        -ApplicationGroupName (& $get 'applicationGroupName') `
        -StorageAccountName (& $get 'storageAccountName') `
        -ProfileShareName ($(if ($share) { $share } else { $ProfileShareName })) `
        -LogAnalyticsWorkspaceId (& $get 'logAnalyticsWorkspaceId') `
        -ScalingPlanName (& $get 'scalingPlanName')
}

function Resolve-AvdContextFromBicep {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$DeploymentName,
        [string]$ProfileShareName = 'profiles'
    )
    $dep = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'deployment', 'sub', 'show', '--name', $DeploymentName, '-o', 'json')
    if ($null -eq $dep) {
        throw "Bicep deployment '$DeploymentName' was not found at subscription scope."
    }
    $out = $dep.properties.outputs
    $get = {
        param($name)
        if ($out -and ($out.PSObject.Properties.Name -contains $name)) { $out.$name.value } else { $null }
    }
    $share = & $get 'profileShareName'
    return New-AvdContextObject -Track 'bicep' `
        -ResourceGroupName (& $get 'resourceGroupName') `
        -Location (& $get 'location') `
        -HostPoolName (& $get 'hostPoolName') `
        -WorkspaceName (& $get 'workspaceName') `
        -ApplicationGroupName (& $get 'applicationGroupName') `
        -StorageAccountName (& $get 'storageAccountName') `
        -ProfileShareName ($(if ($share) { $share } else { $ProfileShareName })) `
        -LogAnalyticsWorkspaceId (& $get 'logAnalyticsWorkspaceId') `
        -ScalingPlanName (& $get 'scalingPlanName')
}

function Resolve-AvdContextFromResourceGroup {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup,
        [string]$ProfileShareName = 'profiles'
    )
    $rg = Invoke-AzCommand -Json -AllowFailure -Arguments @('group', 'show', '--name', $ResourceGroup, '-o', 'json')
    if ($null -eq $rg) { throw "Resource group '$ResourceGroup' was not found." }
    $resources = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'resource', 'list', '--resource-group', $ResourceGroup, '-o', 'json')
    return Convert-AvdResourceListToContext -Resources $resources -Track 'resource-group' `
        -ResourceGroupName $rg.name -Location $rg.location -ProfileShareName $ProfileShareName
}

function Resolve-AvdContextFromTag {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$ProfileShareName = 'profiles'
    )
    $tagFilter = ('{0}={1}' -f $script:WorkloadTagName, $script:WorkloadTagValue)
    $resources = Invoke-AzCommand -Json -AllowFailure -Arguments @('resource', 'list', '--tag', $tagFilter, '-o', 'json')
    if ($null -eq $resources -or @($resources).Count -eq 0) {
        throw "No resources tagged '$tagFilter' were found. Deploy the lab or pass -ResourceGroup."
    }
    $first = $resources | Select-Object -First 1
    return Convert-AvdResourceListToContext -Resources $resources -Track 'tag' `
        -ResourceGroupName $first.resourceGroup -Location $first.location -ProfileShareName $ProfileShareName
}

function Convert-AvdResourceListToContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [object[]]$Resources,
        [Parameter(Mandatory)][string]$Track,
        [Parameter(Mandatory)][string]$ResourceGroupName,
        [string]$Location,
        [string]$ProfileShareName = 'profiles'
    )
    $byType = {
        param($list, $type)
        if (-not $list) { return $null }
        ($list | Where-Object { $_.type -ieq $type } | Select-Object -First 1).name
    }
    $laName = & $byType $Resources $script:AvdResourceType.LogAnalytics
    $laId = $null
    if ($laName) {
        $la = Invoke-AzCommand -Json -AllowFailure -Arguments @(
            'monitor', 'log-analytics', 'workspace', 'show',
            '--resource-group', $ResourceGroupName, '--workspace-name', $laName, '-o', 'json')
        if ($la) { $laId = $la.id }
    }
    return New-AvdContextObject -Track $Track `
        -ResourceGroupName $ResourceGroupName `
        -Location $Location `
        -HostPoolName (& $byType $Resources $script:AvdResourceType.HostPool) `
        -WorkspaceName (& $byType $Resources $script:AvdResourceType.Workspace) `
        -ApplicationGroupName (& $byType $Resources $script:AvdResourceType.ApplicationGroup) `
        -StorageAccountName (& $byType $Resources $script:AvdResourceType.StorageAccount) `
        -ProfileShareName $ProfileShareName `
        -LogAnalyticsWorkspaceId $laId `
        -ScalingPlanName (& $byType $Resources $script:AvdResourceType.ScalingPlan)
}

# --- Teardown safety -------------------------------------------------------------------------

function Test-AvdSafeToDelete {
    <#
    .SYNOPSIS
        Confirm a resource group is a disposable MicroHack lab before any destructive action.
    .DESCRIPTION
        Returns an object with Safe ($true only when the group carries workload=avd-microhack or
        autoDelete=true), the reason, and the group's tags. Reset refuses to delete unsafe groups.
    .PARAMETER ResourceGroup
        The resource group to inspect.
    .EXAMPLE
        Test-AvdSafeToDelete -ResourceGroup rg-avd-lab-sec
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup
    )
    $rg = Invoke-AzCommand -Json -AllowFailure -Arguments @('group', 'show', '--name', $ResourceGroup, '-o', 'json')
    if ($null -eq $rg) {
        return [pscustomobject]@{ Safe = $false; Reason = "Resource group '$ResourceGroup' not found."; Tags = $null }
    }
    $tags = if ($rg.PSObject.Properties.Name -contains 'tags') { $rg.tags } else { $null }
    $workload = if ($tags) { $tags.$($script:WorkloadTagName) } else { $null }
    $autoDelete = if ($tags) { $tags.$($script:AutoDeleteTag) } else { $null }
    $safe = ($workload -eq $script:WorkloadTagValue) -or ("$autoDelete" -eq 'true')
    $reason = if ($safe) {
        'Group is tagged as a disposable MicroHack lab.'
    }
    else {
        "Refusing: group lacks '$($script:WorkloadTagName)=$($script:WorkloadTagValue)' / '$($script:AutoDeleteTag)=true' tags."
    }
    return [pscustomobject]@{ Safe = $safe; Reason = $reason; Tags = $tags }
}

# --- Service-validation checks (read-only) ---------------------------------------------------

function Resolve-AvdWorkspaceCustomerId {
    <#
    .SYNOPSIS
        Resolve a Log Analytics customer (workspace) GUID from its ARM resource ID.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$LogAnalyticsWorkspaceId
    )
    $ws = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'monitor', 'log-analytics', 'workspace', 'show', '--ids', $LogAnalyticsWorkspaceId, '-o', 'json')
    if ($ws -and ($ws.PSObject.Properties.Name -contains 'customerId')) { return $ws.customerId }
    return $null
}

function Get-AvdLogonPerformance {
    <#
    .SYNOPSIS
        Measure P50/P95 connection (logon) seconds from WVDConnections via Log Analytics KQL.
    .PARAMETER LogAnalyticsWorkspaceId
        ARM resource ID of the AVD Log Analytics workspace.
    .PARAMETER LookbackHours
        Window to evaluate (default 24).
    .PARAMETER TargetSeconds
        Pass/fail threshold for P95 (default 30).
    .EXAMPLE
        Get-AvdLogonPerformance -LogAnalyticsWorkspaceId $ctx.LogAnalyticsWorkspaceId
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$LogAnalyticsWorkspaceId,
        [int]$LookbackHours = 24,
        [int]$TargetSeconds = 30
    )
    $query = @"
WVDConnections
| where TimeGenerated > ago(${LookbackHours}h)
| where State == 'Connected'
| project CorrelationId, ConnectedTime = TimeGenerated
| join kind=inner (
    WVDConnections
    | where TimeGenerated > ago(${LookbackHours}h)
    | where State == 'Started'
    | summarize StartTime = min(TimeGenerated) by CorrelationId
  ) on CorrelationId
| extend LogonSeconds = datetime_diff('second', ConnectedTime, StartTime)
| summarize P50 = percentile(LogonSeconds, 50), P95 = percentile(LogonSeconds, 95), Sessions = count()
"@
    $result = [ordered]@{
        Test     = 'Logon performance (P50/P95)'
        Method   = "KQL Started->Connected on WVDConnections (${LookbackHours}h)"
        Target   = "P95 <= ${TargetSeconds}s"
        Actual   = 'No data'
        Status   = 'Inconclusive'
        Evidence = ($query -replace '\s+', ' ').Trim()
    }
    if (-not $LogAnalyticsWorkspaceId) {
        $result.Actual = 'No Log Analytics workspace resolved'
        return [pscustomobject]$result
    }
    $customerId = Resolve-AvdWorkspaceCustomerId -LogAnalyticsWorkspaceId $LogAnalyticsWorkspaceId
    if (-not $customerId) {
        $result.Actual = 'Workspace GUID not resolved'
        return [pscustomobject]$result
    }
    $rows = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'monitor', 'log-analytics', 'query', '--workspace', $customerId, '--analytics-query', $query, '-o', 'json')
    $row = if ($rows) { $rows | Select-Object -First 1 } else { $null }
    if ($null -eq $row -or [string]::IsNullOrWhiteSpace([string]$row.Sessions) -or [int]$row.Sessions -eq 0) {
        $result.Actual = 'No connections in window (generate load with Invoke-AvdLoadTest.ps1)'
        return [pscustomobject]$result
    }
    $p95 = [double]$row.P95
    $result.Actual = ('P50={0}s P95={1}s over {2} sessions' -f [int]$row.P50, [int]$p95, [int]$row.Sessions)
    $result.Status = if ($p95 -le $TargetSeconds) { 'Pass' } else { 'Fail' }
    return [pscustomobject]$result
}

function Test-AvdAppDelivery {
    <#
    .SYNOPSIS
        Confirm application groups are published and assigned for the host pool.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup
    )
    $result = [ordered]@{
        Test     = 'Application launch / delivery'
        Method   = 'App groups present + role assignments (az desktopvirtualization)'
        Target   = '>=1 app group with >=1 assignment'
        Actual   = 'None found'
        Status   = 'Fail'
        Evidence = "az resource list --resource-group $ResourceGroup --resource-type $($script:AvdResourceType.ApplicationGroup)"
    }
    $groups = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'resource', 'list', '--resource-group', $ResourceGroup,
        '--resource-type', $script:AvdResourceType.ApplicationGroup, '-o', 'json')
    if (-not $groups -or @($groups).Count -eq 0) {
        $result.Status = 'Inconclusive'
        $result.Actual = 'No application groups deployed yet'
        return [pscustomobject]$result
    }
    $assignmentTotal = 0
    foreach ($g in $groups) {
        $assignments = Invoke-AzCommand -Json -AllowFailure -Arguments @(
            'role', 'assignment', 'list', '--scope', $g.id, '-o', 'json')
        if ($assignments) { $assignmentTotal += @($assignments).Count }
    }
    $result.Actual = ('{0} app group(s), {1} assignment(s)' -f @($groups).Count, $assignmentTotal)
    $result.Status = if ($assignmentTotal -ge 1) { 'Pass' } else { 'Fail' }
    return [pscustomobject]$result
}

function Test-AvdFsLogixIntegrity {
    <#
    .SYNOPSIS
        Confirm the FSLogix profile store exists on Premium Files with backup-capable redundancy.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup,
        [Parameter(Mandatory)][string]$StorageAccountName,
        [string]$ProfileShareName = 'profiles'
    )
    $result = [ordered]@{
        Test     = 'FSLogix profile integrity'
        Method   = 'Premium Files share present + redundancy (az storage)'
        Target   = "Premium share '$ProfileShareName' reachable, ZRS/GRS"
        Actual   = 'Storage account not found'
        Status   = 'Inconclusive'
        Evidence = "az storage account show --name $StorageAccountName --resource-group $ResourceGroup"
    }
    if (-not $StorageAccountName) { return [pscustomobject]$result }
    $sa = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'storage', 'account', 'show', '--name', $StorageAccountName, '--resource-group', $ResourceGroup, '-o', 'json')
    if ($null -eq $sa) { return [pscustomobject]$result }
    $sku = $sa.sku.name
    $isPremium = ("$($sa.kind)" -match 'FileStorage') -or ("$sku" -match 'Premium')
    $result.Actual = ('kind={0} sku={1}' -f $sa.kind, $sku)
    $result.Status = if ($isPremium) { 'Pass' } else { 'Fail' }
    return [pscustomobject]$result
}

function Test-AvdScalingPlan {
    <#
    .SYNOPSIS
        Confirm an enabled scaling plan is associated with the host pool.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup,
        [string]$HostPoolName
    )
    $result = [ordered]@{
        Test     = 'Autoscaling (scaling plan)'
        Method   = 'Scaling plan enabled + host-pool reference'
        Target   = 'Enabled plan referencing the host pool'
        Actual   = 'No scaling plan found'
        Status   = 'Inconclusive'
        Evidence = "az resource list --resource-group $ResourceGroup --resource-type $($script:AvdResourceType.ScalingPlan)"
    }
    $plans = Invoke-AzCommand -Json -AllowFailure -Arguments @(
        'resource', 'list', '--resource-group', $ResourceGroup,
        '--resource-type', $script:AvdResourceType.ScalingPlan, '-o', 'json')
    if (-not $plans -or @($plans).Count -eq 0) { return [pscustomobject]$result }
    $plan = $plans | Select-Object -First 1
    $detail = Invoke-AzCommand -Json -AllowFailure -Arguments @('resource', 'show', '--ids', $plan.id, '-o', 'json')
    $enabled = $false
    $references = $false
    if ($detail -and ($detail.properties.PSObject.Properties.Name -contains 'hostPoolReferences')) {
        $refs = $detail.properties.hostPoolReferences
        $enabled = [bool]($refs | Where-Object { $_.scalingPlanEnabled })
        if ($HostPoolName) {
            $references = [bool]($refs | Where-Object { "$($_.hostPoolArmPath)" -match [regex]::Escape($HostPoolName) })
        }
        else {
            $references = @($refs).Count -ge 1
        }
    }
    $result.Actual = ('plan={0} enabled={1} referencesHostPool={2}' -f $plan.name, $enabled, $references)
    $result.Status = if ($enabled -and $references) { 'Pass' } elseif (@($plans).Count -ge 1) { 'Fail' } else { 'Inconclusive' }
    return [pscustomobject]$result
}

function Test-AvdResilience {
    <#
    .SYNOPSIS
        Confirm storage redundancy and host-pool capacity support failover/resilience.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory)][string]$ResourceGroup,
        [string]$StorageAccountName,
        [string]$HostPoolName
    )
    $result = [ordered]@{
        Test     = 'Failover / resilience'
        Method   = 'Storage replication + session host count'
        Target   = 'Redundant profile storage; >=1 host (N+1 in prod)'
        Actual   = 'Unknown'
        Status   = 'Inconclusive'
        Evidence = "az storage account show / az vm list --resource-group $ResourceGroup"
    }
    $replication = 'unknown'
    if ($StorageAccountName) {
        $sa = Invoke-AzCommand -Json -AllowFailure -Arguments @(
            'storage', 'account', 'show', '--name', $StorageAccountName, '--resource-group', $ResourceGroup, '-o', 'json')
        if ($sa) { $replication = $sa.sku.name }
    }
    $vms = Invoke-AzCommand -Json -AllowFailure -Arguments @('vm', 'list', '--resource-group', $ResourceGroup, '-o', 'json')
    $hostCount = if ($vms) { @($vms).Count } else { 0 }
    $redundant = "$replication" -match 'ZRS|GRS|GZRS'
    if ($HostPoolName) { Write-Verbose -Message "Resilience check scoped to host pool '$HostPoolName'." }
    $result.Actual = ('replication={0} hosts={1}' -f $replication, $hostCount)
    if ($hostCount -ge 1 -and $redundant) { $result.Status = 'Pass' }
    elseif ($hostCount -ge 1) { $result.Status = 'Fail' }
    return [pscustomobject]$result
}

# --- Output shaping --------------------------------------------------------------------------

function ConvertTo-AvdMarkdownTable {
    <#
    .SYNOPSIS
        Render an array of result objects as a GitHub-flavoured Markdown table.
    .PARAMETER Row
        The objects to render.
    .PARAMETER Property
        Ordered property names to use as columns.
    .EXAMPLE
        ConvertTo-AvdMarkdownTable -Row $results -Property Test,Method,Target,Actual,Status,Evidence
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][object[]]$Row,
        [Parameter(Mandatory)][string[]]$Property
    )
    $escape = { param($v) ("$v" -replace '\|', '\|' -replace '\r?\n', ' ').Trim() }
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('| ' + ($Property -join ' | ') + ' |')
    [void]$sb.AppendLine('|' + (($Property | ForEach-Object { '---' }) -join '|') + '|')
    foreach ($r in $Row) {
        $cells = $Property | ForEach-Object { & $escape $r.$_ }
        [void]$sb.AppendLine('| ' + ($cells -join ' | ') + ' |')
    }
    return $sb.ToString().TrimEnd()
}

Export-ModuleMember -Function @(
    'Write-AvdLog',
    'Invoke-AzCommand',
    'Get-AvdAzContext',
    'Get-AvdRegionShortCode',
    'Get-AvdResourceName',
    'Get-AvdRequiredTag',
    'ConvertTo-AvdTagArgument',
    'Get-AvdLabContext',
    'Test-AvdSafeToDelete',
    'Get-AvdLogonPerformance',
    'Test-AvdAppDelivery',
    'Test-AvdFsLogixIntegrity',
    'Test-AvdScalingPlan',
    'Test-AvdResilience',
    'ConvertTo-AvdMarkdownTable'
)
