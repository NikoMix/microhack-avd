# Contributing

Thanks for helping improve the **AVD Module B MicroHack**. This is a Train-the-Trainer
enablement kit, so contributions that make it **easier to teach** and **more faithful to
the audit** are especially valued.

## Ways to contribute

| You found… | Do this |
|---|---|
| A bug in a challenge, script, or IaC | Open an issue with the **Bug report** template, then a PR |
| Something confusing while teaching | Open an issue with the **Challenge feedback** template |
| A lesson learned from a real delivery | Open an issue with the **Lesson learned** template |
| An out-of-date Azure capability / AVM module | PR the fix and cite the Microsoft Learn doc |

## Ground rules

- **OSS / license-free only.** Do not add a dependency that requires a paid vendor licence.
  If no free option exists, build the capability in-repo.
- **Latest, secure dependencies.** Bump to current versions; keep `npm audit` /
  Dependabot clean. CI must stay green.
- **AVM-first IaC.** Prefer [Azure Verified Modules](https://aka.ms/avm); pin versions.
- **Evidence parity.** Every challenge must still produce the Module B evidence artifact it
  claims. If you change a challenge, update its solution key under `solutions/`.
- **Fictitious data only.** Keep "Contoso" data invented — never commit real customer data,
  tenant IDs, or secrets.

## Local checks before you PR

```bash
# Markdown
npx --yes markdownlint-cli2 "**/*.md" "#node_modules"

# Bicep
az bicep build --file infra/bicep/main.bicep

# Terraform
terraform -chdir=infra/terraform fmt -check && terraform -chdir=infra/terraform validate

# PowerShell (if you changed scripts)
pwsh -c "Invoke-ScriptAnalyzer -Path scripts -Recurse"
```

## Commit & branch conventions

- Branch: `type/short-description` (e.g. `fix/challenge-05-whatif`, `docs/runbook-fslogix`).
- Conventional commit subjects (`feat:`, `fix:`, `docs:`, `chore:`…).
- One logical change per PR; fill in the PR template checklist.

By contributing you agree your work is licensed under the repository's [MIT License](LICENSE).
