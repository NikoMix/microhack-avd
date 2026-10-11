# Contoso AVD — Low-Level Design / As-Built (B.4.2)

> Author: AVD Delivery — Documentation Lead · Date: 2026-06-27 · Deployment / run ID: `avd-lab-sec-20260627-01` (sample)

This Low-Level Design (LLD) records the **as-built** lab footprint, reconciled against the
**deployed** resources in resource group `rg-avd-lab-sec` (Sweden Central) — not the HLD template.
Sample resource IDs and run IDs are clearly marked as examples.

## 1. As-built resource inventory

| Resource | Name | Resource group | Region | SKU/Tier | Key config |
| --- | --- | --- | --- | --- | --- |
| Resource group | `rg-avd-lab-sec` | — | swedencentral | — | Tag-guarded; all required tags applied |
| Virtual network | `vnet-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | — | Address space `10.20.0.0/16` |
| Subnet | `snet-avd-hosts` | `rg-avd-lab-sec` | swedencentral | — | `10.20.1.0/24`, NSG associated |
| Network security group | `nsg-avd-hosts` | `rg-avd-lab-sec` | swedencentral | — | Deny inbound from Internet; reverse-connect outbound only |
| Host pool | `hp-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | Pooled / Breadth-first | RDP Shortpath on; start-VM-on-connect on |
| Application group | `ag-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | Desktop | Assigned to `ws-avd-lab-sec` |
| Workspace | `ws-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | — | Feed for `grp-avd-lab-users` |
| Scaling plan | `sp-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | Pooled | Schedule below; drain on shutdown |
| Session host 0 | `vmavdlab0` | `rg-avd-lab-sec` | swedencentral | Standard_D4as_v5 | 4 vCPU/16 GiB; Trusted Launch; Entra-joined + Intune |
| Session host 1 | `vmavdlab1` | `rg-avd-lab-sec` | swedencentral | Standard_D4as_v5 | 4 vCPU/16 GiB; Trusted Launch; Entra-joined + Intune |
| Storage account | `stavdlabsec001` | `rg-avd-lab-sec` | swedencentral | Premium FileStorage (ZRS) | Azure Files; Entra Kerberos |
| File share | `profiles` | `rg-avd-lab-sec` | swedencentral | 100 GiB | FSLogix VHDX container store |
| Log Analytics workspace | `log-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | Per-GB | AVD Insights data source |
| Budget | `budget-avd-lab-sec` | `rg-avd-lab-sec` | swedencentral | — | 50 USD/month, alerts 50/80/100% |

Required tags on **every** resource:

```text
workload   = avd-microhack
env        = lab
owner      = <consultant-upn>
costCenter = training
autoDelete = true
```

## 2. Network detail

- **Address space:** vNet `vnet-avd-lab-sec` `10.20.0.0/16`.
- **Subnet:** `snet-avd-hosts` `10.20.1.0/24` — hosts receive dynamic IPs (`vmavdlab0` ≈ `10.20.1.4`,
  `vmavdlab1` ≈ `10.20.1.5`; sample, DHCP-assigned).
- **NSG posture (`nsg-avd-hosts`):** default **deny inbound from Internet**; **no inbound RDP (3389)**.
  AVD uses **reverse connect** — hosts make **outbound** TLS 443 to the AVD service (`WindowsVirtualDesktop`
  / `AzureCloud` service tags). RDP Shortpath uses outbound UDP (STUN/3478) where available.
- **Private endpoints / DNS:** lab uses the public Azure Files endpoint
  `stavdlabsec001.file.core.windows.net`; **no private endpoint** in the lab. Production should add a
  Private Endpoint + Private DNS zone `privatelink.file.core.windows.net`.
- **Peerings:** none in the lab (single self-contained vNet). Production peers to hub for on-premises
  `contoso.local` DC reachability.

## 3. Identity & access

- **Directory:** single AD forest `contoso.local` synced to Entra ID; hosts are **Entra-joined** and
  **Intune-enrolled**.
- **Entra groups:**
  - `grp-avd-lab-users` — end users; assigned to application group `ag-avd-lab-sec`.
  - `grp-avd-lab-admins` — operators/admins.
