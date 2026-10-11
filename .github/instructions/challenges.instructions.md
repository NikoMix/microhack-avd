---
applyTo: "challenges/**/*.md"
---
# Challenge content rules

- **Audience:** partner consultants (AZ-140 level) in a Train-the-Trainer setting. Write so a
  trainer can deliver it and a learner can self-serve.
- **Every challenge maps to a Module B control** and must end by producing that control's
  **evidence artifact** in its `work/` folder (copy the matching `templates/` file from the
  `avd-evidence-pack` skill).
- **Structure each challenge README:** Objective · Module B control · Time-box · Prerequisites ·
  The agentic way (which agent/skill/MCP to use) · Steps · Definition of done / acceptance
  criteria · Stretch goals · Trainer notes (collapsible) · What's next.
- **Show the agentic path first.** Lead with "ask the `avd-…` agent / use the `…` skill / query
  the `…` MCP", then give the manual fallback. This is the point of the MicroHack.
- **Cost & safety:** deploy challenges must reference `scripts/setup/` (guardrails first) and end
  with `scripts/reset/` (teardown). Keep the footprint to 1–2 hosts.
- **Style:** imperative, concise, table/checklist-driven; fenced code for commands; passes
  `markdownlint-cli2`. Use relative links to scenario data, skills, and templates.
- **Consistency:** personas/numbers/names must match `scenario/` and the README challenge table.
