# 0001 — Spectra protocol & marketplace

## Problem
AI-assisted development drifts: specs, decisions, and lessons live in chat and are lost.
Teams want a repeatable loop that captures intent up front and learning at the end, and a
way to drop that loop into any repo.

## Outcome
A repo that is a native Claude Code plugin marketplace. A consumer runs
`/plugin marketplace add` → `/plugin install spectra@spectra` → `/spectra-install` and their
repo gains: the protocol, review personas, the `docs/` artifact tree, a reflection hook, and
an AGENTS.md pointer. `/spectra-update` keeps it current.

## Scope
- In: marketplace + plugin manifests; install/update skills; `protocol.md`; four personas;
  reflection `pre-commit` hook; `agents.md` host block; this repo dogfooding itself.
- Out: language-specific tooling, CI wiring, hosted services.

## Approach
Two halves: `spectra/` is the shippable source of truth (the plugin); `docs/` is this
repo's installed instance. Keep the protocol and personas terse to minimize token cost.
This repo's `docs/spectra/` are symlinks to `spectra/` to stay DRY (consumers get copies).

## Acceptance
- [ ] `marketplace.json` and `plugin.json` parse and resolve `source: ./spectra`.
- [ ] Skills `spectra-install` / `spectra-update` are present and self-describing.
- [ ] `pre-commit` warns on spec/plan/feedback change without an overview change, exits 0.
- [ ] `protocol.md` covers route → spec → plan → build → review → merge → reflect.
- [ ] Four personas exist. README explains the value with a quick start.
