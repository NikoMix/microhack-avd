<!-- SOLUTION KEY (trainer reference) — control B.1.1 Workload Assessment.
     A worked, internally consistent example. Not the only correct answer.
     All numbers reconcile with scenario/ (700 + 200 + 60 + 40 = 1000). -->
# Contoso AVD — Workload Assessment (B.1.1)

> Author: AVD Engagement Team · Date: 2026-06-27 · Version: 1.0 (worked solution)

## 1. Engagement context

**Contoso Ltd.** runs ~1,000 users on an ageing on-premises VDI estate — a mix of **Microsoft
RDS** (~12 RD Session Hosts, RD Gateway/Web) and **Citrix Virtual Apps & Desktops 7.x** (~8 VDAs,
StoreFront/NetScaler) across two datacentres, on a single AD forest `contoso.local`. The estate is
out of warranty next year, Citrix renewal looms, profiles corrupt and morning logons take 60–90 s,
and remote-access demand has outgrown the gateways. Contoso is migrating to **Azure Virtual
Desktop** in **Sweden Central** to cut cost, modernise identity, and improve the remote experience
— **wave-based, reversible, no big-bang**, with the LOB CRM and Finance suite available throughout.
This assessment (control **B.1.1**) classifies the population into personas, decides delivery for
every application, sets the image strategy, and sizes the hosts and profile storage with the math
shown — it is the contract the B.2.1 design inherits.

## 2. Personas

Peak concurrency count = users × peak-concurrency % (from `scenario/personas.csv`).

| Persona | Users | Peak concurrency | Work pattern | Key apps | Pool type | Why |
|---|---|---|---|---|---|---|
| Knowledge workers | 700 | **490** (70%) | Office hours, hybrid remote, morning logon storm | M365 apps, Edge, Teams, LOB CRM | Pooled multi-session | Largest, standardised app set; shared hosts are most cost-efficient at scale |
| Call centre | 200 | **180** (90%) | Shift-based, high concurrency, predictable hours, shared thin clients | LOB CRM, Teams, Edge | Pooled multi-session | High density, light apps; ideal for shift-based autoscale |
| Power users | 60 | **48** (80%) | Office hours, heavy spreadsheets/BI, latency sensitive | Finance suite, Excel add-ins, Power BI, M365 | Personal | Heavy single-user workloads + persistent state; memory-optimised, dedicated |
| Developers | 40 | **30** (75%) | Flexible hours, admin rights, local containers/VMs, large repos | IDEs, Docker, Git, Azure tools, M365 | Personal | Admin rights + custom installs + nested virtualization; cannot share a host |
| **Total** | **1000** | **748** | | | | |

**Pool-type logic** (`avd-personas-sizing`): standardised app set + shared hosts acceptable +
cost-efficiency at scale → **pooled multi-session** (knowledge workers, call centre). Persistent
state / admin rights / heavy single-user or nested-virt workloads → **personal** (power users,
developers). All pooled hosts run **Windows 11 Enterprise multi-session**; personal hosts run
**Windows 11 Enterprise**.

## 3. Application inventory & delivery decisions

From `scenario/app-inventory.csv`, with rationale and migration risk.

| App | Persona(s) | Delivery | Rationale | Migration risk |
|---|---|---|---|---|
| Microsoft 365 Apps | All | Install to image (shared activation) | Standard across all personas; shared activation suits multi-session | Low |
| Microsoft Teams | All | Install to image (AVD media optimization) | Enable AVD media optimization so A/V offloads to the client | Low — validate optimization on multi-session |
| Microsoft Edge | All | Install to image | Default browser; no special handling | Low |
| LOB CRM | Knowledge workers, Call centre | Install to image | Critical; must stay available throughout migration | **High** — SQL back end + **smartcard** login; test smartcard redirection |
| Finance Suite | Power users | Install to image (personal pool) | Heavy, latency-sensitive; keep close to data on a dedicated host | **High** — Excel add-in performance; validate vs current Citrix |
| Power BI Desktop | Power users | Install to image | Personal pool; rendering benefits from more vCPU/RAM | Medium — consider GPU SKU only if rendering is heavy |
| Developer IDE (VS / VS Code) | Developers | Install to image + per-user extensions | Personal pool; admin rights; large disk | Medium — premium disk; per-user extension state |
| Docker / container tooling | Developers | Per-user / personal pool | Needs **nested virtualization** (Docker/WSL2) | **High** — pin an Intel SKU that supports nested virtualization |
| Legacy Scanning App | Knowledge workers (~30) | **RemoteApp** | Niche; isolate from the main image | Medium — **TWAIN scanner redirection** must be validated |
| Legacy Java LOB tool | Knowledge workers (~50) | **MSIX app attach** | Old Java runtime; isolate to avoid image conflicts | Medium — package + runtime compatibility |
| Statutory Reporting Tool | Finance power users (~15) | **Replace with SaaS** (evaluate) | Vendor offers SaaS; removes a published-app dependency | Medium — assess SaaS parity + data residency before committing |
| Print Management | All | Install to image | Printer redirection agent | Medium — validate **Universal Print** as the modern alternative |

