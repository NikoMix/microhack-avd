# Challenge 03 — Well-Architected review

> **Module B control:** B.2.2 — Well-Architected Review · **Time-box:** 45 min ·
> **Lead agent:** `avd-waf-reviewer` · **Evidence:** `work/waf-review.md`

## Objective

Pressure-test the B.2.1 HLD against the **Azure Well-Architected Framework** through an **AVD
lens** — leading with **Cost, Performance Efficiency, and Reliability** — and turn every weakness
into a prioritised, owned finding with an explicit decision (fix now or accept-and-record).

## Prerequisites

- Completed [Challenge 02](../challenge-02-solution-design/) — `work/hld.md`.
- The [`avd-waf-lens`](../../.github/skills/avd-waf-lens/SKILL.md) checklist to hand.

## The agentic way (do this first)

1. **Agent:** adopt [`avd-waf-reviewer`](../../.github/agents/avd-waf-reviewer.agent.md) — ask it
   to *"review `work/hld.md` against the WAF AVD lens, lead with Cost/Performance/Reliability, and
   produce a findings table plus a decision register."*
2. **Skill:** it draws on [`avd-waf-lens`](../../.github/skills/avd-waf-lens/SKILL.md) (per-pillar
   AVD-specific probes) and [`avd-cost-guardrails`](../../.github/skills/avd-cost-guardrails/SKILL.md)
   (cost posture).
3. **MCP:** **`microsoft-learn`** (search *"Well-Architected Framework Azure Virtual Desktop"*) to
   ground each pillar; **`github`** to log findings as issues if you want them tracked.

> Let the agent surface candidate findings, then **you** assign risk, pick the owner, and force the
> fix-now-vs-accept decision. A finding with no decision is not done.

## Steps

### 1. Walk the five pillars (AVD-specific, not generic)

Probe each pillar against the HLD using the lens. At minimum:

- **Cost** — autoscale aggressiveness, SKU right-sizing per persona, Files Premium vs Standard
  justified by IOPS, reserved vs pay-go for the steady personal hosts, Log Analytics ingestion.
- **Performance** — density vs the morning logon storm, FSLogix peak-logon IOPS, RDP Shortpath,
  image optimisation (VDOT), profile bloat, user/region proximity.
- **Reliability** — zonal/host-pool resilience, profile storage redundancy (ZRS) **and** backup,
  scaling-plan failure modes, image pipeline as a single point of failure, realistic RTO/RPO.
- **Security** — Entra/Conditional Access/MFA, private endpoints, RBAC least privilege,
  clipboard/drive/screen-capture policy, golden-image patch cadence.
- **Operations** — AVD Insights coverage, alerts on logon time/host health, IaC drift, patch
  cadence, runbooks.

### 2. Log every gap as a finding

Each finding gets: `ID | Pillar | Finding | Risk (H/M/L) | Recommendation | HLD §ref | Owner`.
Recommendations must reference a **specific HLD section** — actionable, not "consider improving
reliability".

### 3. Force a decision per finding

In the **decision register**, record for each finding: **fix now** (change the HLD) or **accept the
risk** (and why), plus the resulting HLD change. Prioritise so the learner knows what must be fixed
**before** the pilot.

### 4. Produce the evidence artifact

```bash
mkdir -p work
cp ../../.github/skills/avd-evidence-pack/templates/waf-review.md work/waf-review.md
```

Complete every section of
[`templates/waf-review.md`](../../.github/skills/avd-evidence-pack/templates/waf-review.md).

## Definition of done (acceptance criteria)

- [ ] `work/waf-review.md` exists and follows the template.
- [ ] **All five pillars** covered; **Cost, Performance, Reliability** each have at least one real,
      AVD-specific finding (not generic advice).
- [ ] Every finding has **risk + recommendation + owner** and references a specific **HLD section**.
- [ ] **Every finding has a decision** (fix now / accept) in the decision register, with
      justification and the HLD change.
- [ ] Findings that must be retired are flagged for the **pilot** (feeds Challenge 04).
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md)
      prompt (or by `avd-waf-reviewer`) → **PASS**.

## Stretch goals

- Quantify the **Cost** findings (e.g. estimated monthly delta of moving the call-centre pool to a
  tighter shift-based ramp) using the `azure` MCP retail-pricing tooling.
- Map each **fix-now** finding to the exact `infra/` parameter it changes.

<details>
<summary>Trainer notes</summary>

- **Timing:** ~25 min pillar walk, ~15 min findings + decisions, ~5 min prioritisation. Keep it to
  ~5–8 strong findings, not 30 weak ones.
- **Common pitfalls:** generic findings with no HLD reference; no owner; no decision; ignoring
  Cost because "it's a lab"; forgetting profile-storage backup (a classic AVD reliability gap).
- **Talking points:** the review exists to **de-risk the pilot and production** — every fix-now
  finding should change the HLD before any host is built. This is where consulting judgement shows.
- **Solution key:** [`solutions/challenge-03/`](../../solutions/challenge-03/).

</details>

## What's next

→ [Challenge 04 — PoC / Pilot](../challenge-04-poc-pilot/) (B.2.3).
