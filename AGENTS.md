# AGENTS.md

This repo **is** the source of Spectra (see [`README.md`](README.md)). It is also built
*using* Spectra — it dogfoods its own protocol. The shippable plugin lives in `spectra/`;
this repo's installed instance lives in `docs/`.

<!-- spectra:start -->
## Spectra protocol

This repo uses **Spectra** — spec-driven development with learning feedback loops.
Read `docs/spectra/protocol.md` and follow it for every change:

- **Trivial** change → implement directly. **Feature** → spec in `docs/specs/` (get
  approval first). **Bug/feedback** → doc in `docs/feedback/`.
- Multi-step work → a plan in `docs/plans/`, built in a worktree, **tested before commit**,
  reviewed by the personas in `docs/spectra/personas/` via PR comments, merged on approval.
- **Before concluding, reflect**: update the relevant `docs/overview/` living docs
  (`project`, `features`, `architecture`, `learnings`).
<!-- spectra:end -->
