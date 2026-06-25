<p align="center">
  <img src="assets/logo.svg" alt="Spectra" width="470">
</p>

<p align="center">
  <strong>Spec-driven development with learning feedback loops - installable into any repo in three commands.</strong>
</p>

<p align="center">
  <a href="https://github.com/rogueoak/spectra/actions/workflows/ci.yml"><img src="https://github.com/rogueoak/spectra/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"></a>
  <a href="https://github.com/rogueoak/spectra/releases/latest"><img src="https://img.shields.io/github/v/release/rogueoak/spectra?sort=semver&label=version" alt="Latest version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/rogueoak/spectra" alt="License: MIT"></a>
</p>

<p align="center">
  <a href="#quick-start"><img src="https://img.shields.io/badge/Claude_Code-D97757?logo=anthropic&logoColor=white" alt="Claude Code"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/OpenAI_Codex-412991" alt="OpenAI Codex"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Gemini_CLI-1A73E8?logo=googlegemini&logoColor=white" alt="Gemini CLI"></a>
  <a href="#quick-start"><img src="https://img.shields.io/badge/Cursor-000000?logo=cursor&logoColor=white" alt="Cursor"></a>
</p>

AI-assisted development is fast but forgetful. The spec lives in a chat message, the
reasoning behind a decision evaporates, and the same mistakes come back next week. Spectra
fixes that by making intent explicit *before* you build and capturing learning *after* -
all in version control, all driven by your coding agent.

It's packaged natively for **Claude Code, OpenAI Codex, Gemini CLI, and Cursor** - one source
of truth, one set of commands - so any repo can adopt the entire protocol (the workflow, the
review personas, the artifact structure, and a reflection reminder) without copy-pasting a thing.

## What's new

<!-- whats-new -->
**1.0.0** - First stable release. 🎉
<!-- /whats-new -->

See every release at
**[github.com/rogueoak/spectra/releases/latest](https://github.com/rogueoak/spectra/releases/latest)**.
The line above is rewritten from the first line of the latest release's notes each time a
release is published - no manual edits here.

## Quick start

Install through your agent's native plugin system, then run `/spectra-install` in the repo
you want to adopt it.

**Claude Code**
```text
/plugin marketplace add rogueoak/spectra
/plugin install spectra@spectra
/reload-plugins
/spectra-install
```
`/reload-plugins` makes the newly installed plugin's commands (`/spectra-install` and the rest)
available in your current session - without it the install won't have taken effect yet.

**OpenAI Codex**
```text
codex plugin marketplace add rogueoak/spectra
```
Then install the **spectra** plugin from that marketplace and run `/spectra-install`.

**Gemini CLI**
```text
gemini extensions install https://github.com/rogueoak/spectra
```
(or `gemini extensions link .` for local development), then run `/spectra-install`.

**Cursor**

Add the `rogueoak/spectra` marketplace (in-editor marketplace panel or `/add-plugin`), then
run `/spectra-install`.

`/spectra-install` scaffolds your repo, drops in the protocol and review personas, installs a
reflection hook, and points your `AGENTS.md` at it. Later, pull updates with `/spectra-update`.

## The protocol

<p align="center">
  <img src="assets/protocol-flow.svg" alt="The Spectra loop: Route, Spec, Plan, Build, Test, Review, Merge, Reflect - learnings feed the next change" width="900">
</p>

Every change flows through one loop (full text: [`spectra/protocol.md`](spectra/protocol.md)):

| # | Step | What happens |
|---|---|---|
| 1 | **Route** | Trivial change? do it. New feature? write a **spec**. Bug or friction? write **feedback** (so it becomes a lesson). |
| 2 | **Spec** | Developer approves before any code is written (`docs/specs/NNNN-*.md`). |
| 3 | **Plan** | Multi-step work becomes an ordered plan (`docs/plans/NNNN-*.md`). |
| 4 | **Build** | Executed in a git worktree on a branch. |
| 5 | **Test** | Run the suite and fix until green **before committing** (no suite? add the test that proves the change). |
| 6 | **Review** | A PR is reviewed by the **personas you've enabled** (engineer, tester, architect, security by default - see [Skills](#skills)) who comment in a fixed format; `major`/`blocker` findings become learnings. |
| 7 | **Merge** | On approval. |
| 8 | **Reflect** | Before concluding, the **living docs** in `docs/overview/` (`project`, `features`, `architecture`, `learnings`) are updated. A non-blocking `pre-commit` hook nudges you if you forget. |

The **feedback → learnings** loop means the system gets
better at *your* codebase over time, instead of repeating itself.

## Skills

Spectra installs as a handful of slash commands (agent skills). Run them from the repo
where Spectra is installed:

| Command | What it does |
|---|---|
| `/spectra-install` | Adopt Spectra in the current repo - scaffolds `docs/`, copies the protocol and review personas, seeds the enabled-persona config, installs the reflection hook, and wires up `AGENTS.md`. |
| `/spectra-update` | Re-sync the Spectra-owned files to the installed plugin version (protocol, personas, host block, hook). Leaves your `specs/plans/feedback/overview`, your `personas.config`, and your `user*.md` ICP personas untouched. |
| `/spectra-add-user` | Define a new 👤 *User (ICP)* review persona through a short guided dialog - one per customer profile - so reviews can judge a change on that customer's behalf. Each profile says *when* it applies. |
| `/spectra-update-user` | Refine an existing ICP persona: pick one, Spectra reads it back, and a short dialog updates its profile or when it applies. |
| `/spectra-remove-user` | Remove an ICP persona so it stops being scoped into reviews. |
| `/spectra-list-users` | List the ICP personas defined in this repo and when each one applies. |
| `/spectra-persona-enable` *`[persona]`* | Turn on a review persona. With no argument, lists the personas available to enable as a numbered menu. |
| `/spectra-persona-disable` *`[persona]`* | Turn off a review persona (a core one too). With no argument, lists the personas currently enabled. |

### Review personas

Each PR is reviewed only by the personas you've **enabled** (tracked in
`docs/spectra/personas.config`) whose facet the change actually touches - so reviews stay
scoped, not eight bots on every diff. Four ship on by default, three more are available, and the
👤 user (ICP) lens is yours to define - one persona per customer profile, each scoped to the
changes it cares about:

