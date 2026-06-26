<!-- TEMPLATE — copy to challenges/challenge-01-assessment/work/assessment.md and fill in.
     Control B.1.1 Workload Assessment. Numbers must reconcile with scenario/. -->
# Contoso AVD — Workload Assessment (B.1.1)

> Author · Date · Version

## 1. Engagement context
<!-- One paragraph: who Contoso is, current RDS/Citrix estate, why AVD, scope. -->

## 2. Personas

| Persona | Users | Peak concurrency | Work pattern | Key apps | Pool type | Why |
|---|---|---|---|---|---|---|
| Knowledge workers |  |  |  |  | Pooled multi-session |  |
| Call centre |  |  |  |  | Pooled multi-session |  |
| Power users |  |  |  |  | Personal |  |
| Developers |  |  |  |  | Personal |  |

## 3. Application inventory & delivery decisions

| App | Persona(s) | Delivery (image / MSIX app attach / per-user / RemoteApp / SaaS / on-prem) | Rationale | Migration risk |
|---|---|---|---|---|
|  |  |  |  |  |

## 4. Image strategy
<!-- Base image, language/region, optimisations (VDOT), build pipeline (Azure Image Builder),
     versioning + ownership. -->

## 5. Sizing & density (show the math)

| Persona | VM family/SKU | vCPU/RAM per user | Users/host | Peak concurrency | Hosts (incl. N+1) | Profile size | Storage IOPS |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

> Density derivation: <!-- reference avd-personas-sizing rules + microsoft-learn guidance -->

## 6. Discovery method
<!-- How MAP Toolkit / Azure Migrate / Citrix Director data maps to the above; what to collect
     in a real engagement; assumptions made where data is missing. -->

## 7. Assumptions & open questions
