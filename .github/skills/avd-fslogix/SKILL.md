---
name: avd-fslogix
description: FSLogix profile container design and configuration on Azure Files Premium with Entra Kerberos for Azure Virtual Desktop. Use when designing or troubleshooting user profiles — share sizing, authentication, registry settings, redirections, Cloud Cache, and the ANF threshold.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# FSLogix on Azure Files Premium

Use when designing or troubleshooting AVD profiles. Default: **FSLogix profile containers on
Azure Files Premium with Entra Kerberos**. Move to **Azure NetApp Files** only > ~1,000 users or
when latency demands it. Ground specifics in the **`microsoft-learn` MCP** (FSLogix + Azure
Files identity-based access).

## Design checklist

- **Share tier:** Premium (SSD); provision size for **peak-logon IOPS**, not total users.
- **Auth:** Entra Kerberos (Entra-joined hosts) or AD DS Kerberos (hybrid). Set storage account
  identity-based access + correct RBAC (`Storage File Data SMB Share Contributor`) **and** NTFS
  ACLs on the share.
- **Network:** private endpoint for the storage account; no public access.
- **Redundancy:** ZRS for resilience; enable **share snapshots / backup**; test restore.

## Core registry / config

| Setting | Value | Why |
|---|---|---|
| `Enabled` | 1 | Turn FSLogix on |
| `VHDLocations` | `\\<storage>.file.core.windows.net\<share>` | Profile share path |
| `VolumeType` | VHDX | Preferred container format |
| `SizeInMBs` | persona-based | Cap profile growth |
| `FlipFlopProfileDirectoryName` | 1 | Friendly folder names |
| `DeleteLocalProfileWhenVHDShouldApply` | 1 | Avoid local/temp profile conflicts |

- **Exclusions/redirections:** redirect Teams/OneDrive caches appropriately;
  `redirections.xml` for known bloat; consider OneDrive KFM.
- **Cloud Cache:** only for multi-region resilience/active-active — it adds cost/complexity;
  justify before enabling.

## Troubleshooting

- **Temp profile** → permissions (RBAC + NTFS), Kerberos ticket, or share path/DNS.
- **Slow logon** → storage IOPS at peak (right tier?), profile bloat, AV scanning the VHDX,
  network latency to the share.
- **Profile won't attach** → another host holds the lock, container corruption, size limit hit.
- Validate integrity by roaming a profile across hosts and confirming data + settings persist
  (this is a B.4.1 validation test).