> Every app has a decision **and** a reason. The three **High**-risk items (LOB CRM smartcard,
> Finance add-in performance, Docker nested virtualization) are the items the pilot (B.2.3) must
> retire before production.

## 4. Image strategy

- **Base images** — from the Azure Marketplace, kept current:
  - **Multi-session:** *Windows 11 Enterprise multi-session, 24H2 + Microsoft 365 Apps* (knowledge
    workers, call centre).
  - **Personal (power):** *Windows 11 Enterprise 24H2* + Finance suite, Power BI, M365.
  - **Personal (developer):** *Windows 11 Enterprise 24H2* on a nested-virtualization-capable SKU +
    dev toolchain; admin rights granted per host.
- **Language/region** — en-US base with **W. Europe** time zone and Swedish (sv-SE) language/keyboard
  pack layered for the Contoso user base; regional formats set per the locale.
- **Optimisations** — the **Virtual Desktop Optimization Tool (VDOT)** — OSS, MIT-licensed
  (`The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool`) — to disable unneeded
  services/startup tasks, apply Teams optimization, and remove built-in app bloat.
- **Build pipeline** — **Azure Image Builder (AIB)** → **Azure Compute Gallery**, **Trusted
  Launch** enabled, images **versioned** and replicated to Sweden Central. **Monthly** patch +
  rebuild cadence; emergency out-of-band rebuild for critical CVEs.
- **Ownership** — the **platform team** owns the golden images; changes are change-controlled and
  promoted dev → test → prod gallery versions. Detail (AIB customisers, gallery names) lands in the
  B.2.1 HLD.

## 5. Sizing & density (show the math)

**Method** (`avd-personas-sizing` + Microsoft *"session host virtual machine sizing guidelines"*):
density is the **lower** of the vCPU-bound and RAM-bound limit; pooled host count =
`ceil(peak concurrent / users-per-host) + N+1`. Personal pools are 1 VM per assigned user, sized
for the single-user workload. FSLogix storage is sized for **peak-logon IOPS**, not total users.

| Persona | VM family/SKU | vCPU/RAM | Workload class | Users/host | Peak concurrency | Hosts (incl. N+1) | Profile size | Storage / IOPS |
|---|---|---|---|---|---|---|---|---|
| Knowledge workers | `Standard_D16as_v5` | 16 / 64 GiB | Medium | **25** | 490 | **21** (20 + N+1) | 5 GB | FSLogix on Files Premium (shared) |
| Call centre | `Standard_D16as_v5` | 16 / 64 GiB | Light | **30** | 180 | **7** (6 + N+1) | 3 GB | FSLogix on Files Premium (shared) |
| Power users | `Standard_E4as_v5` (memory-opt) | 4 / 32 GiB | Heavy (single-user) | 1 (personal) | 48 running | **60 VMs** (~48 peak) | 15 GB | Persistent local Premium SSD |
| Developers | `Standard_D8s_v5` (Intel, nested-virt) | 8 / 32 GiB | Heavy + nested virt | 1 (personal) | 30 running | **40 VMs** (~30 peak) | 30 GB | Persistent local Premium SSD + data disk |

