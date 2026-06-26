# Docs site (Astro + Starlight)

> **Status:** scaffolded — site delivered by the docs workstream. Built with
> [Astro Starlight](https://starlight.astro.build/) (OSS, MIT) and published to **GitHub Pages**
> by [`.github/workflows/deploy-docs.yml`](../.github/workflows/deploy-docs.yml).

A published companion site so the MicroHack can be browsed online (challenges, scenario, the
agentic toolkit) without cloning the repo.

## Planned structure

```text
docs/
  package.json          # Astro + Starlight (pinned, audited)
  astro.config.mjs      # site config, sidebar, base path for Pages
  src/content/docs/     # MDX pages (mirrors challenges + scenario + toolkit)
  public/               # static assets
```

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
