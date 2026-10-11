# AVD landing zone — layered reference architecture

```mermaid
flowchart TB
  subgraph Identity & governance
    entra[Entra ID · CA · RBAC]
    budget[Budget + auto-shutdown]
  end
  subgraph Network
    hub[Hub vNet]
    spoke[AVD spoke vNet · subnet]
    pe[Private endpoints: Files, Key Vault]
    hub --- spoke
  end
  subgraph Storage
    files[(Azure Files Premium · FSLogix · Kerberos)]
  end
  subgraph Image
    aib[Azure Image Builder] --> gallery[Compute Gallery]
  end
  subgraph AVD
    ws[Workspace]
    hp1[Host pool · pooled multi-session]
    hp2[Host pool · personal]
    ag[Application groups]
    sp[Scaling plans]
  end
  subgraph Monitoring
    law[Log Analytics] --> insights[AVD Insights + alerts]
  end

  entra --> ws
  gallery --> hp1
  gallery --> hp2
  spoke --> hp1
  spoke --> hp2
  pe --- files
  hp1 --> files
  hp2 --> files
  ws --> ag
  sp --> hp1
  hp1 --> law
  hp2 --> law
```

## Build order (dependencies)

1. Resource group + tags + **budget/guardrails** (before any VM).
2. Networking (vNet, subnet, NSG, private DNS) + Log Analytics.
3. Storage account + Files Premium share + private endpoint + identity-based access (Kerberos).
4. (Optional in lab) Image: Azure Image Builder → Compute Gallery. Labs may use the
   marketplace Win 11 multi-session image to save time.
5. AVD objects: workspace → host pool(s) → application group(s) → assignments.
6. Session hosts (1–2 in the lab) joined to the pool, FSLogix configured.
7. Scaling plan + monitoring/alerts.

Each numbered layer maps to an AVM module — see the parent `SKILL.md` module map and
`infra/README.md` for the concrete parameter/output contract.