> **Density derivation (pooled).** On `D16as_v5`, reserve ~8 GiB for OS + agents + FSLogix →
> ~56 GiB usable.
>
> - **Knowledge workers (medium):** RAM-bound at ~2 GiB/user → 56 / 2 = **28**; CPU at medium
>   (4 users/vCPU) = 64 (not binding). Plan **25 users/host** for Teams A/V headroom.
>   Hosts = `ceil(490 / 25)` = 20, **+ N+1** = **21**.
> - **Call centre (light):** RAM-bound at ~1.5 GiB/user → 56 / 1.5 ≈ 37; CPU at light
>   (6 users/vCPU) = 96 (not binding). Plan **30 users/host** (conservative, autoscaled on shifts).
>   Hosts = `ceil(180 / 30)` = 6, **+ N+1** = **7**.
> - **Personal pools:** 1 VM per assigned user → 60 (power) + 40 (dev) = **100 VMs provisioned**;
>   with start-on-connect / deallocate-on-idle only ~78 run at peak (48 + 30), which is what
>   autoscale and reservations should be costed against.
>
> **FSLogix storage (pooled population = 900).** Raw profile data = (5 GB × 700) + (3 GB × 200) =
> 3,500 + 600 = **4,100 GB**. With ~30% growth + VHDX overhead, provision a **Premium SMB share
> ≥ 5 TiB**. Azure Files Premium baseline ≈ **1 IOPS/GiB** → ~5,120 baseline IOPS, **burst ~3×**
> (~15,360 IOPS), >200 MiB/s throughput. Pooled peak-concurrent logons = 490 + 180 = **670** at
> ~10–20 IOPS/user steady (≈ 6,700–13,400 IOPS) → within burst. If the **morning logon storm**
> exceeds burst, **split knowledge-worker and call-centre profiles onto separate shares/storage
> accounts**. **ANF** is only warranted **> ~1,000 pooled users** or when latency demands it — at
> **900** pooled users, **Azure Files Premium is the right call**.

## 6. Discovery method

The sizing above is corroborated against `scenario/map-assessment-sample.csv` (MAP Toolkit / Azure
Migrate / Citrix Director):

- **RD Session Hosts** (knowledge workers / call centre) — e.g. `RDSH-N02` ran **58 concurrent**
  users on **16 vCPU / 64 GB at 88% CPU**, i.e. ~3.6 users/vCPU and ~1.1 GiB/user. The estate is
  **over-subscribed** (hence the slow, storming logons). The AVD plan is deliberately **more
  conservative** (~2 GiB/user, 25 users/host) to deliver a better experience, with **autoscale**
  offsetting the lower static density.
- **Citrix VDAs** (power users) — `CTX-VDA-N01/N02` ran only **16–18 concurrent** on **16 vCPU /
  128 GB at 90–93% CPU** with **memory pressure and latency complaints** → confirms **personal +
  memory-optimised** for power users.
- **Profile file server** — `FS-PROFILES-N` peaked at **95% CPU, SAN IOPS-bound**, and is the named
  source of profile corruption + slow logon → confirms the move to **FSLogix on Azure Files Premium
  sized for logon-storm IOPS**, not capacity.

In a real engagement, collect ≥ 4 weeks of MAP/Azure Migrate counters (CPU, RAM, peak concurrent,
disk IOPS/latency) plus Citrix Director session data, validate persona concurrency against observed
peaks, and confirm app dependencies (smartcard, TWAIN, Java runtime, nested virtualization).

## 7. Assumptions & open questions

- **Assumptions:** peak-concurrency percentages from `personas.csv` are representative of steady
  operations; ~2 GiB/user (KW) and ~1.5 GiB/user (CC) RAM budgets pending pilot validation; no GPU
  required (revisit only if Power BI rendering proves heavy); profiles for personal pools stay
  **local** on the persistent VM disk (FSLogix optional for portability).
- **Open questions:** does the LOB CRM **smartcard** login work over AVD redirection? Will the
  **Finance suite Excel add-ins** meet latency targets on `E4as_v5` (or is `E8as_v5` needed)? Is the
  **statutory reporting SaaS** acceptable for data residency? Confirm **ExpressRoute vs VPN** for
  on-prem dependencies during coexistence (a B.2.1 networking decision). These feed the pilot
  (B.2.3) success criteria.
