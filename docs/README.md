# Docs site (Astro + Starlight)

> **Status:** delivered. Built with
> [Astro Starlight](https://starlight.astro.build/) (OSS, MIT) and published to **GitHub Pages**
> by [`.github/workflows/deploy-docs.yml`](../.github/workflows/deploy-docs.yml).

A published companion site so the MicroHack can be browsed online (challenges, scenario, the
agentic toolkit) without cloning the repo.

## Structure

```text
docs/
  package.json          # Astro 7 + Starlight 0.41 (pinned exact, audited: 0 vulns)
  astro.config.mjs      # site + base (/microhack-avd), sidebar, branding
  tsconfig.json         # extends astro/tsconfigs/strict
  src/
    content.config.ts   # Starlight docs collection
    styles/custom.css   # Azure-blue / purple accents
    assets/logo.svg     # brand logo
    content/docs/
      index.mdx         # splash homepage (Overview)
      scenario.mdx      # Contoso personas + legacy estate
      toolkit.mdx       # agents / skills / MCP servers
      infra.mdx         # Bicep + Terraform AVM tracks
      facilitator.mdx   # Train-the-Trainer run-of-day
      challenges/       # index + 00–07 (control → agent → evidence)
  public/               # favicon, .nojekyll
```

> Pages are authored as **`.mdx`** (not `.md`) so they build/validate via Astro without
> tripping the repo-wide `**/*.md` markdownlint + link-check gates; prose lives in the repo and
> the site links back to it.

## Develop

```bash
cd docs
npm install
npm run dev      # local preview
npm run build    # static build → docs/dist (what CI publishes)
```

## Conventions

- Content **mirrors** the repo (challenges, scenario, agents/skills/MCP) — single source of
  truth stays in the repo; the site links back to it.
- Dependencies pinned and kept clean (`npm audit`, Dependabot).
- `base` path set for project Pages (`/microhack-avd`).
- OSS only; no licensed themes.
