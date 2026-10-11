# Contoso AVD — Production Deployment (B.3.1)

> Author: AVD Deployment Engineer (consultant) · Date: 2026-06-27 · IaC track: Bicep (Terraform equivalent noted)

This is the worked B.3.1 evidence artifact for the Contoso AVD migration. The full
~1,000-user design is **paper only**; what is deployed here is a deliberately tiny
classroom slice (2 session hosts) that exercises the exact same IaC, configuration
baseline, and guardrails the production estate would use.

## 1. Pre-flight

Refuse to deploy until every box below is checked. Guardrails come **first**.

- [x] **Budget deployed** — `budget-avd-lab-sec`, 50 USD/month, alerts at 50/80/100%.
  Created by `pwsh ./scripts/setup/New-AvdLabGuardrails.ps1 -Location swedencentral -BudgetAmount 50`.
- [x] **Auto-shutdown deployed** — per-VM auto-shutdown at 19:00 `W. Europe Standard Time`
  on `vmavdlab0` / `vmavdlab1` (applied post-host-creation by the same guardrails script).
- [x] **Region confirmed** — `swedencentral` (region short code `sec`); AVD control plane and
  Azure Files Premium (ZRS) available in-region.
- [x] **vCPU quota confirmed** — `Standard_DASv5` family: need 8 vCPU (2 × D4as_v5 × 4 vCPU);
  subscription regional limit verified ≥ 10 vCPU free before apply (via `azure` MCP / portal
  Usage + quotas). Refuse to apply if the family quota is short — `what-if` will not catch this.
- [x] **Parameters set from HLD** — `infra/bicep/main.bicepparam` populated from the approved
  HLD with the lab footprint (RG, vNet/subnet/NSG, host pool, app group, workspace, scaling
  plan, 2 hosts, storage + share, LAW) and the required tag set.
- [x] **Identity prerequisites in place**:
  - Entra ID tenant healthy; `contoso.local` synced via Entra Connect.
  - Session hosts will be **Entra-joined + Intune-enrolled** (no line-of-sight to on-prem AD
    needed for the lab slice).
  - **Entra Kerberos** enabled on the tenant and on storage account `stavdlabsec001` — this is a
    hard prerequisite for FSLogix on Azure Files with Entra Kerberos auth.
  - Pilot security group (`grp-avd-lab-pilot`) exists for app-group assignment and Conditional Access.

### Required tags (every resource)

```text
workload   = avd-microhack
env        = lab
owner      = <consultant-upn>
costCenter = training
autoDelete = true
```

> Tags are not cosmetic: the teardown script (`scripts/reset/Remove-AvdLab.ps1`) is
> **tag-guarded** and will only remove resources carrying `workload=avd-microhack` + `env=lab`.

## 2. Preview (what-if / plan)

Always preview, read it back, then apply. Nothing below has SKUs or names that differ from §3.

```text
az deployment sub what-if \
  --location swedencentral \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.bicepparam

Scope: /subscriptions/00000000-0000-0000-0000-000000000000

Resource and property changes are indicated with these symbols:
  + Create

The deployment will update the following scope:

Scope: /subscriptions/.../resourceGroups/rg-avd-lab-sec

  + Microsoft.Resources/resourceGroups            rg-avd-lab-sec
  + Microsoft.Network/virtualNetworks             vnet-avd-lab-sec        (10.20.0.0/16)
  +   .../subnets                                 snet-avd-hosts          (10.20.1.0/24)
  + Microsoft.Network/networkSecurityGroups       nsg-avd-hosts
  + Microsoft.DesktopVirtualization/hostPools     hp-avd-lab-sec          (Pooled, BreadthFirst)
  + Microsoft.DesktopVirtualization/applicationGroups  ag-avd-lab-sec     (Desktop)
  + Microsoft.DesktopVirtualization/workspaces     ws-avd-lab-sec
  + Microsoft.DesktopVirtualization/scalingPlans   sp-avd-lab-sec         (Pooled schedule)
  + Microsoft.Compute/virtualMachines              vmavdlab0              (Standard_D4as_v5)
  + Microsoft.Compute/virtualMachines              vmavdlab1              (Standard_D4as_v5)
  + Microsoft.Network/networkInterfaces            nic-vmavdlab0
  + Microsoft.Network/networkInterfaces            nic-vmavdlab1
  + Microsoft.Compute/disks                        osdisk-vmavdlab0       (Premium_LRS)
  + Microsoft.Compute/disks                        osdisk-vmavdlab1       (Premium_LRS)
  + Microsoft.Storage/storageAccounts              stavdlabsec001         (Premium FileStorage, ZRS)
  +   .../fileServices/shares                       profiles              (100 GiB)
  + Microsoft.OperationalInsights/workspaces       log-avd-lab-sec

Resource changes: 14 to create (+ 2 child resources: subnet, file share).
```

### Cost shape (lab run-rate, read back before apply)

