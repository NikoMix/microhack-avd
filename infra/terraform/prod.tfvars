###############################################################################
# prod.tfvars — PRODUCTION-SHAPED REFERENCE (do not apply at full scale here)
#
# ┌──────────────────────────────────────────────────────────────────────────┐
# │ WARNING: This file documents the production-shaped knobs (zonal premium   │
# │ storage, larger hosts, autoscale, private endpoints). It is a REFERENCE   │
# │ for the High-Level / Low-Level Design — NOT something to apply at         │
# │ Contoso's real fleet size in the shared classroom subscription.           │
# │                                                                            │
# │ Contoso production sizing is a PAPER design (control B.1.1):               │
# │   700 knowledge + 200 call-centre  → Pooled multi-session                 │
# │    60 power     +  40 developers   → Personal                             │
# │   = 1,000 users. Deploy that with per-persona host pools and proper       │
# │   quota — never from this single token-scale stack.                       │
# │                                                                            │
# │ Even with this file, sessionHostCount stays small so a curious            │
# │ `apply` cannot run up a surprise bill (the variable also caps at 10).     │
# └──────────────────────────────────────────────────────────────────────────┘
#
# Apply (token scale only):  terraform apply -var-file=prod.tfvars
###############################################################################

location    = "swedencentral"
environment = "prod"
namePrefix  = "avd"

# --- Session hosts ------------------------------------------------------------
# Reference SKU for the knowledge-worker pool. Kept to 2 hosts here; production
# capacity is derived per persona in the sizing assessment, not hard-coded.
sessionHostCount = 2
sessionHostSize  = "Standard_D8as_v5" # 8 vCPU / 32 GiB knowledge-worker reference
hostPoolType     = "Pooled"
maxSessionLimit  = 16

# --- FSLogix profile storage (production posture) -----------------------------
profileStorageQuotaGb = 1024
profileStorageSku     = "Premium_ZRS" # zone-redundant for resilience
osDiskStorageType     = "Premium_LRS"

# --- Security baseline --------------------------------------------------------
enablePrivateEndpoints = true

# --- Autoscale ----------------------------------------------------------------
deployScalingPlan = true

# --- Identity -----------------------------------------------------------------
# REQUIRED in production: the Entra group ID granted desktop access + KV admin.
adminObjectId = ""

# --- Cost guardrails ----------------------------------------------------------
budgetAmount = 1000
# Set to the first of the current month before applying.
budgetStartDate    = "2026-06-01T00:00:00Z"
autoShutdownTime   = "2000"
enableAutoShutdown = true

owner = "avd-platform-team"

tags = {
  course      = "avd-module-b-ttt"
  designStage = "reference"
}
