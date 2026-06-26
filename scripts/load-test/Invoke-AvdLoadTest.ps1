#Requires -Version 7.0
<#
.SYNOPSIS
    Generate lightweight, classroom-scale synthetic load on AVD session hosts so the
    service-validation signals (logon time, density, FSLogix IO) have data to measure.

.DESCRIPTION
    A license-free load generator for challenge-06. It resolves the lab's session-host VMs
    (track-agnostic: resource group, Bicep deployment, or Terraform state) and dispatches an
    in-guest PowerShell workload through 'az vm run-command invoke' - no paid SaaS, no agents
    to install. Each invoked host spins up a small, bounded number of worker jobs that mix light
    CPU work with FSLogix-style profile file IO for a capped duration, then clean up after
    themselves.

    Cost/scale guardrails are deliberate: ConcurrentUsers (<=25) and DurationMinutes (<=30) are
    range-validated, only the first -MaxHosts hosts are targeted, and the workload self-terminates.
    This is a token-scale signal generator for the lab, never a Contoso-scale stress test.

    Supports -WhatIf / -Confirm: with -WhatIf it prints what it would run without touching a host.

.PARAMETER ResourceGroup
    Resolve session hosts from this resource group (default parameter set).

.PARAMETER BicepDeploymentName
    Resolve from a subscription-scope Bicep deployment's outputs.

.PARAMETER TerraformDir
    Resolve from 'terraform output -json' in this working directory.

.PARAMETER SubscriptionId
    Optional subscription to operate against.

.PARAMETER ConcurrentUsers
    Synthetic worker sessions per host (1-25, default 3).

.PARAMETER DurationMinutes
    How long each host runs the workload (1-30, default 3).

.PARAMETER MaxHosts
    Maximum number of session hosts to target (1-10, default 2). Keeps lab cost/time bounded.

.EXAMPLE
    ./Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -ConcurrentUsers 5 -DurationMinutes 5

.EXAMPLE
    ./Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf

.NOTES
    Feeds control B.4.1 evidence (challenge-06). Cost-safe by design. Passes PSScriptAnalyzer.
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'ResourceGroup')]
[OutputType([pscustomobject])]
param(
    [Parameter(ParameterSetName = 'ResourceGroup', Mandatory)][string]$ResourceGroup,
    [Parameter(ParameterSetName = 'Bicep', Mandatory)][string]$BicepDeploymentName,
    [Parameter(ParameterSetName = 'Terraform', Mandatory)][string]$TerraformDir,
    [string]$SubscriptionId,
    [ValidateRange(1, 25)][int]$ConcurrentUsers = 3,
    [ValidateRange(1, 30)][int]$DurationMinutes = 3,
    [ValidateRange(1, 10)][int]$MaxHosts = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath 'lib', 'Common.psm1') -Force

# --- Resolve the lab context (track-agnostic) ------------------------------------------------
$resolveArgs = @{}
if ($SubscriptionId) { $resolveArgs['SubscriptionId'] = $SubscriptionId }
switch ($PSCmdlet.ParameterSetName) {
    'Bicep' { $resolveArgs['BicepDeploymentName'] = $BicepDeploymentName }
    'Terraform' { $resolveArgs['TerraformDir'] = $TerraformDir }
    default { $resolveArgs['ResourceGroup'] = $ResourceGroup }
}

Write-AvdLog -Message "Resolving session hosts ($($PSCmdlet.ParameterSetName))" -Level Step
$ctx = Get-AvdLabContext @resolveArgs
if ($null -eq $ctx -or [string]::IsNullOrWhiteSpace($ctx.ResourceGroupName)) {
    throw 'Could not resolve the lab context. Confirm the deployment exists and you are signed in (az login).'
}
$rg = $ctx.ResourceGroupName

$vms = Invoke-AzCommand -Json -AllowFailure -Arguments @('vm', 'list', '--resource-group', $rg, '-o', 'json')
$windowsVms = @()
if ($vms) {
    $windowsVms = @($vms | Where-Object { "$($_.storageProfile.osDisk.osType)" -ne 'Linux' })
}
if ($windowsVms.Count -eq 0) {
    Write-AvdLog -Message "No Windows session hosts found in '$rg'. Deploy hosts (challenge-05) first." -Level Warning
    return [pscustomobject]@{
        Test = 'Synthetic load'; Method = 'az vm run-command'; Target = "$ConcurrentUsers users x $DurationMinutes min"
        Actual = 'No session hosts'; Status = 'Skipped'; Evidence = "az vm list --resource-group $rg"
    }
}

