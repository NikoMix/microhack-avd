#Requires -Version 7.0
<#
.SYNOPSIS
    Tear down an AVD MicroHack lab safely: delete the lab resource group (or just the AVD
    objects) after confirming the target is a disposable, tagged lab, then verify nothing remains.

.DESCRIPTION
    The end-of-day teardown for the live-deploy challenges, honouring the cost guardrails. It
    refuses to touch anything that is not tagged as a MicroHack lab
    (workload=avd-microhack or autoDelete=true), so it can never delete a real environment.

    Two scopes:
      - ResourceGroup (default): delete the entire lab resource group and poll until it is gone.
        The RG-scoped budget is removed with the group; re-run setup/New-AvdLabGuardrails.ps1 to
        recreate guardrails next time.
      - AvdObjects: delete only the Desktop Virtualization objects and session-host compute
        (VMs, disks, NICs), keeping the resource group, network, storage (FSLogix profiles) and
        the budget so you can redeploy. Add -RemoveBudget to also delete the budget.

    Idempotent: a missing group reports success; an already-clean group reports 0 remaining.
    Destructive actions are gated by ShouldProcess with ConfirmImpact High, so -Confirm prompts
    by default and -WhatIf shows exactly what would be deleted.

.PARAMETER ResourceGroup
    The lab resource group to tear down.

.PARAMETER SubscriptionId
    Optional subscription to operate against.

.PARAMETER Scope
    ResourceGroup (delete everything) or AvdObjects (delete AVD + compute only). Default ResourceGroup.

.PARAMETER RemoveBudget
    In AvdObjects scope, also delete the Consumption budget (kept by default).

.PARAMETER BudgetName
    Budget name to remove with -RemoveBudget. Defaults to '<resourceGroup>-budget'.

.PARAMETER TimeoutMinutes
    How long to poll for resource-group deletion to finish (1-60, default 15).

.EXAMPLE
    ./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Confirm

.EXAMPLE
    ./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -Scope AvdObjects   # keep RG/network/profiles

.EXAMPLE
    ./Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf             # preview only

.NOTES
    Cost guardrail / teardown (see .github/skills/avd-cost-guardrails). Passes PSScriptAnalyzer.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
[OutputType([pscustomobject])]
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [string]$SubscriptionId,
    [ValidateSet('ResourceGroup', 'AvdObjects')][string]$Scope = 'ResourceGroup',
    [switch]$RemoveBudget,
    [string]$BudgetName,
    [ValidateRange(1, 60)][int]$TimeoutMinutes = 15
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'lib', 'Common.psm1') -Force

Get-AvdAzContext -SubscriptionId $SubscriptionId | Out-Null
if ([string]::IsNullOrWhiteSpace($BudgetName)) { $BudgetName = "$ResourceGroup-budget" }

# --- Idempotency: nothing to do if the group is already gone ----------------------------------
$exists = "$(Invoke-AzCommand -AllowFailure -Arguments @('group', 'exists', '--name', $ResourceGroup))".Trim()
if ($exists -ne 'true') {
    Write-AvdLog -Message "Resource group '$ResourceGroup' does not exist - nothing to tear down." -Level Info
    return [pscustomobject]@{ ResourceGroup = $ResourceGroup; Scope = $Scope; Safe = $true; Deleted = $true; RemainingResourceCount = 0; Reason = 'Already absent' }
}

# --- Safety: only ever delete a tagged, disposable lab ----------------------------------------
$safe = Test-AvdSafeToDelete -ResourceGroup $ResourceGroup
if (-not $safe.Safe) {
    Write-AvdLog -Message $safe.Reason -Level Warning
    return [pscustomobject]@{ ResourceGroup = $ResourceGroup; Scope = $Scope; Safe = $false; Deleted = $false; RemainingResourceCount = $null; Reason = $safe.Reason }
}
Write-AvdLog -Message $safe.Reason -Level Info

