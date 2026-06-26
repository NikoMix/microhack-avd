---
marp: true
theme: microhack
paginate: true
footer: "AVD Module B MicroHack · The Agentic Engagement"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# AVD Module B MicroHack

## The Agentic Engagement

A 1-day, classroom-led **Train-the-Trainer** lab — deliver every Azure Virtual Desktop
Advanced Specialization **Module B** control with GitHub Copilot **agents, skills, and MCP**.

> Migrate **Contoso** (~1,000 RDS/Citrix users) to AVD — discovery → handover — on real Azure.

---

## Today in one sentence

You take a single fictitious customer, **Contoso**, from **legacy VDI to Azure Virtual
Desktop** across **8 challenges**, and at each step a purpose-built **Copilot agent** does the
heavy lifting while **you** apply the consulting judgement.

- Eight challenges, one continuous engagement (C00 → C07).
- Every challenge maps to a **Module B control** and yields one **audit evidence artifact**.
- Real Azure, real Bicep **and** Terraform — deployed at a tiny, cost-safe token scale.

---

## Why this MicroHack exists

- **Module B** is the *consulting engagement lifecycle* a Microsoft auditor inspects for the
  **AVD Advanced Specialization** — assessment, design, review, pilot, deploy, validate, hand over.
- Partners win the specialization by **proving** they ran that lifecycle and produced evidence.
- Here we run it **end to end, accelerated by AI tooling** — so you can re-deliver it for *your*
  customers, faster and more consistently.

> The destination is the same audit evidence; the vehicle is agentic.

---

## Train-the-Trainer

You are learning **two things at once**:

1. **The content** — how to deliver an AVD Module B engagement to audit standard.
2. **The delivery** — how to *facilitate* this MicroHack for your own customers and colleagues.

Throughout the day, watch for the **Trainer cue** slides — they call out what to demo live, the
common pitfalls, and the go/no-go gate for each challenge.

---

## The customer — Contoso

- **~1,000 users** on an ageing on-prem estate: **Microsoft RDS** + **Citrix** across two
  datacentres, single AD forest `contoso.local` synced to Entra ID.
- Pain: **slow/unreliable logons** (60–90 s, profile corruption), **cost & licensing**
  (Citrix renewal + hardware refresh), **remote experience**, **two VDI stacks to operate**.
- Goal: migrate to **AVD** — no big-bang, wave-based, reversible — target region
  **Sweden Central**, modernise identity (Entra join + Intune + Conditional Access).

---

## Contoso personas — the 1,000

| Persona | Users | Pool type | OS |
|---|---|---|---|
| Knowledge workers | **700** | Pooled multi-session | Win 11 Enterprise multi-session |
| Call centre | **200** | Pooled multi-session | Win 11 Enterprise multi-session |
| Power users | **60** | Personal | Win 11 Enterprise |
| Developers | **40** | Personal | Win 11 Enterprise |
| **Total** | **1,000** | — | — |

> Source: [`scenario/personas.csv`](../scenario/personas.csv). Use these numbers everywhere.

---

## The engagement arc

```text
C00 ▸ C01 ▸ C02 ▸ C03 ▸ C04 ▸ C05 ▸ C06 ▸ C07
Setup  Assess  HLD   WAF   Pilot Deploy Validate Handover
```

- **Assess & Design** — C01 Assessment → C02 HLD → C03 Well-Architected review.
- **Prove** — C04 PoC / Pilot with quantitative success criteria.
- **Build & Run on Azure** — C05 Deploy → C06 Validate → C07 Handover.

Each phase **feeds the next**: one consistent chain of personas, numbers and names.

---

## Module B controls and evidence

| # | Challenge | Control | Lead agent | Evidence |
|---|---|---|---|---|
| 00 | Setup & guardrails | — | `avd-engagement-lead` | Env + cost cap |
| 01 | Workload assessment | B.1.1 | `avd-assessor` | `assessment.md` |
| 02 | Solution design (HLD) | B.2.1 | `avd-architect` | `hld.md` |
| 03 | Well-Architected review | B.2.2 | `avd-waf-reviewer` | `waf-review.md` |
| 04 | PoC / Pilot | B.2.3 | `avd-pilot-lead` | `pilot.md` |
| 05 | Deploy to production | B.3.1 | `avd-deployment-engineer` | `deployment.md` |
| 06 | Service validation | B.4.1 | `avd-test-engineer` | `validation.md` |
| 07 | Handover documentation | B.4.2 | `avd-handover-writer` | LLD + runbook + sign-off |

---

## The agentic toolkit

Three Copilot capabilities do the heavy lifting — learn to **route work to the right one**.

- **Custom agents** — 8 AVD specialists (one engagement lead + one per control).
- **Skills** — auto-activating AVD knowledge modules (FSLogix, sizing, WAF lens, cost…).
- **MCP servers** — live tools and authoritative docs (GitHub, **Azure**, Microsoft Learn,
  Terraform Registry).

> Lead with the agent, then show the manual path. **That contrast is the lesson.**

