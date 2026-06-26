#Requires -Version 7.0
<#
.SYNOPSIS
    Run the AVD service-validation checks (control B.4.1) and emit the evidence results table.

.DESCRIPTION
    A read-only orchestrator for challenge-06. It resolves the deployed lab's infra-contract
    outputs the same way regardless of IaC track (Terraform state, Bicep deployment outputs, or
    plain resource-group discovery) and then runs the validation checks defined in Common.psm1:

      - Logon performance (P50/P95) from WVDConnections via Log Analytics KQL
      - Application launch / delivery (app groups present and assigned)
      - FSLogix profile integrity (Premium Files share, redundancy)
      - Autoscaling (scaling plan enabled and referencing the host pool)
      - Failover / resilience (storage replication + session-host count)

    Nothing here changes Azure state. Use -AsMarkdown to print the table you paste into the
    'Results' section of work/validation.md (the control B.4.1 evidence artifact).

.PARAMETER ResourceGroup
    Resolve the lab by enumerating resources in this resource group (default parameter set).

.PARAMETER BicepDeploymentName
    Resolve from a subscription-scope Bicep deployment's outputs.

.PARAMETER TerraformDir
    Resolve from 'terraform output -json' in this working directory.

.PARAMETER SubscriptionId
    Optional subscription to operate against.

.PARAMETER ProfileShareName
    FSLogix share name (contract default 'profiles').

.PARAMETER LookbackHours
    Logon-performance KQL lookback window in hours (default 24).

.PARAMETER TargetLogonSeconds
    Pass/fail threshold for the P95 logon time (default 30).

.PARAMETER AsMarkdown
    Emit a Markdown results table instead of the raw result objects.

.EXAMPLE
    ./Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec

.EXAMPLE
    ./Test-AvdService.ps1 -TerraformDir ../../infra/terraform -AsMarkdown

.NOTES
    Control B.4.1 -> agent avd-test-engineer -> evidence work/validation.md. Read-only.
#>
[CmdletBinding(DefaultParameterSetName = 'ResourceGroup')]
[OutputType([pscustomobject])]
param(
    [Parameter(ParameterSetName = 'ResourceGroup', Mandatory)][string]$ResourceGroup,
    [Parameter(ParameterSetName = 'Bicep', Mandatory)][string]$BicepDeploymentName,
    [Parameter(ParameterSetName = 'Terraform', Mandatory)][string]$TerraformDir,
    [string]$SubscriptionId,
    [string]$ProfileShareName = 'profiles',
    [ValidateRange(1, 720)][int]$LookbackHours = 24,
    [ValidateRange(1, 600)][int]$TargetLogonSeconds = 30,
    [switch]$AsMarkdown
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'lib', 'Common.psm1') -Force

# --- Resolve the lab context (track-agnostic) ------------------------------------------------
$resolveArgs = @{ ProfileShareName = $ProfileShareName }
if ($SubscriptionId) { $resolveArgs['SubscriptionId'] = $SubscriptionId }
switch ($PSCmdlet.ParameterSetName) {
    'Bicep' { $resolveArgs['BicepDeploymentName'] = $BicepDeploymentName }
    'Terraform' { $resolveArgs['TerraformDir'] = $TerraformDir }
    default { $resolveArgs['ResourceGroup'] = $ResourceGroup }
}

Write-AvdLog -Message "Resolving lab context ($($PSCmdlet.ParameterSetName))" -Level Step
$ctx = Get-AvdLabContext @resolveArgs
if ($null -eq $ctx -or [string]::IsNullOrWhiteSpace($ctx.ResourceGroupName)) {
    throw 'Could not resolve the lab context. Confirm the deployment exists and you are signed in (az login).'
}
Write-AvdLog -Message ("Target: rg={0} hostPool={1} storage={2}" -f $ctx.ResourceGroupName, $ctx.HostPoolName, $ctx.StorageAccountName) -Level Info

# --- Run the read-only validation checks -----------------------------------------------------
$results = [System.Collections.Generic.List[object]]::new()

$results.Add((Get-AvdLogonPerformance -LogAnalyticsWorkspaceId $ctx.LogAnalyticsWorkspaceId -LookbackHours $LookbackHours -TargetSeconds $TargetLogonSeconds))
$results.Add((Test-AvdAppDelivery -ResourceGroup $ctx.ResourceGroupName))
$results.Add((Test-AvdFsLogixIntegrity -ResourceGroup $ctx.ResourceGroupName -StorageAccountName $ctx.StorageAccountName -ProfileShareName $ctx.ProfileShareName))
$results.Add((Test-AvdScalingPlan -ResourceGroup $ctx.ResourceGroupName -HostPoolName $ctx.HostPoolName))
$results.Add((Test-AvdResilience -ResourceGroup $ctx.ResourceGroupName -StorageAccountName $ctx.StorageAccountName -HostPoolName $ctx.HostPoolName))

# --- Summary ---------------------------------------------------------------------------------
$summary = $results | Group-Object -Property Status | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }
Write-AvdLog -Message ("Validation summary: {0}" -f ($summary -join ' ')) -Level Step
if ($results | Where-Object { $_.Status -eq 'Fail' }) {
    Write-AvdLog -Message 'One or more checks FAILED - see the results below before signing off C06.' -Level Warning
}

# --- Output ----------------------------------------------------------------------------------
if ($AsMarkdown) {
    ConvertTo-AvdMarkdownTable -Row $results -Property 'Test', 'Method', 'Target', 'Actual', 'Status'
}
else {
    $results
}
