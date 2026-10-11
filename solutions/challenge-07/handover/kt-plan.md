# Contoso AVD — Knowledge Transfer Plan (B.4.2)

> Owner: AVD Delivery Lead · Date: 2026-06-27

Goal: transfer operation of `hp-avd-lab-sec` to Contoso Cloud Operations so they can run every
runbook procedure unaided before hypercare exit.

## Sessions

| # | Session | Audience | Duration | Agenda | Hands-on lab | Owner | When |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Architecture overview | Ops, Service Owner, Security | 90 min | LLD walkthrough: network/reverse-connect, identity (Entra-join, CA), AVD objects, profiles, monitoring; map to HLD/WAF | Navigate the deployed RG; locate each resource in LLD §1 | Delivery Lead | Week 1, Day 1 |
| 2 | Day-2 operations | Ops (L1/L2) | 120 min | Runbook routine ops: add/drain/remove host, scaling change, patching, right-size | Add then drain a test host; change ramp-up threshold via `--what-if` then apply | Ops Lead | Week 1, Day 2 |
| 3 | FSLogix & profiles | Ops (L2) | 90 min | Container model, Entra Kerberos, registry values, single-VHD roaming | Reproduce + fix a temp-profile; inspect FSLogix event log | Storage SME | Week 1, Day 3 |
| 4 | Monitoring & alerting | Ops, Service Desk | 75 min | AVD Insights workbook, the three alert rules, response runbook | Trigger CPU alert (load test); walk the response | Monitoring SME | Week 1, Day 4 |
| 5 | Image lifecycle | Ops (L2), Packaging | 90 min | Golden image build, gallery versioning, blue/green rollout | Publish a new image version; roll one host blue/green | Image SME | Week 2, Day 1 |
| 6 | IaC & change | Ops, Platform/DevOps | 90 min | AVM Bicep/Terraform layout, params, `what-if`/`plan`, PR change flow, teardown script | Make a param change via PR; preview with `--what-if` | Platform Lead | Week 2, Day 2 |

## Materials

- Runbook: `solutions/challenge-07/handover/runbook.md`
- LLD / as-built: `solutions/challenge-07/handover/lld.md`
- Dashboards: AVD Insights workbook on `log-avd-lab-sec`
- IaC repo: `infra/bicep` (`main.bicepparam`) and `infra/terraform`
- Teardown: `scripts/reset/Remove-AvdLab.ps1`

## Exit criteria

- Ops team performs **each** runbook operation unaided (add/drain/remove host, scaling change,
  image rollout, patching, FSLogix fix, snapshot restore).
- Each attendee group signs the KT attendance/competency sheet.
- Open KT questions are closed or carried into hypercare as tracked actions.
