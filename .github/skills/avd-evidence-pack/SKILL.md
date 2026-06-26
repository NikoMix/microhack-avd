---
name: avd-evidence-pack
description: The canonical formats for every Azure Virtual Desktop Module B audit evidence artifact (controls B.1.1–B.4.2). Use when producing or reviewing a challenge deliverable so each artifact has the exact sections an Advanced Specialization auditor expects, with reusable templates.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# AVD Module B evidence pack

Use when creating or checking a challenge deliverable. Each Module B control requires **one
artifact with specific content**. Copy the matching file from `templates/` into the challenge's
`work/` folder and fill it in. Keep numbers consistent with `scenario/` and across artifacts.

## Control → artifact → template

| Control | Artifact | Template |
|---|---|---|
| B.1.1 Workload Assessment | `assessment.md` | `templates/assessment.md` |
| B.2.1 Solution Design (HLD) | `hld.md` | `templates/hld.md` |
| B.2.2 Well-Architected Review | `waf-review.md` | `templates/waf-review.md` |
| B.2.3 PoC / Pilot | `pilot.md` | `templates/pilot.md` |
| B.3.1 Deploy to Production | `deployment.md` | `templates/deployment.md` |
| B.4.1 Service Validation | `validation.md` | `templates/validation.md` |
| B.4.2 Handover | `lld.md`, `runbook.md`, `kt-plan.md`, `hypercare.md`, `signoff.md`, `lessons-learned.md` | `templates/handover/` |

## What "audit-grade" means here

- **Decisions, not just descriptions** — every significant choice has options considered + a
  justification.
- **Quantified** — sizing, success criteria, and validation results carry numbers + how they
  were derived/measured.
- **Traceable** — assessment → design → review → pilot → deploy → validation → handover form one
  consistent chain (same personas, same numbers, same names).
- **As-built reality** — the LLD and validation reflect what was actually deployed (pull from the
  `azure` MCP), not just the design intent.

## Review heuristic

For any artifact, ask: *would a Microsoft auditor accept this as proof the control was met?* If a
section is generic, unquantified, or inconsistent with the rest of the chain, it fails — send it
back with specifics.
