---
marp: true
theme: microhack
paginate: true
footer: "Train-the-Trainer · Facilitation"
---

<!-- _class: lead -->
<!-- _paginate: false -->
<!-- _footer: "" -->

# Train-the-Trainer

## Facilitating the AVD Module B MicroHack

How to **run this day for your own customers** — rehearsal, timing, gates, cost discipline,
and debrief. The trainer's playbook in ten slides.

---

## The Train-the-Trainer contract

You are teaching **two layers at once** — make both explicit to the room.

- **Layer 1 — the content** — the AVD Module B engagement lifecycle and its evidence.
- **Layer 2 — the delivery** — how to facilitate it: the demos, the pitfalls, the timing.

> Narrate your own facilitation as you go: *"Notice I led with the agent, then showed the
> manual path — that's the move you'll repeat for your customers."*

---

## Lead with the agent — the core move

Every challenge uses the same rhythm. **Model it consistently.**

1. **Adopt the agent**, ground it in `scenario/` and the prior artifact.
2. Let it **draft** using its skills + MCP tools.
3. **You apply judgement** — quantify, challenge, decide.
4. Show the **manual path** once, so learners see what the agent saved.
5. **Grade the evidence** with [`/review-evidence`](../.github/prompts/review-evidence.prompt.md).

> The contrast between agentic and manual **is the lesson** — not the artifact alone.

---

## Rehearse before you teach

Dry-run the **agents, skills and MCP** the day before — never first-run them live.

- **Agents** — open the picker; confirm all **eight `avd-*`** appear
  ([`.github/agents/`](../.github/agents/)). Run
  [`/start-engagement`](../.github/prompts/start-engagement.prompt.md) and confirm it reads
  `scenario/`.
- **Skills** — ask a sizing question; confirm `avd-personas-sizing` activates with the math.
- **MCP** — smoke-test each: `github` (list issues), `azure` (subscription + quota + what-if),
  `microsoft-learn` (grounded answer with links), `terraform` (module lookup).
- **Deploy** — run **C05 end to end** in the class region and **time it**.

> Full prep list: [`facilitator/delivery-checklist.md`](../facilitator/delivery-checklist.md).

---

## Timing discipline

The day is **dense (~9 h elapsed, ~7 h hands-on)**. Guard the schedule.

- Start the **Codespace build during the welcome** — it is the morning long pole.
- **C05 (Deploy, 75 min) is the overrun risk.** Protect its slot; keep the footprint tiny.
- If you fall behind, **shorten manual fallbacks**, not the agentic demo or the gates.
- Keep a **pre-deployed environment or recording** as a C05 fallback.

> Minute-by-minute: [`facilitator/run-of-day.md`](../facilitator/run-of-day.md).

---

<!-- _class: gate -->

## The go / no-go gates

Each challenge has a **Definition of done**. Treat it as a **gate** — do not advance until it passes.

- **C00** — everyone has a **budget** before any deploy. *Hard stop.*
- **C01–C04** — the artifact is **quantified and traceable** before the next phase builds on it.
- **C05** — **what-if / plan reviewed** before apply; budget confirmed.
- **C06** — results are **measured**, not asserted.
- **End** — **every learner has run teardown.** *Hard stop.*

---

## Cost is a teaching moment

Don't hide the bill — **teach the discipline**.

- Guardrails (budget + auto-shutdown) deploy **before** any host — model it out loud.
- **`what-if` / `plan` every time**; read the cost shape back to the room.
- Small SKUs, **1–2 hosts**; the 1,000-user design stays on paper.
- Verify teardown via the **`azure` MCP** (resource group empty).

> Playbook: [`facilitator/cost-and-cleanup.md`](../facilitator/cost-and-cleanup.md).

---

## Common pitfalls across the day

- **Wrong Azure subscription** selected — check `az account show` early.
- **Docker not running** locally — breaks the Terraform MCP container.
- **Corporate tenant** blocks device-code login — have a **fallback subscription**.
- **Inconsistent numbers** — personas must stay **700 / 200 / 60 / 40 = 1,000** throughout.
- **Asserting instead of measuring** in validation.
- **Skipping teardown** — the most expensive mistake of the day.

---

## Debrief and teardown check

Close deliberately — **do not let the room drift out**.

1. Recap the **chain**: assessment → design → review → pilot → deploy → validate → handover.
2. Reinforce the **agentic pattern** they will reuse for customers.
3. **Teardown check** — confirm **every** learner ran reset and the `azure` MCP shows nothing left.
4. Collect feedback as **GitHub issues** (challenge-feedback / lesson-learned templates).

---

## Re-deliver for your customers

This kit is **yours to reuse**.

- Swap **Contoso** for the customer's estate; keep the **control → agent → evidence** structure.
- Reuse the agents, skills, MCP config, and the evidence templates as-is.
- Keep the **cost guardrails and teardown habit** — they protect every engagement.

> The destination is the **Advanced Specialization audit evidence**; the agents just get you
> there faster and more consistently.

---

<!-- _class: lead close -->
<!-- _paginate: false -->

## The facilitator kit

### Everything you need to run this day

[Guide](../facilitator/facilitator-guide.md) ·
[Run of day](../facilitator/run-of-day.md) ·
[Delivery checklist](../facilitator/delivery-checklist.md) ·
[Cost & cleanup](../facilitator/cost-and-cleanup.md)

> Start at [`facilitator/README.md`](../facilitator/README.md). Thank you — now go teach it.
