#Requires -Version 7.0
<#
.SYNOPSIS
    Guardrails first: create a Consumption budget with alerts and session-host auto-shutdown
    for an AVD MicroHack lab resource group.

.DESCRIPTION
    Run this BEFORE deploying any session hosts (challenge-00 and again before challenge-05).
    It is idempotent and safe to re-run:

      1. Ensures the lab resource group exists and carries the required MicroHack tags
         (workload=avd-microhack, env, owner, costCenter=training, autoDelete=true).
      2. Creates / updates a monthly, resource-group-scoped Consumption budget with 50 / 80 / 100 %
         alert notifications. The budget is deployed with an ARM template via
         'az deployment group create', so it upserts cleanly on every run and works on both the
         Bicep and Terraform infra tracks.
      3. Applies DevTest Labs auto-shutdown to every VM already in the group (re-run after the
         session hosts are deployed to protect them). Skips cleanly when no VMs exist yet.

    Nothing is hardcoded: subscription, region, budget amount and owner are all parameters.
    Supports -WhatIf / -Confirm for every change (the budget step shows an ARM what-if preview).

.PARAMETER SubscriptionId
    Subscription to operate against. Defaults to the signed-in subscription.

.PARAMETER Location
    Azure region for the lab (default swedencentral). Drives the naming short code.

.PARAMETER Environment
    lab or prod (default lab). Part of the name and the env tag.

.PARAMETER ResourceGroup
    Lab resource group. Defaults to the contract name (e.g. rg-avd-lab-sec).

.PARAMETER BudgetAmount
    Monthly budget ceiling in subscription currency (default 50).

.PARAMETER BudgetName
    Budget resource name. Defaults to '<resourceGroup>-budget'.

.PARAMETER Owner
    Owner tag value. Defaults to the signed-in user.

.PARAMETER NotificationEmail
    Optional email to receive budget alerts in addition to the Owner RBAC role.

.PARAMETER ShutdownTime
    Auto-shutdown time, 24h HHmm (default 1900).

.PARAMETER ShutdownTimeZone
    Auto-shutdown time zone (default 'W. Europe Standard Time', matching swedencentral).

.PARAMETER SkipAutoShutdown
    Do not configure VM auto-shutdown (budget + tags only).

.EXAMPLE
    ./New-AvdLabGuardrails.ps1 -SubscriptionId <id> -Location swedencentral -BudgetAmount 50

.EXAMPLE
    # Re-run after deploying session hosts to apply auto-shutdown to them.
    ./New-AvdLabGuardrails.ps1 -ResourceGroup rg-avd-lab-sec

.NOTES
    Control: cost guardrails (see .github/skills/avd-cost-guardrails). Passes PSScriptAnalyzer.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [string]$SubscriptionId,
    [string]$Location = 'swedencentral',
    [ValidateSet('lab', 'prod')][string]$Environment = 'lab',
    [string]$ResourceGroup,
    [ValidateRange(1, 100000)][int]$BudgetAmount = 50,
    [string]$BudgetName,
    [string]$Owner,
    [string]$NotificationEmail,
    [ValidatePattern('^[0-2][0-9][0-5][0-9]$')][string]$ShutdownTime = '1900',
    [string]$ShutdownTimeZone = 'W. Europe Standard Time',
    [switch]$SkipAutoShutdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'lib', 'Common.psm1') -Force

# --- Resolve context, names and tags ---------------------------------------------------------
$context = Get-AvdAzContext -SubscriptionId $SubscriptionId
Write-AvdLog -Message ("Subscription: {0} ({1})" -f $context.SubscriptionName, $context.SubscriptionId) -Level Step

if ([string]::IsNullOrWhiteSpace($ResourceGroup)) {
    $ResourceGroup = Get-AvdResourceName -ResourceType 'rg' -Environment $Environment -Location $Location
}
if ([string]::IsNullOrWhiteSpace($BudgetName)) {
    $BudgetName = "$ResourceGroup-budget"
}
if ([string]::IsNullOrWhiteSpace($Owner)) {
    $Owner = if ($context.User) { $context.User } else { 'unknown' }
}

$tags = Get-AvdRequiredTag -Environment $Environment -Owner $Owner
$tagArgs = ConvertTo-AvdTagArgument -Tag $tags

# --- 1. Resource group (idempotent) ----------------------------------------------------------
$existing = Invoke-AzCommand -Json -AllowFailure -Arguments @('group', 'show', '--name', $ResourceGroup, '-o', 'json')
if ($null -eq $existing) {
    if ($PSCmdlet.ShouldProcess($ResourceGroup, "Create resource group in $Location")) {
        Invoke-AzCommand -Arguments (@('group', 'create', '--name', $ResourceGroup, '--location', $Location, '--tags') + $tagArgs) | Out-Null
        Write-AvdLog -Message "Created resource group '$ResourceGroup'." -Level Step
    }
}
else {
    if ($PSCmdlet.ShouldProcess($ResourceGroup, 'Update resource group tags')) {
        Invoke-AzCommand -Arguments (@('group', 'update', '--name', $ResourceGroup, '--tags') + $tagArgs) | Out-Null
        Write-AvdLog -Message "Resource group '$ResourceGroup' already exists; tags reconciled." -Level Info
    }
}

