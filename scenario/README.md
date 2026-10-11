# Contoso — scenario data

Everything in this folder is **fictitious** and exists to drive the MicroHack. Use these numbers
everywhere; do not invent different ones unless a challenge explicitly asks for a variation.

## The customer

**Contoso Ltd.** runs **~1,000 users** on an ageing on-premises VDI estate (a mix of **Microsoft
RDS** and **Citrix Virtual Apps & Desktops**) across two datacentres. Hardware refresh is due,
the Citrix licensing renewal is looming, and remote-work demand has outgrown the gateway. Contoso
wants to **migrate to Azure Virtual Desktop** to cut cost, simplify operations, and improve the
remote experience — without a big-bang cutover.

## Files

| File | What it is | Used by |
|---|---|---|
| `current-state.md` | Narrative of the legacy RDS/Citrix estate, identity, network, pain points | C01 (B.1.1) |
| `personas.csv` | The four user personas with counts, patterns, app sets | C01, C02 |
| `app-inventory.csv` | Application estate + current delivery + migration notes | C01 |
| `map-assessment-sample.csv` | Sample MAP Toolkit / Azure Migrate / Citrix Director discovery output | C01 |

## Totals (must reconcile)

| Persona | Users |
|---|---|
| Knowledge workers | 700 |
| Call centre | 200 |
| Power users | 60 |
| Developers | 40 |
| **Total** | **1000** |

> The full 1,000-user footprint is a **paper design**. In the lab you deploy a token slice
> (1–2 session hosts) — see the cost guardrails skill and `scripts/setup/`.
