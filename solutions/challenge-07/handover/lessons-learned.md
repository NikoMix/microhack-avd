# Contoso AVD — Lessons Learned (B.4.2)

> Date: 2026-06-27 · Contributors: Delivery team, Contoso Cloud Ops, Security

## What went well

| Theme | Detail |
| --- | --- |
| AVM IaC + `what-if` | Repeatable deploys; previews caught drift before apply |
| Logon performance | P95 ≈ 26 s vs 60–90 s legacy — clear, demonstrable win |
| Reverse-connect security | No inbound RDP; CA MFA accepted by security with no friction |
| FSLogix on Premium ZRS | Clean single-VHD roaming; no temp profiles in testing |
| Tag + budget guardrails | Cost stayed within 50 USD; auto-shutdown enforced nightly |

## What to improve

| Theme | Detail | Follow-up owner |
| --- | --- | --- |
| Entra Kerberos prereq | Easy to miss; gate it earlier in the build | Platform Lead |
| Image pipeline | Manual capture slowed rollout; automate gallery versioning | Image SME |
| Private networking | Lab used public Files endpoint; bake PE/DNS into prod IaC | Platform Lead |
| App-compat coverage | Smartcard + legacy Java need a dedicated test matrix | App Owner |

## Surprises / risks realised

- **Quota:** `Standard_D4as_v5` regional vCPU quota needed a raise before scaling beyond the lab.
- **Entra Kerberos prerequisite:** storage account Kerberos + share RBAC + NTFS ACLs must all align,
  or profiles fall back to temp.
- **App compatibility:** smartcard middleware and a legacy Java app required redirection/runtime
  validation not obvious from the HLD.
- **Cost:** without auto-shutdown and the scaling plan, idle hosts would have blown the 50 USD budget.

## Feedback into the engagement model

| Change | What | How |
| --- | --- | --- |
| Challenge 01 (Assessment) | Add explicit quota + Entra Kerberos prereq checklist | New checklist item gating later challenges |
| Challenge 05 (Deploy) | Ship image pipeline as IaC | Add gallery + versioning module |
| Validation agent (B.4.1) | Add app-compat matrix (smartcard, legacy Java) | Extend validation skill |
| Reset script | Auto-teardown stale labs via the `autoDelete=true` tag sweep | Scheduled workflow calling `Remove-AvdLab.ps1` |

> Filed as GitHub `lesson-learned` issue (offer): *"AVD Module B — lessons learned (B.4.2)"* with the
> follow-up actions above assigned to named owners. Run, on approval:
> `gh issue create --label lesson-learned --title "AVD Module B — lessons learned (B.4.2)" --body-file solutions/challenge-07/handover/lessons-learned.md`