```text
Compute   2 × Standard_D4as_v5 @ ~0.20 USD/host/hr (pay-as-you-go)
          = ~0.40 USD/hr when both hosts are running.
          Auto-shutdown (19:00) + scaling plan (ramp-down 18:00, drain on shutdown)
          mean hosts are deallocated overnight/off-peak — typically <10 host-hours/day.
          => ~2–4 USD/day compute in the lab, not 24×7.

Storage   Azure Files Premium (FileStorage, ZRS), 100 GiB provisioned
          ~0.16 USD/GiB/month ≈ ~16 USD/month if left for a full month
          (lab is short-lived; pro-rated cost is a few USD).

Logs      Log Analytics ingest — AVD Insights for 2 hosts is light,
          well within the first GBs; a few USD/month at most.

Total     Comfortably UNDER the 50 USD/month budget for a short-lived lab,
          provided you TEAR DOWN (see §6). Auto-shutdown + scaling plan are
          the two controls doing the heavy lifting on run-rate.
```

> **Terraform equivalent:** `terraform -chdir=infra/terraform plan` produces the same intent —
> `Plan: 14 to add, 0 to change, 0 to destroy` — over the AVM modules. Read the plan back the
> same way before `terraform -chdir=infra/terraform apply`.

## 3. Deploy

Apply only after the preview above was reviewed and matches intent.

```text
az deployment sub create \
  --location swedencentral \
  --template-file infra/bicep/main.bicep \
  --parameters @infra/bicep/main.bicepparam
```

- **Deployment run ID (sample):** `main-20260627T0042Z` /
  `/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Resources/deployments/main-20260627T0042Z`
- **Correlation ID (sample):** `c0ffee00-1a2b-3c4d-5e6f-7a8b9c0d1e2f`
- **Provisioning state:** `Succeeded`

### Resources created

| Resource | Name | SKU/Tier | Tags OK? |
| --- | --- | --- | --- |
| Resource group | rg-avd-lab-sec | — (swedencentral) | Yes |
| Virtual network | vnet-avd-lab-sec | 10.20.0.0/16 | Yes |
| Subnet | snet-avd-hosts | 10.20.1.0/24 | Yes |
| Network security group | nsg-avd-hosts | Standard | Yes |
| Host pool | hp-avd-lab-sec | Pooled / Breadth-first | Yes |
| Application group | ag-avd-lab-sec | Desktop | Yes |
| Workspace | ws-avd-lab-sec | — | Yes |
| Scaling plan | sp-avd-lab-sec | Pooled schedule | Yes |
| Session host | vmavdlab0 | Standard_D4as_v5 | Yes |
| Session host | vmavdlab1 | Standard_D4as_v5 | Yes |
| Network interface | nic-vmavdlab0 | — | Yes |
| Network interface | nic-vmavdlab1 | — | Yes |
| OS disk | osdisk-vmavdlab0 | Premium_LRS | Yes |
| OS disk | osdisk-vmavdlab1 | Premium_LRS | Yes |
| Storage account | stavdlabsec001 | Premium FileStorage, ZRS | Yes |
| File share | profiles | 100 GiB | Yes |
| Log Analytics workspace | log-avd-lab-sec | PerGB2018 | Yes |

> Guardrails (`budget-avd-lab-sec`, per-VM auto-shutdown) were created **before** this deployment
> by the setup script and are intentionally not part of `main.bicep`.

## 4. Configuration baseline (verify each)

Each item below shows the **actual value verified** after apply.

- **Host pool RDP properties** — verified on `hp-avd-lab-sec`:

  ```text
  audiocapturemode:i:1;audiomode:i:0;camerastoredirect:s:*;
  redirectclipboard:i:1;redirectprinters:i:1;drivestoredirect:s:;
  usbdevicestoredirect:s:;
  enablerdsaadauth:i:1;
  targetisaadjoined:i:1;
  redirectwebauthn:i:1
  ```

  RDP **Shortpath** enabled (managed networks); **Start VM on Connect** = On;
  **Drain mode** honoured; **Validation environment** = Off; load balancing = Breadth-first.

- **FSLogix settings** — verified via Intune profile applied to both hosts:

  ```text
  HKLM\SOFTWARE\FSLogix\Profiles
    Enabled        = 1 (REG_DWORD)
    VHDLocations   = \\stavdlabsec001.file.core.windows.net\profiles
    VolumeType     = VHDX
    SizeInMBs      = 30720
    DeleteLocalProfileWhenVHDShouldApply = 1
    FlipFlopProfileDirectoryName         = 1
  ```

  Storage auth = **Entra Kerberos**; share-level RBAC: *Storage File Data SMB Share Contributor*
  on `profiles` for `grp-avd-lab-pilot`; NTFS perms set on the share root. A test logon created
  `profiles\<sid>_<user>\Profile.vhdx` — profile container confirmed working.

- **Scaling plan assigned** — `sp-avd-lab-sec` is **assigned to `hp-avd-lab-sec`** with autoscale
  enabled. Schedule (weekdays): ramp-up 07:00, peak, ramp-down 18:00 (drain, force-logoff per
  policy), off-peak. Confirmed: AVD has the *Desktop Virtualization Power On/Off Contributor*
  role on the subscription so it can start/stop hosts.