- **RBAC on AVD objects:**

  | Principal | Role | Scope |
  | --- | --- | --- |
  | `grp-avd-lab-users` | Desktop Virtualization User | `ag-avd-lab-sec` |
  | `grp-avd-lab-admins` | Desktop Virtualization Contributor | `rg-avd-lab-sec` |

- **Conditional Access:** policy `CA-AVD-Require-MFA` targets the **Azure Virtual Desktop** app for
  `grp-avd-lab-users` — **require MFA** and **compliant or hybrid-joined device** (pilot posture).

## 4. Profiles / storage

- **Storage account:** `stavdlabsec001` — Premium FileStorage, **ZRS**.
- **Share:** `profiles`, quota **100 GiB**.
- **Authentication:** **Entra Kerberos** (`AzureADKerberos`); share-level RBAC grants
  `grp-avd-lab-users` **Storage File Data SMB Share Contributor**; NTFS ACLs follow FSLogix
  least-privilege.
- **FSLogix registry (both hosts, `HKLM\SOFTWARE\FSLogix\Profiles`):**

  | Value | Data |
  | --- | --- |
  | `Enabled` | `1` |
  | `VHDLocations` | `\\stavdlabsec001.file.core.windows.net\profiles` |
  | `DeleteLocalProfileWhenVHDShouldApply` | `1` |
  | `FlipFlopProfileDirectoryName` | `1` |
  | `SizeInMBs` | `30000` |
  | `VolumeType` | `VHDX` |
  | `ProfileType` | `0` |

## 5. AVD objects

- **Host pool `hp-avd-lab-sec`:** Pooled, **Breadth-first**, **RDP Shortpath** on, **start-VM-on-connect**
  on.
- **RDP properties (custom):** drive + clipboard redirection per policy, **multi-monitor** on.
  Representative string:

  ```text
  drivestoredirect:s:*;redirectclipboard:i:1;use multimon:i:1;audiocapturemode:i:1;camerastoredirect:s:*
  ```

- **Application group `ag-avd-lab-sec`:** type **Desktop**, published to `ws-avd-lab-sec`.
- **Workspace `ws-avd-lab-sec`:** single feed for `grp-avd-lab-users`.
- **Scaling plan `sp-avd-lab-sec`** — pooled, **drain on shutdown**:

  | Phase | Start | Load balancing | Capacity threshold |
  | --- | --- | --- | --- |
  | Ramp-up | 07:00 | Breadth-first | 60% |
  | Peak | 09:00 | Breadth-first | — |
  | Ramp-down | 18:00 | Depth-first | — |
  | Off-peak | 20:00 | Depth-first | — |

## 6. Monitoring

- **Log Analytics workspace:** `log-avd-lab-sec`.
- **AVD Insights:** **on**; host pool / app group / workspace diagnostics stream to `log-avd-lab-sec`.
- **Alert rules:**

  | Alert | Condition | Threshold |
  | --- | --- | --- |
  | Slow logon | Logon duration P95 | `> 30 s` |
  | Host CPU pressure | CPU sustained | `> 85% for 10 min` |
  | Capacity | Available sessions | low / below floor |

## 7. Parameter / tfvars reference

Deployed from **AVM-based** IaC. Preview before apply (`az deployment ... what-if` / `terraform plan`).

- **Bicep:** `infra/bicep` with parameters in `infra/bicep/main.bicepparam`.
- **Terraform:** `infra/terraform`.

Exact parameters used (representative):

```text
location             = swedencentral        # 'sec'
env                  = lab
workload             = avd
vnetAddressSpace     = 10.20.0.0/16
hostSubnetPrefix     = 10.20.1.0/24
hostPoolType         = Pooled
loadBalancerType     = BreadthFirst
hostCount            = 2
vmSize               = Standard_D4as_v5
image                = MicrosoftWindowsDesktop:windows-11:win11-24h2-avd
securityType         = TrustedLaunch
profileStorageSku    = Premium_ZRS
profileShareQuotaGiB = 100
fslogixSizeInMBs     = 30000
budgetAmountUsd      = 50
```

Guardrails: budget `budget-avd-lab-sec` 50 USD/month (50/80/100% alerts); per-VM auto-shutdown
**19:00 'W. Europe Standard Time'**.