# --- Scope: ResourceGroup (delete everything, poll until gone) ---------------------------------
if ($Scope -eq 'ResourceGroup') {
    if (-not $PSCmdlet.ShouldProcess($ResourceGroup, 'Delete resource group and ALL resources')) {
        $preview = Invoke-AzCommand -Json -AllowFailure -Arguments @('resource', 'list', '--resource-group', $ResourceGroup, '-o', 'json')
        $count = if ($preview) { @($preview).Count } else { 0 }
        Write-AvdLog -Message "WhatIf: would delete '$ResourceGroup' and its $count resource(s)." -Level Info
        return [pscustomobject]@{ ResourceGroup = $ResourceGroup; Scope = $Scope; Safe = $true; Deleted = $false; RemainingResourceCount = $count; Reason = 'WhatIf preview' }
    }

    Write-AvdLog -Message "Deleting resource group '$ResourceGroup'..." -Level Step
    Invoke-AzCommand -Arguments @('group', 'delete', '--name', $ResourceGroup, '--yes', '--no-wait') | Out-Null

    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    do {
        Start-Sleep -Seconds 15
        $stillThere = "$(Invoke-AzCommand -AllowFailure -Arguments @('group', 'exists', '--name', $ResourceGroup))".Trim()
        Write-AvdLog -Message "  ...waiting for deletion (exists=$stillThere)" -Level Verbose
    } while ($stillThere -eq 'true' -and (Get-Date) -lt $deadline)

    $gone = ($stillThere -ne 'true')
    if ($gone) { Write-AvdLog -Message "Resource group '$ResourceGroup' deleted." -Level Step }
    else { Write-AvdLog -Message "Deletion still in progress after $TimeoutMinutes min; Azure will finish asynchronously." -Level Warning }
    return [pscustomobject]@{ ResourceGroup = $ResourceGroup; Scope = $Scope; Safe = $true; Deleted = $gone; RemainingResourceCount = $(if ($gone) { 0 } else { $null }); Reason = $(if ($gone) { 'Deleted' } else { 'Deletion in progress' }) }
}

# --- Scope: AvdObjects (delete AVD + compute only, keep RG/network/storage) --------------------
if ($RemoveBudget) {
    if ($PSCmdlet.ShouldProcess($BudgetName, 'Delete Consumption budget')) {
        Invoke-AzCommand -AllowFailure -Arguments @('consumption', 'budget', 'delete', '--budget-name', $BudgetName, '--resource-group', $ResourceGroup) | Out-Null
        Write-AvdLog -Message "Budget '$BudgetName' removed." -Level Info
    }
}

# Dependency-safe deletion order (subresources/dependants first).
$deletionOrder = @(
    'Microsoft.DesktopVirtualization/scalingplans'
    'Microsoft.Compute/virtualMachines'
    'Microsoft.DesktopVirtualization/applicationgroups'
    'Microsoft.DesktopVirtualization/workspaces'
    'Microsoft.DesktopVirtualization/hostpools'
    'Microsoft.Compute/disks'
    'Microsoft.Network/networkInterfaces'
)

$deleted = 0
foreach ($type in $deletionOrder) {
    $items = Invoke-AzCommand -Json -AllowFailure -Arguments @('resource', 'list', '--resource-group', $ResourceGroup, '--resource-type', $type, '-o', 'json')
    if (-not $items) { continue }
    foreach ($item in $items) {
        if ($PSCmdlet.ShouldProcess($item.name, "Delete $type")) {
            Invoke-AzCommand -AllowFailure -Arguments @('resource', 'delete', '--ids', $item.id) | Out-Null
            $deleted++
            Write-AvdLog -Message "Deleted $type/$($item.name)." -Level Info
        }
    }
}

# Recount AVD + compute resources still present.
$remaining = 0
foreach ($type in $deletionOrder) {
    $items = Invoke-AzCommand -Json -AllowFailure -Arguments @('resource', 'list', '--resource-group', $ResourceGroup, '--resource-type', $type, '-o', 'json')
    if ($items) { $remaining += @($items).Count }
}
Write-AvdLog -Message "AvdObjects teardown complete: deleted $deleted, $remaining AVD/compute resource(s) remaining." -Level Step
[pscustomobject]@{ ResourceGroup = $ResourceGroup; Scope = $Scope; Safe = $true; Deleted = ($remaining -eq 0); RemainingResourceCount = $remaining; Reason = "Deleted $deleted AVD/compute resource(s)" }
