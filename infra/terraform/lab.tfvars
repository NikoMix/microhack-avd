###############################################################################
# lab.tfvars — classroom / token-scale footprint
#
# Apply with:  terraform apply -var-file=lab.tfvars
#
# This is the footprint you actually deploy in the MicroHack: ONE small session
# host, cost-trimmed storage and disk, budget + auto-shutdown on. Contoso's full
# ~1,000-user fleet (700 knowledge + 200 call-centre + 60 power + 40 dev) stays a
# paper design in the assessment — never scale this to production in the shared
# subscription. Tear down with scripts/reset when finished.
###############################################################################

location    = "swedencentral"
environment = "lab"
namePrefix  = "avd"

# --- Session hosts: keep tiny -------------------------------------------------
deploySessionHosts = true # false = deploy the control plane only (no VMs)
sessionHostCount   = 1
sessionHostSize    = "Standard_D2as_v5" # 2 vCPU / 8 GiB — smallest sensible AVD host
hostPoolType       = "Pooled"
maxSessionLimit    = 8

# Break-glass local admin. The password is SENSITIVE — leave it unset to auto-generate
# a strong password (stored in Key Vault), or supply your own WITHOUT committing it:
#   $env:TF_VAR_sessionHostAdminPassword = "<complex-password>"   # PowerShell
sessionHostAdminUsername = "avdadmin"

# --- FSLogix profile storage (cost-trimmed for lab) ---------------------------
profileStorageQuotaGb = 128
profileStorageSku     = "Premium_LRS"     # LRS to trim lab cost; ZRS in prod
osDiskStorageType     = "StandardSSD_LRS" # StandardSSD to trim lab cost

# --- Security baseline --------------------------------------------------------
enablePrivateEndpoints = true # private endpoint + private DNS for the profile share

# --- Autoscale ----------------------------------------------------------------
# A single host plus an autoscale plan would fight each other (ramp-down would
# deallocate the only host), so the scaling plan is OFF in the lab. Turn it on
# once you run 2+ hosts.
deployScalingPlan = false

# --- Identity -----------------------------------------------------------------
# Entra object ID (user or, preferably, a group) granted "Desktop Virtualization
# User" on the app group and Key Vault Administrator. Leave empty for `validate`
# / `plan`; set a real GUID before `apply` to get working desktop access.
adminObjectId = ""

# --- Cost guardrails ----------------------------------------------------------
budgetAmount = 100
# Budget start date MUST be the first day of a month. Update this to the first of
# the CURRENT month before you apply, or Azure will reject the budget.
budgetStartDate    = "2026-06-01T00:00:00Z"
autoShutdownTime   = "1900"
enableAutoShutdown = true

owner = "avd-microhack-lab"

tags = {
  course = "avd-module-b-ttt"
}
