# Spectra

**Spec-driven development with learning feedback loops — installable into any repo in three commands.**

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

Every change flows through one loop (full text: [`spectra/protocol.md`](spectra/protocol.md)):

1. **Route** — trivial change? do it. New feature? write a **spec**. Bug or friction? write
   **feedback** (so it becomes a lesson).
2. **Spec** → developer approves before any code is written (`docs/specs/NNNN-*.md`).
3. **Plan** → multi-step work becomes an ordered plan (`docs/plans/NNNN-*.md`).
4. **Build** → executed in a git worktree on a branch.
5. **Test** → run the suite and fix until green **before committing** (no suite? add the
   test that proves the change).
6. **Review** → a PR is reviewed by four personas — **engineer, tester, architect,
   security** — who comment in a fixed format; `major`/`blocker` findings become learnings.
7. **Merge** on approval.
8. **Reflect** → before concluding, the **living docs** in `docs/overview/`
   (`project`, `features`, `architecture`, `learnings`) are updated. A non-blocking
   `pre-commit` hook nudges you if you forget.

Step 8 is the differentiator: the **feedback → learnings** loop means the system gets
better at *your* codebase over time, instead of repeating itself.

## Low token cost

Spectra is deliberately terse — the whole protocol fits in a corner of the context window,
leaving room for your actual code:

| What loads | Rough size |
|---|---|
| Always-on host block (in `AGENTS.md`) | **~175 tokens** |
| Full protocol + all four personas | **~1.6k tokens** |
| Everything, including the install/update skills | **~2.6k tokens** |

(Rough estimates at ~4 chars/token; measured from `spectra/`.) Reproduce with `./test.sh`'s
sibling check or `cat spectra/protocol.md spectra/agents.md spectra/personas/*.md | wc -c`.

## What lands in your repo

```
docs/
  spectra/protocol.md      the protocol (agent reads this)
  spectra/personas/*       review lenses
  specs/  plans/  feedback/   numbered artifacts (NNNN-<slug>.md)
  overview/                living docs, updated every change
AGENTS.md                  points your agent at Spectra
```

## Repo layout (this repo)

- **`spectra/`** — the shippable source of truth: the plugin (skills, protocol, personas,
  hook). This is what gets installed.
- **`docs/`** — Spectra dogfooding itself: this repo built using its own protocol.

## License

See [LICENSE](LICENSE).
