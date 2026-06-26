---
applyTo: "scripts/**/*.ps1"
---
# PowerShell authoring rules (lab scripts)

- **Cross-platform PowerShell 7+.** Scripts run in the dev container / Codespaces (Linux) and on
  Windows. Avoid Windows-only cmdlets unless guarded.
- **Strictness:** start with `#Requires -Version 7.0`, `[CmdletBinding()]`, `param(...)` with
  typed parameters and `Set-StrictMode -Version Latest`; `$ErrorActionPreference = 'Stop'`.
- **Idempotent & safe:** check-before-create; support `-WhatIf`/`-Confirm` via
  `SupportsShouldProcess` for anything that creates or deletes Azure resources. Destroy scripts
  must confirm the target resource group before deleting.
- **Azure:** prefer the `az` CLI (already authenticated) or `Az` modules; never hardcode
  subscription IDs, tenant IDs, or secrets — take them as parameters or read from context.
- **Output:** use `Write-Verbose`/`Write-Information` for progress, return objects (not formatted
  strings) so output is composable. No `Write-Host` for data.
- **Quality:** must pass `PSScriptAnalyzer` (no errors/warnings). Add comment-based help
  (`.SYNOPSIS`, `.PARAMETER`, `.EXAMPLE`) to every script.
- **Cost guardrails:** setup scripts create a budget + auto-shutdown; reset scripts verify
  teardown and report remaining resources.