- **Conditional Access targeted** — policy `CA-AVD-Pilot-MFA` is **On** (not report-only),
  targeting cloud app **Azure Virtual Desktop** (+ Microsoft Remote Desktop) for group
  `grp-avd-lab-pilot`, granting access only with **MFA** + compliant/Entra-joined device.
  Verified with What-If sign-in for a pilot user → policy applies.

- **Monitoring / AVD Insights on** — diagnostic settings stream from the **host pool**,
  **application group**, and **workspace** to `log-avd-lab-sec`. AVD **Insights** workbook is
  enabled and **populated** (connections, host performance, FSLogix profile-load timings visible
  within ~15 min of first logon). Host data collection (perf counters + events) confirmed flowing.

## 5. Go-Live & cutover (waves)

No big-bang. Five reversible waves, lowest-risk first. **LOB CRM and Finance Suite stay available
on both estates throughout** — legacy RDS/Citrix remains the fallback until a wave is signed off.
Validation gates map to B.4.1 test cases.

| Wave | Persona(s) | Entry criteria | Validation gate (→ B.4.1) | Comms |
| --- | --- | --- | --- | --- |
| 1 | Knowledge-worker pilot subset (~25 of 700) | Pilot "go" from B.2.3; baseline §4 green; `grp-avd-lab-pilot` populated | Logon <30 s at peak; FSLogix container mounts; M365/Edge/Teams + LOB CRM verified; no P1 for 5 business days | T-5d email + lunch-and-learn; quick-start card; dedicated Teams support channel |
| 2 | Call centre (200) | Wave 1 signed off; scaling plan schedule validated against shift pattern (90% peak) | Schedule scales hosts ahead of shift; CRM/Teams/Edge OK; concurrency holds at 90% with no capacity errors | T-5d shift-manager brief; per-shift floor-walkers day 1; rollback hotline |
| 3 | Knowledge workers bulk (remaining ~675) | Wave 1 & 2 signed off; capacity model validated at 70% concurrency; host count scaled per HLD | Profile roams cleanly (5 GB); logon time held <30 s; CRM latency within SLA across full load | T-10d + T-2d staged emails by department; manager toolkit; FAQ |
| 4 | Power users (60, Personal) | KW waves stable; personal host pool + memory-optimised hosts provisioned; 15 GB profiles sized | Finance Suite + Excel add-ins + Power BI validated; **Finance Suite zero downtime** confirmed; per-user personal host assignment works | 1:1 scheduling with Finance; named owner per desk; change-freeze window respected |
| 5 | Developers (40, Personal) | All prior waves signed off; nested-virtualisation SKU + premium disk + admin-rights policy in place | Docker/nested virt runs; IDEs/Git build green; 30 GB profile + premium disk performance OK; admin elevation works | Dev-guild session; self-service runbook; opt-in scheduling |

## 6. Rollback

Every wave is reversible to the legacy estate (RDS / Citrix VAD). Because users are routed by
**Conditional Access + app-group assignment**, rolling a wave back does **not** require destroying
infrastructure — you simply stop routing those users to AVD so they land back on RDS/Citrix.

### Trigger conditions

- Any P1 incident (CRM or Finance Suite unavailable / data risk).
- Logon time regresses beyond the legacy 60–90 s baseline, or FSLogix profile corruption recurs.
- Capacity / scaling failure preventing a persona group from working at peak.
- Validation gate for the wave not met within its bake period.

### Per-wave fallback steps (reverse the routing)

1. **Announce** on the wave comms channel: rollback in progress, use legacy desktop.
2. **Reduce AVD exposure** — remove the wave's group from the `ag-avd-lab-sec` application-group
   assignment (or set the host pool to **drain mode** to stop new sessions).
3. **Reverse Conditional Access** — remove the wave's group from `CA-AVD-Pilot-MFA` targeting so
   the AVD app is no longer the sign-in path for them.
4. **Re-point users to legacy** — confirm their RDS collection / Citrix delivery group still
   publishes the CRM/Finance/desktop resources (legacy kept warm until sign-off, so this is a
   no-op re-enable, not a rebuild).
5. **Validate fallback** — test logon on RDS/Citrix; confirm CRM and Finance Suite reachable.
6. **Record** the trigger, blast radius, and fix-forward plan; re-attempt the wave after remediation.

> Coexistence is the safety net: legacy RDS (~12 RDSH) and Citrix VAD (~8 VDAs) are **not
> decommissioned** until a wave is signed off, so fallback is always available within minutes.

### Lab teardown (do this at the end — leaving resources running costs money)

```text
# Preview what would be removed (tag-guarded):
pwsh ./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -WhatIf

# Tear down the lab resources:
pwsh ./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec

# Also remove the budget guardrail when fully finished:
pwsh ./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec -RemoveBudget
```

The reset script only deletes resources tagged `workload=avd-microhack` + `env=lab`, so it cannot
touch anything outside the lab footprint.

**Handoff:** report status to `avd-engagement-lead`; the live lab environment goes to
`avd-test-engineer` for B.4.1 validation.
