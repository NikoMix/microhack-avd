# Trainer Solution Key — Challenge 07: Handover Documentation (B.4.2)

This is the trainer-facing rationale for the six-document handover pack in `handover/`. It explains
what "good" looks like and how to assess learner submissions.

## As-built vs HLD

The **LLD must reflect what was actually deployed**, not the HLD template. In a real engagement the
learner reconciles every value against the live environment (via the `azure` MCP / `az` queries):
resource names, SKUs, IPs, FSLogix registry, scaling schedule, alert thresholds. This paper key uses
the **lab as-built token slice** (`rg-avd-lab-sec`, `vmavdlab0/1`, `stavdlabsec001`, etc.) as the
source of truth. An LLD that merely restates the HLD or leaves placeholders **fails**.

## Why each document exists (and who consumes it)

- **`lld.md`** — the as-built record of truth. Consumed by **Ops + future projects**; the audit
  baseline.
- **`runbook.md`** — concrete day-2 procedures. Consumed by **L1/L2 Ops** during incidents and change.
- **`kt-plan.md`** — structured handover sessions + labs. Consumed by **Ops + delivery** to transfer
  capability.
- **`hypercare.md`** — the supported transition window and BAU exit gates. Consumed by **Ops + sponsor**.
- **`signoff.md`** — formal acceptance mapped to evidence. Consumed by **sponsor + delivery**; it is
  the gate that **closes the engagement**.
- **`lessons-learned.md`** — continuous improvement with **owned** actions. Consumed by **delivery +
  practice leads**, fed back as a GitHub `lesson-learned` issue.

Together this pack is the **billable deliverable** that closes the engagement.

## Sign-off discipline

Every acceptance row in `signoff.md` **traces to a B.4.1 result** in
`solutions/challenge-06/validation.md` (logon P95 ≈ 26 s, CRM ≈ 6 s + smartcard, autoscale + drain,
FSLogix clean roam, 1-of-2 host resilience, alerts fire, security posture). No claim without evidence.

## Teardown reminder

This is a paper/lab key — **nothing is deployed live**. In the real lab: **capture evidence first**
(LLD, screenshots, validation), *then* tear down:

```powershell
pwsh ./scripts/reset/Remove-AvdLab.ps1 -ResourceGroup rg-avd-lab-sec
# add -RemoveBudget to also remove budget-avd-lab-sec
```

The script is tag-guarded (`autoDelete=true`). Confirm the footprint is gone after running.

## Common ways learners go wrong

- **LLD full of placeholders** — copies the HLD instead of reconciling to deployed reality.
- **Generic runbook** — "how to add a host" in the abstract, not concrete `az` commands against
  `hp-avd-lab-sec`.
- **Forgetting teardown** — leaving the lab running (cost + audit risk).
- **Sign-off not mapped to validation** — acceptance ticked without pointing at B.4.1 evidence.
- **Lessons-learned without owned follow-up** — observations with no owner, date, or change action.
