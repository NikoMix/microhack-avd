# Contoso AVD — Operations Runbook (B.4.2)

> Owner: Contoso Cloud Operations · Date: 2026-06-27 · Version: 1.0

Scope: day-2 operation of host pool `hp-avd-lab-sec` in `rg-avd-lab-sec` (swedencentral).
Prereqs: `az login`, the `desktopvirtualization` extension, and membership of `grp-avd-lab-admins`.

```powershell
az account set --subscription "<sub-id>"
$RG = "rg-avd-lab-sec"; $HP = "hp-avd-lab-sec"
```

## Routine operations

| Operation | Steps / command | Notes |
| --- | --- | --- |
| Add a session host | Deploy a new host via IaC then register it. Preferred path is IaC: bump `hostCount` and re-run `az deployment group create -g $RG -f infra/bicep/main.bicep -p infra/bicep/main.bicepparam --what-if` then without `--what-if`. Manual path: `az desktopvirtualization hostpool update -g $RG -n $HP --registration-info expiration-time=(Get-Date).AddHours(8).ToString('o') registration-token-operation=Update`, then run the AVD agent bootloader on the new VM with that token. | Always preview with `--what-if`. New host inherits the golden image and FSLogix registry. Verify it shows `Available` in `az desktopvirtualization session-host list -g $RG --host-pool-name $HP -o table`. |
| Remove / drain a host | 1. Drain: `az desktopvirtualization session-host update -g $RG --host-pool-name $HP -n vmavdlab1.contoso.local --allow-new-session false`. 2. Notify + log off users: `az desktopvirtualization user-session list -g $RG --host-pool-name $HP --session-host-name vmavdlab1.contoso.local -o table` then `... user-session disconnect/send-message`. 3. Remove registration: `az desktopvirtualization session-host delete -g $RG --host-pool-name $HP -n vmavdlab1.contoso.local`. 4. Delete VM via IaC (reduce `hostCount`). | Never delete a VM that still has active sessions. Drain first, confirm zero sessions. |
| Update golden image & roll out | 1. Build/patch image, capture to Azure Compute Gallery, publish new version. 2. Update `image`/gallery version param in `main.bicepparam`. 3. Stand up **new** hosts on the new image (blue/green), drain old hosts, remove them. | Use blue/green, not in-place. Validate logon + LOB CRM on one new host before draining old hosts. |
| Change scaling-plan schedule | `az desktopvirtualization scaling-plan update -g $RG -n sp-avd-lab-sec` then edit the pooled schedule (ramp-up/peak/ramp-down/off-peak times, capacity threshold). Preview via IaC `--what-if`. | Keep **drain on shutdown** enabled. Change ramp-up capacity threshold (currently 60%) to tune cost vs. headroom. |
| Resize / right-size | Drain host, stop VM, then `az vm resize -g $RG -n vmavdlab0 --size Standard_D8as_v5`, start, re-enable sessions. Re-evaluate `maxSessionLimit` on the host pool. | Validate against logon P95 ≤ 30 s after resize. Update LLD §1 + IaC params. |
| Patch hosts | Managed by Intune update rings (Entra-joined). For ad-hoc: drain host → `az vm run-command invoke -g $RG -n vmavdlab0 --command-id RunPowerShellScript --scripts "Install-Module PSWindowsUpdate -Force; Install-WindowsUpdate -AcceptAll -AutoReboot"` → re-enable sessions. | Stagger across `vmavdlab0`/`vmavdlab1` to keep 1 host serving. Reboots release FSLogix VHD locks. |

## FSLogix troubleshooting

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Temporary profile (`TEMP` on desktop) | VHD failed to attach; storage perms/Kerberos issue | Check `Microsoft-FSLogix-Apps/Operational` event log. Verify Entra Kerberos: `klist` shows ticket for `stavdlabsec001`. Confirm share RBAC + NTFS ACLs. Ensure `DeleteLocalProfileWhenVHDShouldApply=1`. Reboot host to clear stale local profile. |
| Slow logon (> 30 s) | Large profile, redirected-but-bloated folders, storage throttling | Check profile size vs `SizeInMBs=30000`. Review Premium share IOPS/throughput; confirm host + storage in **swedencentral** (no cross-region). Exclude AV-scanned VHD paths. Trim cached Teams/OneDrive. |
| VHD won't attach / "in use" | Stale lock from an ungraceful logoff on another host | Confirm no active session elsewhere: `az desktopvirtualization user-session list ...`. Reboot the holding host to release the SMB lock. Validate single-VHD roaming after. |

## Incident playbook

| Symptom | Likely cause | First response | Escalate if |
| --- | --- | --- | --- |
| Slow logons across users | Storage throttling, image regression, or DC/Kerberos latency | Check `log-avd-lab-sec` logon-duration P95; confirm both hosts `Available`; check FSLogix events | P95 > 30 s sustained 30 min after first response → L2; storage/Kerberos root cause → Microsoft |
| Users can't connect | start-VM-on-connect off / hosts deallocated, CA blocking, or agent unhealthy | Verify hosts running + `Available`; check `CA-AVD-Require-MFA` sign-in logs; restart AVD agent/bootloader | Agent unhealthy after restart, or service health event → Microsoft |
| App fails to launch (CRM) | Smartcard middleware, SQL connectivity, or redirection policy | Confirm smartcard redirection in RDP props; test SQL reachability from host; check app event log | CRM down for all users > 15 min → L2 + app owner |

## Backup & restore

- **Mechanism:** Azure Files **share snapshots** on `stavdlabsec001/profiles`.
- **Create snapshot:**

  ```powershell
  az storage share snapshot --account-name stavdlabsec001 --name profiles --auth-mode login
  ```

- **List / restore a profile:** browse the snapshot via
  `\\stavdlabsec001.file.core.windows.net\profiles\?snapshot=<timestamp>`, copy the user's VHDX folder
  back into the live share while the user is logged off.
- **Cadence:** daily automated snapshots (retain 7 daily / 4 weekly). **Test restore quarterly** —
  restore one test profile end-to-end and confirm clean roam.

## Monitoring & alerts

- **Dashboards:** AVD Insights workbook on `log-avd-lab-sec` (connection diagnostics, host performance,
  logon duration, available sessions).
- **Alert rules + response:**

  | Alert | Threshold | Who responds | Action |
  | --- | --- | --- | --- |
  | Slow logon | P95 > 30 s | L1 Ops | Triage per incident playbook (storage/image/Kerberos) |
  | Host CPU pressure | > 85% for 10 min | L1 Ops | Confirm scaling ramp; add/resize host if sustained |
  | Available sessions low | below floor | L1 Ops | Verify scaling plan ran; add host if peak demand |
  | Budget | 50/80/100% of 50 USD | Engagement owner | Review spend; confirm auto-shutdown working |
