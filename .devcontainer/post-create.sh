#!/usr/bin/env bash
# Post-create setup for the AVD Module B MicroHack dev container.
# Idempotent: safe to re-run. Keeps tooling current and verifies the toolchain.
set -euo pipefail

echo "▶ AVD MicroHack — provisioning developer toolchain…"

# --- Ensure Bicep is present & current (azure-cli feature installs it, refresh anyway) ---
az bicep install >/dev/null 2>&1 || true
az bicep upgrade >/dev/null 2>&1 || true

# --- PowerShell analyzers used by scripts/ and CI ---
pwsh -NoLogo -NoProfile -Command \
  "Set-PSRepository PSGallery -InstallationPolicy Trusted; \
   if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) { Install-Module PSScriptAnalyzer -Scope CurrentUser -Force }; \
   if (-not (Get-Module -ListAvailable Pester)) { Install-Module Pester -Scope CurrentUser -Force }" \
  || echo '  (PowerShell module install skipped)'

# --- Docs site + slides + markdown tooling (global, latest) ---
npm install -g --no-fund --no-audit \
  @marp-team/marp-cli@latest \
  markdownlint-cli2@latest \
  || echo '  (global npm tooling install skipped)'

# --- Pre-warm the docs site dependencies if present ---
if [ -f docs/package.json ]; then
  ( cd docs && npm install --no-fund --no-audit ) || echo '  (docs npm install skipped — run later)'
fi

echo ""
echo "▶ Toolchain versions:"
for t in az azd bicep terraform gh node pwsh python3; do
  if command -v "$t" >/dev/null 2>&1; then
    printf '  %-10s %s\n' "$t" "$($t --version 2>/dev/null | head -n1)"
  else
    printf '  %-10s NOT FOUND\n' "$t"
  fi
done

cat <<'EOF'

✅ Dev container ready.

Next steps (see challenges/challenge-00-setup/README.md):
  1. Confirm GH_TOKEN is set            →  gh auth status
  2. Sign in to YOUR Azure subscription →  az login --use-device-code
  3. Verify the MCP servers + agents    →  open Copilot Chat, run the C0 checks
  4. Deploy the cost-cap budget         →  scripts/setup/

Start the course at: challenges/challenge-00-setup/
EOF
