# Solution key — Challenge 04 · PoC / Pilot (B.2.3)

> ⚠️ **Trainers only.** Reference answer for [Challenge 04](../../challenges/challenge-04-poc-pilot/).
> Learners should attempt it with `avd-pilot-lead` first.

**Worked artifact:** [`pilot.md`](pilot.md) — a complete B.2.3 pilot plan with **quantitative**
success criteria, a test plan that retires WAF findings, results, and an explicit go/no-go.

## Why this answer is defensible

- **Quantitative criteria.** Every criterion has a **number and a measurement method** (P95 < 30 s
  via `WVDConnections` KQL, profile load < 15 s via FSLogix event 26). "It feels fast" is not a
  criterion — this models the bar.
- **The pilot retires risk.** Each test maps to a **WAF finding** (T1→F3 logon storm, T2→F4 density,
  T3→F5 restore, T4→smartcard, T5→F7). The pilot exists to *prove the design*, not to demo features.
- **Right-sized and cost-safe.** A **tiny lab footprint** (1–2 KW hosts + 3 personal VMs, small
  SKUs, budget + auto-shutdown first) — never Contoso's full 1,000-user estate in the classroom.
- **An honest go/no-go.** **Go-with-conditions** with the specific fixes (split shares, restore
  runbook, redirection policy) required before B.3.1, plus residual risks (CC at scale, BCDR,
  Citrix app *X*) routed to later phases.

## Teaching points

- **No number, no criterion.** Push learners to attach a target + a method to every line.
- **Pilot ⇄ WAF traceability** is the whole point. If a test maps to no finding, question whether
  it's worth running; if a High finding maps to no test, the pilot is incomplete.
- **"Go-with-conditions" is the realistic outcome** — pure GO is rare, NO-GO means the design
  failed. Teach the conditional gate.
- **Cost guardrails are part of the deliverable** — applying budget + auto-shutdown *before* the
  first host is the muscle memory this MicroHack builds.
- The **Results** table here is illustrative so the worked example is complete; in a real engagement
  the numbers come from the deployed lab (B.4.1). The banner in `pilot.md` says so explicitly.

## Common ways learners go wrong (pre-empt these)

| Mistake | Why it's wrong | Steer them to |
|---|---|---|
| Qualitative criteria ("logon feels fast") | Can't pass/fail it | a target + a measurement method |
| Pilot the whole estate | Cost + time blow-up; unsafe | a representative slice at lab scale |
| Tests not mapped to WAF findings | Pilot proves nothing | map each test to the risk it retires |
| Skips **budget / auto-shutdown** | Burns the training sub | apply guardrails before any host |
| Binary GO / NO-GO only | Misses the real-world path | go-with-conditions + required fixes |
| No residual risks | Hides what's still unproven | list deferrals (CC scale, BCDR, legacy app) |
| Logon storm not tested | The top AVD risk goes unmeasured | T1 ramps concurrent logons on one host |

## Scoring guide (trainer)

A strong submission has **≥ 5 quantitative criteria** (each with a method), a **test plan that maps
to the C03 WAF findings**, a **lab-scale** footprint with guardrails, and an **explicit go/no-go with
conditions and residual risks**. Bonus for tying criteria 6–8 (IOPS, restore, smartcard) back to the
specific design decisions they validate.

## Hand-off

The conditions become entry criteria for **C05 (B.3.1 deploy)**; the criteria + methods become the
**C06 (B.4.1 service-validation)** test cases. This closes the design → review → pilot → deploy loop.
