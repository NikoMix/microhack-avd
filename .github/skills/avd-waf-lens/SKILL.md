---
name: avd-waf-lens
description: An Azure Well-Architected Framework checklist viewed through an Azure Virtual Desktop lens. Use when reviewing an AVD design for Reliability, Security, Cost Optimization, Operational Excellence, and Performance Efficiency, to produce specific, prioritised findings instead of generic advice.
compatibility: GitHub Copilot (VS Code, CLI), Copilot coding agent
---

# AVD Well-Architected lens

Use when reviewing an AVD HLD. Probe each pillar with AVD-specific questions; lead with **Cost,
Performance, Reliability**. Ground recommendations in the **`microsoft-learn` MCP** WAF-for-AVD
guidance. Output a findings table: `ID | Pillar | Finding | Risk | Recommendation | Owner`.

## Cost Optimization

- Autoscale plans per persona (time + demand)? Off-hours/weekend ramp-down? Drain before
  deallocate?
- SKU right-sized per persona, or oversized "to be safe"?
- Files **Premium vs Standard** justified by IOPS, not defaulted?
- Reserved Instances / savings plan for steady personal hosts?
- Log Analytics ingestion/retention controlled? Image build frequency reasonable?

## Performance Efficiency

- Density validated against logon storms, not just steady state?
- FSLogix on storage that meets **peak-logon IOPS**?
- RDP Shortpath (UDP) enabled? Image optimised (VDOT, disabled bloat)?
- Users co-located with session hosts (region proximity)? Profile size capped?

## Reliability

- Host pool / availability-zone resilience? N+1 headroom?
- Profile storage redundancy (ZRS) **and** backup? Restore tested?
- Scaling-plan failure modes understood? Image pipeline a single point of failure?
- BCDR objectives (RTO/RPO) realistic and documented?

## Security

- Entra join + Conditional Access + MFA? RBAC least privilege on AVD objects?
- Private endpoints for Files/Key Vault? No public storage exposure?
- Clipboard/drive/screen-capture redirection policy set to requirement?
- Golden image patched on a cadence; no secrets baked in?

## Operational Excellence

- AVD Insights enabled; alerts on logon time + host health?
- Everything in IaC; drift detection; change process?
- Patch/update cadence for image + hosts defined? Runbooks exist?

## Using the lens

For each question that fails, write a finding with risk (H/M/L) and a concrete recommendation
tied to a specific HLD section. Force a decision: fix now, or accept-and-record.
