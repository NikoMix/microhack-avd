# Contoso — current state (legacy VDI estate)

## Estate summary

- **~1,000 users**, two datacentres (DC-North primary, DC-South DR), single Active Directory
  forest `contoso.local`.
- **Microsoft RDS farm** — ~12 RD Session Hosts (Windows Server 2019), RD Gateway + RD Web,
  serving knowledge workers and the call centre with published desktops and a few RemoteApps.
- **Citrix Virtual Apps & Desktops 7.x** — ~8 VDAs for power users and developers (published
  desktops + published apps), Citrix MCS golden images, StoreFront + NetScaler Gateway.
- **Profiles** — Citrix UPM and roaming profiles on an ageing file server; frequent profile
  corruption and slow logons (60–90 s at peak).
- **Hardware** — hosts on 5-year-old servers, out of warranty next year. SAN nearing capacity.

## Identity & endpoints

- On-prem **AD DS** (`contoso.local`) synced to **Entra ID** via Entra Connect.
- Microsoft 365 E3 for most users; a subset on E5. Intune is deployed but only lightly used.
- Endpoints: mostly corporate Windows laptops; call centre uses shared thin clients; a growing
  number of users want BYOD/remote access.

## Network

- MPLS between datacentres; ~1 Gbps internet at DC-North.
- ExpressRoute **not** yet provisioned (a migration decision point).
- Legacy remote access via Citrix NetScaler and RD Gateway; no modern Conditional Access on VDI.

## Applications (high level)

- Standard productivity: Microsoft 365 apps, Edge, Teams.
- **LOB CRM** (call centre + knowledge workers) — a Windows desktop app with a SQL back end.
- **Finance suite** (power users) — heavy, latency-sensitive, some Excel add-ins.
- **Developer toolchain** (developers) — IDEs, local containers/VMs, admin rights, large repos.
- A handful of **legacy apps** with old runtimes / peripheral (scanner, smartcard) dependencies.

See `app-inventory.csv` for the per-application detail.

## Pain points (drivers for AVD)

1. **Cost & licensing** — Citrix renewal + hardware refresh + datacentre overhead.
2. **Slow, unreliable logons** — profile corruption, logon storms each morning.
3. **Remote experience** — gateway capacity and latency complaints from remote staff.
4. **Operational burden** — two VDI stacks (RDS + Citrix), manual image management.
5. **Security** — no Conditional Access / MFA on VDI; flat network access.

## Goals & constraints

- Migrate to **AVD** with **no big-bang** — wave-based, reversible, coexistence with legacy.
- **Reduce run cost** via autoscale and right-sizing.
- **Modernise identity** — Entra join + Intune + Conditional Access where feasible.
- Keep the **LOB CRM and Finance suite** working throughout (these cannot have downtime).
- Target region: **Sweden Central** (closest to the user base).
