<p align="center">
  <img src="assets/logo.svg" alt="Spectra" width="470">
</p>

<p align="center">
  <strong>Spec-driven development with learning feedback loops — installable into any repo in three commands.</strong>
</p>

AI-assisted development is fast but forgetful. The spec lives in a chat message, the
reasoning behind a decision evaporates, and the same mistakes come back next week. Spectra
fixes that by making intent explicit *before* you build and capturing learning *after* —
all in version control, all driven by your coding agent.

It's packaged as a native Claude Code plugin marketplace, so any repo can adopt the entire
protocol — the workflow, the review personas, the artifact structure, and a reflection
reminder — without copy-pasting a thing.

## Quick start

```text
/plugin marketplace add mattmaynes/spectra
/plugin install spectra@spectra
/spectra-install
```

That scaffolds your repo, drops in the protocol and review personas, installs a reflection
hook, and points your `AGENTS.md` at it. Later, pull updates with:

```text
/spectra-update
```

## The protocol

<p align="center">
  <img src="assets/protocol-flow.svg" alt="The Spectra loop: Route, Spec, Plan, Build, Test, Review, Merge, Reflect — learnings feed the next change" width="900">
</p>

Every change flows through one loop (full text: [`spectra/protocol.md`](spectra/protocol.md)):

| # | Step | What happens |
|---|---|---|
| 1 | **Route** | Trivial change? do it. New feature? write a **spec**. Bug or friction? write **feedback** (so it becomes a lesson). |
| 2 | **Spec** | Developer approves before any code is written (`docs/specs/NNNN-*.md`). |
| 3 | **Plan** | Multi-step work becomes an ordered plan (`docs/plans/NNNN-*.md`). |
| 4 | **Build** | Executed in a git worktree on a branch. |
| 5 | **Test** | Run the suite and fix until green **before committing** (no suite? add the test that proves the change). |
| 6 | **Review** | A PR is reviewed by four personas — **engineer, tester, architect, security** — who comment in a fixed format; `major`/`blocker` findings become learnings. |
| 7 | **Merge** | On approval. |
| 8 | **Reflect** | Before concluding, the **living docs** in `docs/overview/` (`project`, `features`, `architecture`, `learnings`) are updated. A non-blocking `pre-commit` hook nudges you if you forget. |

Step 8 is the differentiator: the **feedback → learnings** loop means the system gets
better at *your* codebase over time, instead of repeating itself.

## Own your protocol

Spectra isn't a SaaS, a runtime, or an API you call out to — it's a handful of Markdown
files that live **in your repo**, under your version control, read by the coding agent you
already use. That changes what you're adopting:

- **It's yours to edit.** `protocol.md` and the personas are plain prose. Tighten a step,
  add a persona, rename an artifact directory — it's a text change, reviewed like any other.
- **No third-party dependency.** Nothing phones home; there's no account and no lock-in.
  Uninstall the plugin and the `docs/` it scaffolded keep working on their own.
- **Opinionated, but flexible.** The defaults encode a real workflow (route → spec → … →
  reflect) so you don't start from a blank page — yet every default is just a starting
  point you can override per repo.
- **Versioned like code.** Because the protocol is committed, changes to *how you build*
  show up in `git log` right next to changes to *what you built*.

`/spectra-update` re-syncs only the files you haven't claimed as your own, so customizing
the protocol and pulling upstream improvements aren't mutually exclusive.

## Low token cost

Spectra is deliberately terse — the whole protocol fits in a corner of the context window,
leaving room for your actual code:[^tokens]

<!-- spectra:tokens:start -->
| What loads into context | Characters | Tokens (≈4 ch) |
|---|---|---|
| Always-on host block (in `AGENTS.md`) | 693 | **173** |
| Protocol only (no personas needed) | 4,013 | **1,003** |
| Full protocol + all four personas | 9,271 | **2,318** |
| Everything, incl. install/update skills | 18,459 | **4,615** |
<!-- spectra:tokens:end -->

## What lands in your repo

```
docs/
  spectra/protocol.md      the protocol (agent reads this)
  spectra/personas/*       review lenses
  specs/                   approved specs (NNNN-<slug>.md)
  plans/                   ordered build plans (NNNN-<slug>.md)
  feedback/                bugs & friction → lessons (NNNN-<slug>.md)
  overview/                living docs, updated every change
AGENTS.md                  points your agent at Spectra
.git/hooks/pre-commit      reflection reminder (copied in; not tracked)
```

## Repo layout (this repo)

- **`spectra/`** — the shippable source of truth: the plugin (skills, protocol, personas,
  hook). This is what gets installed.
- **`docs/`** — Spectra dogfooding itself: this repo built using its own protocol.
- **`assets/`** — the logo and protocol diagram (SVG) used by this README.
- **`scripts/`** — repo-local tooling, not shipped: `token-report.sh` keeps the token
  figures above honest (enforced by a `pre-commit` guard and `test.sh`).

## License

See [LICENSE](LICENSE).

[^tokens]: Measured from the Markdown in `spectra/` with a dependency-free ~4 chars/token
    heuristic, and kept in sync with the source automatically.
