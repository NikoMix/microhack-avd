# Challenge 06 — Service validation

> **Module B control:** B.4.1 — Service Validation · **Time-box:** 45 min ·
> **Lead agent:** `avd-test-engineer` · **Evidence:** `work/validation.md`

## Objective

Prove the deployed AVD environment **works and meets the pilot's success criteria** with
**evidence, not opinion**: logon performance, application launch, autoscaling, failover/resilience,
FSLogix profile integrity, and monitoring — each with a target, an actual, a pass/fail, and the
query or command that produced it.

## Prerequisites

- Completed [Challenge 05](../challenge-05-deploy-to-production/) — a deployed lab and `deployment.md`.
- The pilot success criteria from [Challenge 04](../challenge-04-poc-pilot/) (`work/pilot.md`).
- Guardrails still in place ([`scripts/setup/`](../../scripts/setup/)).

## The agentic way (do this first)

1. **Agent:** adopt **`avd-test-engineer`** — ask it to run the validation suite against your
   deployment and table the results into the evidence artifact.
2. **Skill:** it draws on `avd-personas-sizing` (what "good" looks like per persona),
   `avd-fslogix` (profile roam integrity), and the `avd-waf-lens` reliability checks.
3. **MCP:** `azure` to run Log Analytics KQL and read resource state; `microsoft-learn` for the
   AVD Insights / WVDConnections schema; `github` for the task board.

> The point of this MicroHack is the agentic workflow. Use the agent to draft, then **you** apply
> the consulting judgement and verify.

## Steps

### 1. Generate signal (token-scale load)

The logon-performance query needs connections to measure. Generate a little load first:

```bash
pwsh ./scripts/load-test/Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -ConcurrentUsers 5 -DurationMinutes 5
```

### 2. Run the validation suite

```bash
# Resolves your lab on either IaC track; -AsMarkdown emits the Results table
pwsh ./scripts/validate/Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec -AsMarkdown
```

Paste the table into the **Results** section of `validation.md`. Use `-TerraformDir` or
`-BicepDeploymentName` instead of `-ResourceGroup` if you prefer track-native resolution.

### 3. Complete each test area

For every row, fill in **method · target · actual · pass/fail · evidence**:

- **Logon performance (P50/P95)** — KQL on `WVDConnections`; target from the pilot (≈30 s).
- **Application launch** — the per-persona apps published and assigned.
- **Autoscaling** — ramp-up / ramp-down / drain via the scaling plan.
- **Failover / resilience** — host failure tolerance + storage redundancy.
- **FSLogix profile integrity** — sign in across hosts; the profile roams cleanly.
- **Monitoring / alerting** — thresholds breach and alert as designed.

### 4. Record failures & remediation

Capture any gaps, the remediation, and whether they **loop back to B.3.1 deploy**.

### 5. Reconcile to the pilot

Confirm the results meet the **B.2.3 pilot success criteria**, then copy
[`.github/skills/avd-evidence-pack/templates/validation.md`](../../.github/skills/avd-evidence-pack/templates/validation.md)
into `work/` and finish it.

## Definition of done (acceptance criteria)

- [ ] `work/validation.md` exists and follows the template.
- [ ] **Every** results row has method, target, **actual**, pass/fail, and the **evidence** command/query.
- [ ] Logon P95 is within the pilot target (or a justified deviation is recorded).
- [ ] FSLogix profile roam verified across hosts.
- [ ] Failures have remediation and a loop-back decision.
- [ ] Results **reconciled** to the B.2.3 pilot success criteria.
- [ ] Reviewed with the [`/review-evidence`](../../.github/prompts/review-evidence.prompt.md) prompt → **PASS**.

## Stretch goals

- Capture an AVD Insights workbook view of logon duration breakdown as supporting evidence.
- Drain a host and confirm sessions reschedule without profile loss.
- Run the suite against **both** IaC tracks and compare.

<details>
<summary>Trainer notes</summary>

- **Timing:** kick off `Invoke-AvdLoadTest.ps1` first (it blocks a few minutes per host) and run
  the other checks while it works.
- **Common pitfalls:** "No data in window" — they forgot to generate load; querying the Log
  Analytics **ARM id** instead of the **customer GUID** (the script handles this); expecting
  production-scale numbers from a 1–2 host lab — interpret directionally against the target.
- **Talking points:** sign-off is **evidence-based**; every target traces back to the pilot;
  `Inconclusive`/`Skipped` is an honest status, not a failure — it means "not deployed yet".
- **Solution key:** [`solutions/challenge-06/`](../../solutions/challenge-06/).

</details>

## What's next

→ Challenge 07 — Handover documentation (B.4.2).