$targets = $windowsVms | Select-Object -First $MaxHosts
Write-AvdLog -Message ("Targeting {0} of {1} host(s): {2}" -f @($targets).Count, $windowsVms.Count, (($targets | ForEach-Object { $_.name }) -join ', ')) -Level Info

# --- Build the in-guest workload (values baked in; cleans up after itself) --------------------
$loadScriptTemplate = @'
$durationMinutes = __DURATION__
$concurrent = __CONCURRENT__
$deadline = (Get-Date).AddMinutes($durationMinutes)
$jobs = 1..$concurrent | ForEach-Object {
    Start-Job -ScriptBlock {
        param($deadline)
        $dir = Join-Path $env:LOCALAPPDATA ('avd-loadtest-' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $file = Join-Path $dir 'profile-io.dat'
        $buffer = New-Object byte[] (262144)
        try {
            while ((Get-Date) -lt $deadline) {
                $null = [math]::Sqrt((Get-Random -Minimum 1 -Maximum 1000000))
                [System.IO.File]::WriteAllBytes($file, $buffer)
                $null = [System.IO.File]::ReadAllBytes($file)
                Start-Sleep -Milliseconds 200
            }
        }
        finally { Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue }
    } -ArgumentList $deadline
}
$jobs | Wait-Job | Out-Null
$jobs | Remove-Job -Force
"loadtest-complete users=$concurrent minutes=$durationMinutes host=$env:COMPUTERNAME"
'@

$loadScript = $loadScriptTemplate.Replace('__DURATION__', "$DurationMinutes").Replace('__CONCURRENT__', "$ConcurrentUsers")
$scriptFile = Join-Path ([System.IO.Path]::GetTempPath()) ("avd-load-{0}.ps1" -f ([guid]::NewGuid().ToString('N')))

$results = [System.Collections.Generic.List[object]]::new()
try {
    Set-Content -LiteralPath $scriptFile -Value $loadScript -Encoding utf8
    foreach ($vm in $targets) {
        $detail = "$ConcurrentUsers worker(s) x $DurationMinutes min via RunPowerShellScript"
        if (-not $PSCmdlet.ShouldProcess($vm.name, "Dispatch synthetic load ($detail)")) {
            $results.Add([pscustomobject]@{ Host = $vm.name; ConcurrentUsers = $ConcurrentUsers; DurationMinutes = $DurationMinutes; Status = 'WhatIf'; Detail = $detail })
            continue
        }
        Write-AvdLog -Message "Dispatching load to '$($vm.name)' (blocks ~$DurationMinutes min)..." -Level Step
        $invoke = Invoke-AzCommand -Json -AllowFailure -Arguments @(
            'vm', 'run-command', 'invoke', '--resource-group', $rg, '--name', $vm.name,
            '--command-id', 'RunPowerShellScript', '--scripts', ('@' + $scriptFile), '-o', 'json')
        $message = if ($invoke -and $invoke.value) { ($invoke.value | ForEach-Object { $_.message }) -join "`n" } else { '' }
        $status = if ($message -match 'loadtest-complete') { 'Pass' } else { 'Fail' }
        $line = ($message -split "`n" | Where-Object { $_ -match 'loadtest-complete' } | Select-Object -First 1)
        $results.Add([pscustomobject]@{
                Host            = $vm.name
                ConcurrentUsers = $ConcurrentUsers
                DurationMinutes = $DurationMinutes
                Status          = $status
                Detail          = if ($line) { $line.Trim() } else { $detail }
            })
        Write-AvdLog -Message "Host '$($vm.name)': $status" -Level Info
    }
}
finally {
    if (Test-Path -LiteralPath $scriptFile) { Remove-Item -LiteralPath $scriptFile -Force }
}

Write-AvdLog -Message 'Load run complete. Now collect signals with validate/Test-AvdService.ps1.' -Level Step
$results