| Persona | Default | Reviews for |
|---|---|---|
| 🔧 **engineer** | on | correctness, edge cases, maintainability |
| 🧪 **tester** | on | coverage, edge cases, honest tests |
| 📐 **architect** | on | boundaries, dependencies, design-for-change |
| 🔒 **security** | on | auth, input handling, secrets, dependencies |
| 🎨 **designer** | off | visual consistency, spacing, design tokens, clear calls-to-action |
| ⚖️ **compliance** | off | accessibility, PII minimization, i18n, GDPR/CCPA |
| 📊 **analytics** | off | event tracking, measurable outcomes, feature-gate metrics |
| 👤 **user (ICP)** | `/spectra-add-user` | whether the change actually serves your ideal customer - define one persona per customer profile, each scoped to the changes it cares about |

Flip any of them with `/spectra-persona-enable` / `/spectra-persona-disable`. A disabled persona costs nothing -
its checklist only loads when it's both enabled and scoped into a review.

## Low token cost

Spectra is deliberately terse - the whole protocol fits in a corner of the context window,
leaving room for your actual code:[^tokens]

<!-- spectra:tokens:start -->
| What loads into context | Characters | Tokens (≈4 ch) |
|---|---|---|
| Always-on host block (in `AGENTS.md`) | 691 | **173** |
| Protocol only (no personas needed) | 5,167 | **1,292** |
| Full protocol + core personas | 10,840 | **2,710** |
| Optional personas (load only when enabled) | 2,608 | **652** |
| Everything, incl. install/update skills | 33,561 | **8,390** |
<!-- spectra:tokens:end -->

## What lands in your repo

```
docs/
  spectra/protocol.md      the protocol (agent reads this)
  spectra/personas/*       review lenses (all shipped; enable the ones you want)
  spectra/personas.config  which review personas are enabled (yours to edit)
  specs/                   approved specs (NNNN-<slug>.md)
  plans/                   ordered build plans (NNNN-<slug>.md)
  feedback/                bugs & friction → lessons (NNNN-<slug>.md)
  overview/                living docs, updated every change
AGENTS.md                  points your agent at Spectra
.git/hooks/pre-commit      reflection reminder (copied in; not tracked)
```

## Repo layout (this repo)

- **`spectra/`** - the shippable source of truth: the plugin (skills, protocol, personas,
  hook). This is what gets installed.
- **`docs/`** - Spectra dogfooding itself: this repo built using its own protocol.
- **`assets/`** - the logo and protocol diagram (SVG) used by this README.
- **`scripts/`** - repo-local tooling, not shipped: `token-report.sh` keeps the token
  figures above honest (enforced by a `pre-commit` guard and `test.sh`).

## License

See [LICENSE](LICENSE).

[^tokens]: Measured from the Markdown in `spectra/` with a dependency-free ~4 chars/token
    heuristic, and kept in sync with the source automatically.
