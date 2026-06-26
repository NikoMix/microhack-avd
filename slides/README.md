# Slides (Marp)

> **Status:** scaffolded — decks delivered by the slides workstream. Built with
> [Marp](https://marp.app/) (OSS) → Markdown to HTML/PDF.

Plenary and per-challenge slides for classroom delivery. Marp keeps slides as **Markdown** so
they live in the repo, diff cleanly, and render in CI.

## Planned decks

```text
slides/
  00-welcome.md          # objectives, TtT framing, the agentic toolkit
  01-assessment.md ...   # one short deck per challenge (intro + key concepts)
  themes/                # custom Marp theme (brand-neutral, OSS)
```

## Build

```bash
# Single deck → HTML
npx @marp-team/marp-cli@latest slides/00-welcome.md -o out/00-welcome.html

# Single deck → PDF
npx @marp-team/marp-cli@latest slides/00-welcome.md --pdf -o out/00-welcome.pdf
```

The dev container pre-installs the Marp CLI and the Marp VS Code extension for live preview.

## Conventions

- Keep slides sparse — they frame the hands-on work, they are not the content.
- Every challenge deck ends pointing at the challenge folder and its lead agent.
- Brand-neutral theme; no licensed fonts or imagery (OSS only).
