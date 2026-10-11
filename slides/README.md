# Slides (Marp)

Plenary and per-challenge decks for classroom delivery, built with
[Marp](https://marp.app/) (OSS, MIT). Slides stay as **Markdown** so they live in the repo, diff
cleanly, and render with a single pinned CLI — no licensed fonts, themes, or imagery.

> **Trainers:** the facilitation playbook (talk tracks, timings, rehearsal, gates) lives in
> [`facilitator/`](../facilitator/README.md). These decks are the on-screen frame; the facilitator
> kit is how you run the day.

## Decks

| Deck | Use |
|---|---|
| [`00-welcome.md`](00-welcome.md) | Plenary opener — objectives, TtT framing, the agentic toolkit (agents / skills / MCP), the Contoso scenario, run of day, and C00 |
| [`01-assessment.md`](01-assessment.md) | C01 · Workload assessment (B.1.1) |
| [`02-solution-design.md`](02-solution-design.md) | C02 · Solution design / HLD (B.2.1) |
| [`03-well-architected-review.md`](03-well-architected-review.md) | C03 · Well-Architected review (B.2.2) |
| [`04-poc-pilot.md`](04-poc-pilot.md) | C04 · PoC / Pilot (B.2.3) |
| [`05-deploy-to-production.md`](05-deploy-to-production.md) | C05 · Deploy to production (B.3.1) |
| [`06-service-validation.md`](06-service-validation.md) | C06 · Service validation (B.4.1) |
| [`07-handover-documentation.md`](07-handover-documentation.md) | C07 · Handover documentation (B.4.2) |
| [`08-train-the-trainer.md`](08-train-the-trainer.md) | Facilitation closer — rehearsal, timing, gates, debrief |

Each per-challenge deck follows the same shape: **control + objective → the agentic way (agent /
skill / MCP) → demo beats → Definition of done (gate) → trainer cue**. The shared OSS theme is
[`themes/microhack.css`](themes/microhack.css).

## Build

The Marp CLI is **pinned** in [`package.json`](package.json) and kept audit-clean.

```bash
cd slides
npm install            # installs the pinned Marp CLI locally (0 known vulnerabilities)
npm run build          # render every deck to slides/out/*.html (headless, no browser)
```

```bash
npm run build:pdf      # PDF  (requires a local Chrome/Chromium)
npm run build:pptx     # PPTX (requires a local Chrome/Chromium)
npm run watch          # live preview server for all decks
```

Rendered output (`out/`, `*.html`, `*.pdf`, `*.pptx`) is git-ignored. The build helper
[`build.mjs`](build.mjs) uses only Node built-ins plus the pinned CLI and runs the same on Linux
(Codespaces / dev container) and Windows.

No global install needed for a one-off render:

```bash
npx @marp-team/marp-cli@4.4.0 --theme-set ./themes --html 00-welcome.md -o out/00-welcome.html
```

The dev container also pre-installs the Marp VS Code extension for live preview while editing.

## Conventions

- **Sparse slides** — they frame the hands-on work; they are not the content.
- **One `#` (H1) per deck** (the title slide); every other slide leads with `##` — keeps
  `markdownlint` happy and the deck navigable.
- Special slide classes via Marp directives: `<!-- _class: lead -->` (title / divider),
  `<!-- _class: gate -->` (a go/no-go checkpoint), `<!-- _class: invert -->` (dark divider).
- Every challenge deck ends pointing at the **next** challenge and its **lead agent**.
- Brand-neutral theme; **OSS only** — system fonts, no licensed assets.
