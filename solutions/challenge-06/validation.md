# Contoso AVD — Service Validation (B.4.1)

> Author: AVD Validation Engineer · Date: 2026-06-27 · Environment / deployment ID: `env=lab` · `rg-avd-lab-sec` · host pool `hp-avd-lab-sec` (Sweden Central, `sec`)

This artifact records the evidence that the deployed lab slice meets the B.2.3 pilot
success criteria. Signal was generated first with the load-test, then the read-only
validation suite was run and its Markdown results captured below.

Commands run (in order):

```text
pwsh ./scripts/load-test/Invoke-AvdLoadTest.ps1 -ResourceGroup rg-avd-lab-sec -ConcurrentUsers 5 -DurationMinutes 5
pwsh ./scripts/validate/Test-AvdService.ps1 -ResourceGroup rg-avd-lab-sec -AsMarkdown
```

## Results

| Test area | Method | Target | Actual | Pass/Fail | Evidence (query/cmd) |
| --- | --- | --- | --- | --- | --- |
| Logon performance (P50/P95) | Generate 5-user logon storm, then summarise `WVDConnections` Started→Connected over the last hour from `log-avd-lab-sec` | P50 ≤ 20 s · P95 ≤ 30 s | P50 ≈ 14 s · P95 ≈ 26 s (vs 60–90 s legacy) | Pass | KQL below (logon-performance query) |
| Application launch | Launch representative apps per persona on the published desktop; time LOB CRM cold start and exercise smartcard sign-in | LOB CRM ≤ 8 s; smartcard redirection works | LOB CRM ≈ 6 s; smartcard sign-in succeeded | Pass | `Test-AvdService.ps1 -AsMarkdown` (App delivery check); smartcard redirection confirmed in session (`Get-PnpDevice` smartcard reader present) |
| Autoscaling (ramp up/down, drain) | Inspect scaling plan `sp-avd-lab-sec` schedule; drive utilisation with load-test; observe host power/drain states in AVD Insights | Ramp up before shift start, down after; drain on shutdown | Ramp-up brought 2nd host online ahead of the configured peak window; ramp-down drained then deallocated off-peak; drain-on-shutdown observed | Pass | `Get-AzWvdScalingPlan -ResourceGroupName rg-avd-lab-sec -Name sp-avd-lab-sec`; AVD Insights host-states; `Invoke-AvdLoadTest.ps1` drove utilisation |
| Failover / resilience | Drain `vmavdlab0`, confirm new sessions land on `vmavdlab1`; verify profile storage redundancy | Tolerate loss of 1 of 2 hosts (sessions reschedule); storage ZRS | New connections rescheduled to `vmavdlab1`; storage account `stavdlabsec001` confirmed ZRS. Two-host lab gives limited signal for true host-failure failover | Inconclusive | `Update-AzWvdSessionHost -AllowNewSession:$false` on `vmavdlab0`; `Get-AzStorageAccount -ResourceGroupName rg-avd-lab-sec -Name stavdlabsec001 \| Select Sku` → `Premium_ZRS`; KQL on `WVDConnections` for landing host |
| FSLogix profile integrity | Sign in on `vmavdlab0`, sign out, sign in on `vmavdlab1`; verify single VHD attach, no temp profile, redirections | Profile roams cleanly across both hosts; no temp profiles; single VHD attach | Profile attached from `\\stavdlabsec001.file.core.windows.net\profiles\...`; single VHD; no `TEMP` profile; redirections correct | Pass | `frx list-redirects`; FSLogix Apps Operational event log (ID 26 attach success, no ID 31 temp); profile path under `profiles` share |
| Monitoring / alerting | Confirm AVD Insights populated; breach a threshold and confirm the alert fires | AVD Insights populated; alert on logon P95 > 30 s and host CPU > 85% for 10 min | Insights populated; CPU > 85% alert fired during load-test. First run: logon-P95 alert mis-fired during the empty pre-load window (no sessions → null evaluated as breach) | Fail | Azure Monitor alert rules `alrt-avd-logon-p95-sec`, `alrt-avd-cpu85-sec`; fired alert in Alerts blade; see Failures table |

### Logon-performance KQL (evidence for the logon row)

```kusto
WVDConnections
| where TimeGenerated > ago(1h)
| project CorrelationId, UserName, State, TimeGenerated, SessionHostName
| summarize StartTime = minif(TimeGenerated, State == "Started"),
            ConnectedTime = minif(TimeGenerated, State == "Connected")
            by CorrelationId, UserName, SessionHostName
| where isnotnull(ConnectedTime)
| extend LogonSeconds = datetime_diff('second', ConnectedTime, StartTime)
| summarize P50 = percentile(LogonSeconds, 50), P95 = percentile(LogonSeconds, 95), Sessions = count()
```

## Failures & remediation

| Test | Gap | Remediation | Loop back to |
| --- | --- | --- | --- |
| Monitoring / alerting (logon P95) | First-run alert mis-fired: the log-search alert evaluated an empty window (no sessions before load was generated) and a null/zero P95 tripped the rule | Add `Sessions >= N` guard to the alert query and set "do not fire when no data"; align the evaluation window to populated periods. Re-test after load. This is an alert-rule tuning fix, not an infra defect | B.3.1 deploy? No — fix is in the monitoring/alert-rule definition; no host or storage redeploy required |
| Failover / resilience | Two-host lab gives limited signal; draining 1 host leaves only 1 host so a true host-loss reschedule cannot be fully demonstrated at classroom scale | Validate directionally in lab (drain reschedules to surviving host; ZRS confirmed). Confirm full N+1 failover at production density during pilot/UAT with ≥ 3 hosts | N/A — lab-scale limitation, not a deployment defect; revisit at production scale |

## Reconciliation

Validated results reconcile to the B.2.3 pilot success criteria as follows:

1. **Logon time** — P50 ≈ 14 s (≤ 20 s) and P95 ≈ 26 s (≤ 30 s): **met**, a large improvement on the 60–90 s legacy RDS+Citrix pain. Directly benefits the 700 knowledge workers and 200 call-centre users on the pooled host pool.

2. **LOB CRM launch + smartcard** — ≈ 6 s (≤ 8 s) with smartcard redirection working: **met**. Covers knowledge-worker and call-centre CRM dependency.

3. **Autoscaling** — `sp-avd-lab-sec` ramps up before the shift window and down after, with drain-on-shutdown: **met**. Satisfies the call-centre shift-based scaling requirement.

4. **FSLogix roaming** — single VHD attach, no temp profile, clean roam `vmavdlab0`→`vmavdlab1`: **met**. Resolves the Citrix UPM corruption pain for all personas; production should still size Azure Files for the 5/3/15/30 GB persona profiles and isolate developer profiles.

5. **Resilience / storage** — surviving-host reschedule observed and storage ZRS confirmed, but full host-loss failover is **Inconclusive at 2-host lab scale**; deviation justified by classroom footprint and deferred to production-density validation.

6. **Monitoring** — AVD Insights populated and CPU > 85% alert fired: **met**; the logon-P95 alert needs the no-data guard (see Failures) before it is trustworthy.

Net: 4 of 6 areas pass outright, 1 Inconclusive (lab-scale limitation, justified), 1 Fail
with a contained alert-rule remediation. No deployment (B.3.1) loop-back required.
