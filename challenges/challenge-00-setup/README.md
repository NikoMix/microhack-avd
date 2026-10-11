# Challenge 00 — Setup & guardrails

> **Module B control:** — (foundation) · **Time-box:** 45 min ·
> **Lead agent:** `avd-engagement-lead` · **Evidence:** a working environment + a deployed cost cap

## Objective

Stand up your lab environment, sign in to **your own Azure subscription**, confirm the GitHub
Copilot **agents, skills, and MCP servers** are live, and deploy a **budget + auto-shutdown** so
the rest of the day's real deployments can never surprise you on cost.

## Prerequisites

- A GitHub account with **GitHub Copilot** enabled.
- **Your own Azure subscription** with rights to create resource groups and a budget
  (Contributor + Cost Management Contributor, or Owner).
- One of:
  - **GitHub Codespaces** (recommended — zero local install), or
  - **VS Code + Dev Containers** locally with Docker.

## The agentic way (do this first)

1. **Agent:** open Copilot Chat and adopt **`avd-engagement-lead`**. Run the
   [`/start-engagement`](../../.github/prompts/start-engagement.prompt.md) prompt. It will read
   the scenario and tell you exactly what to do next.
2. **MCP:** you'll use the **`azure`** server to check region/quota and create the budget, and
   **`github`** to see the engagement issues.
3. **Skill:** `avd-cost-guardrails` carries the cost-safety rules the lead will enforce.

## Steps

### 1. Open the environment

- **Codespaces:** on the repo, **Code → Codespaces → Create codespace on main**. Wait for the
  dev container to finish (`post-create.sh` installs the toolchain).
- **Local:** clone, open in VS Code, **Reopen in Container**.

### 2. Verify the toolchain

```bash
az version && azd version && bicep --version && terraform version && gh --version && pwsh --version
```

All should print a version. If any are missing, re-run: `bash .devcontainer/post-create.sh`.

### 3. Confirm GitHub auth

```bash
gh auth status
```

In Codespaces this is automatic. Locally, ensure `GH_TOKEN` is set (see
[`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json)).

### 4. Sign in to YOUR Azure subscription

```bash
az login --use-device-code
az account show --output table          # confirm the right subscription
az account set --subscription "<your-subscription-id>"   # if you have several
```

### 5. Confirm the agents, skills & MCP servers are live

- In Copilot Chat, open the **agent picker** — you should see the eight `avd-*` agents.
- Ask the lead: *"Which skills and MCP servers do you have available?"* It should list the
  `avd-*` skills and the `github`, `azure`, `microsoft-learn`, `terraform` MCP servers
  (see [`.vscode/mcp.json`](../../.vscode/mcp.json)).
- Quick MCP smoke test — ask: *"Use the microsoft-learn MCP to summarise AVD host pool load
  balancing."* You should get a grounded answer with links.

> If the `azure` or `terraform` MCP server doesn't start, check Docker is running (Terraform MCP
> uses a container) and that `npx` can reach the registry. The GitHub MCP needs a valid token.

### 6. Check capacity, then deploy the cost cap

Ask the lead to check your quota/region, then deploy guardrails:

```bash
# Confirm vCPU quota in the lab region before deploying anything
az vm list-usage --location swedencentral --output table

# Deploy the budget + auto-shutdown guardrails (see scripts/setup/)
#   -> follow scripts/setup/README.md for the exact command on your track
```

> `scripts/setup/` is delivered with the deployment workstream. Until then, create a manual
> Consumption budget (e.g. €/$50) with alerts at 50/80/100% via the portal or
> `az consumption budget create`, as the `avd-cost-guardrails` skill describes.

## Definition of done (acceptance criteria)

- [ ] Toolchain verified (az, azd, bicep, terraform, gh, pwsh all report versions).
- [ ] Signed in to **your own** Azure subscription (`az account show` correct).
- [ ] All eight `avd-*` agents visible; the four MCP servers respond.
- [ ] A **budget with alerts** exists on your subscription/resource group.
- [ ] You can explain what will be deployed today and **how you'll tear it down**.

## Stretch goals

- Pin the lab region to one with confirmed quota for your chosen VM family.
- Ask the `azure` MCP to list any pre-existing AVD resources so you start clean.

<details>
<summary>Trainer notes</summary>

- **Timing:** the long pole is Codespace build + `az login` for the class. Start the codespace
  build during the welcome, before the first slides.
- **Common pitfalls:** wrong subscription selected; Docker not running locally (breaks the
  Terraform MCP); corporate tenant blocking device-code login — have a fallback sub ready.
- **Talking points:** this is the moment to explain *why* guardrails come first — every later
  challenge deploys real, billable resources. Reinforce the teardown habit now.
- **Solution key:** [`solutions/challenge-00/`](../../solutions/).

</details>

## What's next

→ Challenge 01 — Workload assessment (B.1.1).
