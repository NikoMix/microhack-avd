# Contoso AVD — Acceptance & Sign-off (B.4.2)

> Date: 2026-06-27 · Engagement reference: Contoso AVD Module B / control B.4.2

## Acceptance checklist

Each row traces to a validated result in `solutions/challenge-06/validation.md` (B.4.1).

| # | Acceptance criterion | Met? | Evidence (B.4.1 validation.md) |
| --- | --- | --- | --- |
| 1 | Logon time within target (≤ 30 s P95) | Yes | Logon P50 ≈ 14 s, **P95 ≈ 26 s** (target ≤ 30 s) |
| 2 | LOB CRM launches and smartcard auth works | Yes | CRM launch ≈ 6 s (≤ 8 s) + smartcard logon OK |
| 3 | Autoscale ramps on schedule with drain | Yes | Scaling plan ramps on schedule; drain-on-shutdown verified |
| 4 | FSLogix profiles roam cleanly | Yes | Single VHD attach, **no temp profile**, clean roam |
| 5 | Resilience to host loss | Yes | Tolerant of **1-of-2** host loss; sessions continue |
| 6 | Monitoring alerts fire correctly | Yes | Logon / CPU / capacity alerts fired in test |
| 7 | Security posture enforced (MFA / no inbound RDP) | Yes | `CA-AVD-Require-MFA` enforced; NSG reverse-connect only |

## Outstanding items / conditions

| Item | Owner | Target date | Condition |
| --- | --- | --- | --- |
| Add Private Endpoint + Private DNS for Azure Files (prod) | Platform Lead | Pre-prod wave 1 | Lab used public endpoint |
| Tighten CA to "compliant device" only (drop hybrid) | Security | Post-pilot | Pilot allowed hybrid-or-compliant |
| Production scale sizing per persona (1000 users) | Delivery Lead | Wave planning | Lab sized at 2 hosts |

## Sign-off

| Role | Name | Signature | Date |
| --- | --- | --- | --- |
| Customer sponsor | _______________ | _______________ | __________ |
| Delivery lead | _______________ | _______________ | __________ |