# --- 2. Consumption budget (ARM upsert, RG-scoped, 50/80/100 % alerts) ------------------------
$start = [datetime]::UtcNow
$startDate = '{0:yyyy-MM}-01T00:00:00Z' -f $start
$endDate = '{0:yyyy-MM}-01T00:00:00Z' -f $start.AddYears(5)

$notification = [ordered]@{}
foreach ($threshold in 50, 80, 100) {
    $entry = [ordered]@{
        enabled       = $true
        operator      = 'GreaterThanOrEqualTo'
        threshold     = $threshold
        contactRoles  = @('Owner')
        thresholdType = 'Actual'
    }
    if (-not [string]::IsNullOrWhiteSpace($NotificationEmail)) {
        $entry['contactEmails'] = @($NotificationEmail)
    }
    $notification["Actual_GreaterThan_${threshold}_Percent"] = $entry
}

$template = [ordered]@{
    '$schema'      = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
    contentVersion = '1.0.0.0'
    resources      = @(
        [ordered]@{
            type       = 'Microsoft.Consumption/budgets'
            apiVersion = '2023-05-01'
            name       = $BudgetName
            properties = [ordered]@{
                category      = 'Cost'
                amount        = $BudgetAmount
                timeGrain     = 'Monthly'
                timePeriod    = [ordered]@{ startDate = $startDate; endDate = $endDate }
                notifications = $notification
            }
        }
    )
}

$templateFile = Join-Path ([System.IO.Path]::GetTempPath()) ("avd-budget-{0}.json" -f ([guid]::NewGuid().ToString('N')))
try {
    $template | ConvertTo-Json -Depth 30 | Set-Content -LiteralPath $templateFile -Encoding utf8
    $deploymentName = "avd-guardrails-budget-$Environment"
    if ($PSCmdlet.ShouldProcess($BudgetName, "Create/update monthly budget of $BudgetAmount with 50/80/100% alerts")) {
        Invoke-AzCommand -Arguments @(
            'deployment', 'group', 'create', '--resource-group', $ResourceGroup,
            '--name', $deploymentName, '--template-file', $templateFile, '-o', 'none') | Out-Null
        Write-AvdLog -Message "Budget '$BudgetName' set to $BudgetAmount/month (alerts at 50/80/100%)." -Level Step
    }
    else {
        # -WhatIf / declined: show the ARM what-if preview instead of mutating.
        Invoke-AzCommand -AllowFailure -Arguments @(
            'deployment', 'group', 'what-if', '--resource-group', $ResourceGroup,
            '--template-file', $templateFile, '-o', 'table') | Out-Null
    }
}
finally {
    if (Test-Path -LiteralPath $templateFile) { Remove-Item -LiteralPath $templateFile -Force }
}

# --- 3. Session-host auto-shutdown (idempotent; skips when no VMs) ----------------------------
$autoShutdownResults = @()
if (-not $SkipAutoShutdown) {
    $vms = Invoke-AzCommand -Json -AllowFailure -Arguments @('vm', 'list', '--resource-group', $ResourceGroup, '-o', 'json')
    if (-not $vms -or @($vms).Count -eq 0) {
        Write-AvdLog -Message 'No VMs in the group yet; re-run after deploying session hosts to apply auto-shutdown.' -Level Info
    }
    else {
        foreach ($vm in $vms) {
            if ($PSCmdlet.ShouldProcess($vm.name, "Set auto-shutdown at $ShutdownTime ($ShutdownTimeZone)")) {
                Invoke-AzCommand -AllowFailure -Arguments @(
                    'vm', 'auto-shutdown', '--resource-group', $ResourceGroup, '--name', $vm.name,
                    '--time', $ShutdownTime, '--timezone', $ShutdownTimeZone, '-o', 'none') | Out-Null
                Write-AvdLog -Message "Auto-shutdown set on '$($vm.name)'." -Level Info
            }
            $autoShutdownResults += [pscustomobject]@{ Host = $vm.name; ShutdownTime = $ShutdownTime; TimeZone = $ShutdownTimeZone }
        }
    }
}

# --- Result --------------------------------------------------------------------------------
[pscustomobject]@{
    SubscriptionId    = $context.SubscriptionId
    ResourceGroup     = $ResourceGroup
    Location          = $Location
    Tags              = $tags
    BudgetName        = $BudgetName
    BudgetAmount      = $BudgetAmount
    AlertThresholds   = @(50, 80, 100)
    AutoShutdownHosts = $autoShutdownResults
}