---

## Custom agents

| Agent | Role |
|---|---|
| `avd-engagement-lead` | Orchestrator — plans, routes phases, tracks evidence, guards cost |
| `avd-assessor` | Workload assessment (B.1.1) |
| `avd-architect` | High-Level Design (B.2.1) |
| `avd-waf-reviewer` | Well-Architected review (B.2.2) |
| `avd-pilot-lead` | PoC / Pilot (B.2.3) |
| `avd-deployment-engineer` | Production deploy (B.3.1) |
| `avd-test-engineer` | Service validation (B.4.1) |
| `avd-handover-writer` | Handover pack (B.4.2) |

> Defined in [`.github/agents/`](../.github/agents/). Start with the lead and let it hand off.

---

## Skills

Reusable, **auto-activating** knowledge — the agent pulls them in when the topic comes up.

- `avd-personas-sizing` — density math, VM families, host counts, FSLogix IOPS.
- `avd-fslogix` — profile containers on Azure Files Premium + Entra Kerberos.
- `avd-landing-zone` — AVM-first reference architecture.
- `avd-waf-lens` — Well-Architected checklist through an AVD lens.
- `avd-cost-guardrails` · `avd-migration-cutover` · `avd-evidence-pack`.

> Defined in [`.github/skills/`](../.github/skills/). They make numbers **defensible**, not guessed.

---

## MCP servers

Model Context Protocol servers give the agents **live tools and grounded docs**.

| Server | What it brings |
|---|---|
| `github` | Issues / PRs / repo as the engagement task board |
| `azure` | Live Azure resources, deployment, **cost**, quota (Azure MCP) |
| `microsoft-learn` | Authoritative Microsoft / AVD documentation |
| `terraform` | Terraform Registry module + provider lookup |

> Configured in [`.vscode/mcp.json`](../.vscode/mcp.json). Prefer **grounding in `microsoft-learn`**
> over recalling from memory; use **`azure`** rather than guessing resource state.

---

## How a challenge runs

1. **Adopt the lead agent** to orchestrate — or jump to the challenge's specialist.
2. **Do it the agentic way** — the agent drafts using its skills + MCP tools.
3. **Apply judgement** — *you* verify, quantify, and decide. The agent is a co-pilot, not autopilot.
4. **Produce the evidence** — copy the matching `avd-evidence-pack` template into `work/`.
5. **Pass the gate** — check the artifact against its **Definition of done** before moving on.

> Grade artifacts live with the [`/review-evidence`](../.github/prompts/review-evidence.prompt.md)
> prompt — it models the auditor mindset.

---

<!-- _class: gate -->

## Guardrails first

This is a **paid** Azure subscription. **Cost safety outranks speed.**

- **Budget + alerts** and **auto-shutdown** deploy in C00, before any session host exists.
- **Small SKUs, 1–2 hosts.** Contoso's 1,000-user footprint is a **paper design**.
- **`what-if` / `plan` before every apply.** Read the cost shape back.
- **Tear down** with `scripts/reset/` ([`scripts/`](../scripts/)) — every challenge reminds you.

> If anyone is about to deploy without a budget — **stop them.**

---

## Run of day

| Time | Block | Control |
|---|---|---|
| 09:00 | Welcome + plenary (this deck) | — |
| 09:30 | C00 Setup & guardrails | — |
| 10:15 | C01 Workload assessment | B.1.1 |
| 11:30 | C02 Solution design (HLD) | B.2.1 |
| 13:15 | C03 Well-Architected review | B.2.2 |
| 14:00 | C04 PoC / Pilot | B.2.3 |
| 15:00 | C05 Deploy to production | B.3.1 |
| 16:15 | C06 Service validation | B.4.1 |
| 17:00 | C07 Handover documentation | B.4.2 |

> Breaks 11:15 + 14:45, lunch 12:30. Full timetable in [`facilitator/run-of-day.md`](../facilitator/run-of-day.md).

---

## C00 — Setup & guardrails

**Now:** stand up the lab and the cost cap so the day can never surprise you.

- Open **GitHub Codespaces** (everything pre-installed) — start the build *now*.
- `az login` to **your own** Azure subscription; confirm the right one.
- Confirm the **eight `avd-*` agents**, the skills, and the **four MCP servers** are live.
- Check vCPU quota in **Sweden Central**, then deploy the **budget + auto-shutdown**.

> Detail: [`challenges/challenge-00-setup/`](../challenges/challenge-00-setup/).

---

## Ground rules

- **OSS / license-free only** — no paid vendor licences to run this lab.
- **You own the cloud cost** — labs deploy into *your* subscription; guardrails included,
  **teardown is your responsibility**.
- **Contoso is fictitious** — personas, apps and numbers are invented; never commit secrets,
  real tenant IDs, or customer data.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## Let's begin

### Start your Codespace, then open Challenge 00

Next deck → **01 · Workload assessment (B.1.1)** with `avd-assessor`.

> Trainers: the full facilitation guide is in [`facilitator/`](../facilitator/README.md).
