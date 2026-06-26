# Solution key — Challenge 03 · Well-Architected review (B.2.2)

> ⚠️ **Trainers only.** Reference answer for [Challenge 03](../../challenges/challenge-03-well-architected-review/).
> Learners should attempt it with `avd-waf-reviewer` first.

**Worked artifact:** [`waf-review.md`](waf-review.md) — a WAF review of the C02 HLD through an AVD
lens, leading with Cost / Performance / Reliability.

## Why this answer is defensible

- **Specific, not generic.** Every finding names a **real artefact in the HLD** and cites its
  **section** (e.g. F3 → §2.3 FSLogix, F6 → §2.1 host pools). "Enable MFA" with no reference is the
  anti-pattern; this avoids it.
- **AVD-shaped.** The High findings are the two that actually bite AVD projects — the **FSLogix
  logon storm** (single share vs 490 concurrent KW logons) and the **untested restore**. Density,
  redirection, ingestion cost, zones, and alert thresholds round it out.
- **Ends in decisions.** A decision register turns each finding into **fix-now vs accept-and-
  validate** with a justification and the **exact HLD edit** — so the review changes the design
  instead of just describing it.
- **Feeds the pilot.** Four findings (F3, F4, F5 + the smartcard question) are explicitly handed to
  B.2.3, which is what makes the WAF review *useful* rather than ceremonial.

## Teaching points

- **Lead with the pillars that matter for AVD.** Cost, Performance, Reliability first — Security and
  Operations still covered, but the headline risks in VDI are profile IOPS, recoverability, and run
  cost.
- **A finding without a § reference is unfinished.** Force traceability back to the HLD.
- **"Accept the risk" is a valid, mature answer** — F4 (density) is accepted and validated in the
  pilot rather than over-engineered now. Model that judgement.
- **The review must edit the design.** The HLD-change column is the deliverable's teeth.

## Common ways learners go wrong (pre-empt these)

| Mistake | Why it's wrong | Steer them to |
|---|---|---|
| Generic checklist ("turn on MFA, use NSGs") | Not tied to *this* design | cite the HLD § and the specific gap |
| All five pillars weighted equally | Misses the AVD-critical risks | lead Cost / Performance / Reliability |
| Findings but **no decisions** | A review must change the design | fix-now / accept + HLD edit per finding |
| No severity or owner | Can't prioritise or action | H/M/L + a named role |
| Ignores the **logon storm** | The #1 AVD performance failure mode | size/split the profile share for peak IOPS |
| Treats snapshots as a backup | Untested restore ≠ recoverability | require a tested restore runbook |
| Nothing handed to the pilot | WAF becomes ceremony | flag the risks B.2.3 must measure |

## Scoring guide (trainer)

A strong submission has **5–8 findings**, **at least two AVD-specific High findings**, every finding
**referenced to an HLD section**, and a **decision register that edits the HLD**. Bonus for explicitly
routing risks into the pilot's success criteria.

## Hand-off

Fix-now findings update [`hld.md`](../challenge-02/hld.md) before C05 deploys. The carried risks
become the quantitative success criteria in [`pilot.md`](../challenge-04/pilot.md).
