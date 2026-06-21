# 0005 — Optional advanced personas & enable/disable toggles

Builds on `0004` (the create-on-demand `user.md` persona, merged via PR #8). Branch
`feat/advanced-personas`, based on `main` (which now carries #7's gated review step and #8's
file-presence persona rule).

> **Revised during review (PR #10).** This spec was originally written around "active = persona
> file present" with the optional personas under `personas/optional/` and a "refresh-only-present"
> update. The 📐 architect review showed that overloaded the file with two meanings (installed vs.
> enabled) and made `spectra-update` non-additive. The shipped design instead **ships all persona
> files and tracks the enabled set in a developer-owned `docs/spectra/personas.config`** (seeded
> if absent, never overwritten); update copies all files additively. The final mechanism lives in
> `docs/overview/architecture.md` and `feedback/0006`; passages below that still say
> "file presence" / `optional/` reflect the original approach.

## Problem
Spectra ships four review personas (engineer 🔧, tester 🧪, architect 📐, security 🔒) and they
are effectively always-on for any non-trivial change. Two gaps:

1. **No room for specialist perspectives.** Some changes deserve a *designer*, a *compliance*,
   or an *analytics* review — but most repos/changes don't, and baking those checklists into the
   always-considered set would tax every review (more sub-agents, more tokens) for a perspective
   that rarely applies.
2. **No way to tune the active set.** A repo can't say "I don't want a security persona" or
   "turn on the designer." The set is fixed.

We want extra personas that are **available but off by default and cost zero tokens until
enabled**, and a way to toggle *any* persona on or off — with the four core personas on by
default.

## Outcome
- Three new **optional** personas ship with the plugin but are **not installed** by default:
  - **designer 🎨** — visual consistency: element sizing (buttons, inputs), spacing/margins/
    padding, design-token use over ad-hoc styles, and minimizing confusing end-user choices
    (competing CTAs, misleading button text).
  - **compliance ⚖️** — accessibility standards, PII minimization, i18n coverage (all
    user-facing text translated where i18n exists), and GDPR/CCPA obligations.
  - **analytics 📊** — tracking coverage (events on clicks/inputs/key actions), measurable
    outcomes for complex flows, and measurability of success behind feature gates.
- **Activation = a config allowlist.** *(Revised during review — see the banner above; the
  original "active = file presence" approach was replaced.)* All personas ship as files in
  `docs/spectra/personas/`; the **active** set is the slugs listed in
  `docs/spectra/personas.config` (developer-owned, default = the four core). A disabled persona's
  checklist is never scoped into a review, so **not enabled = not loaded = ~zero tokens.**
- **`/spectra-enable [persona]`** copies an available persona's file into
  `docs/spectra/personas/`; **`/spectra-disable [persona]`** removes it. Called **without an
  argument**, each lists the relevant personas as a **numbered list** and acts on the
  developer's reply (single number, or several). Any toggleable persona can be enabled or
  disabled — including the four core ones — so a repo can drop security or add designer freely.
- **Toggles survive `/spectra-update`.** Update **refreshes only the personas already present**
  in the instance (re-copying each from source if a source exists) instead of copying the whole
  shipped set. A disabled persona stays gone; an enabled optional one gets refreshed; a
  developer-owned `user.md` (no source) is left untouched — one rule replaces `0004`'s
  "glob has no `user.md`" reasoning and the new "don't re-enable" need.

## Scope
- **In:**
  - `spectra/personas/optional/{designer,compliance,analytics}.md` — three new persona files in
    the same shape as the shipped four (a `See persona.md` line + an opinionated checklist).
    Placed in an `optional/` subdir so install/update's top-level `*.md` glob skips them and the
    "ships but off by default" intent is structural, not a maintained list.
  - `spectra/skills/spectra-enable/SKILL.md` and `spectra/skills/spectra-disable/SKILL.md` — two
    terse skills (kept minimal to hold token cost down). Discover the catalog from the source
    layout (no hardcoded persona list): enable lists optional personas not yet present; disable
    lists currently-present toggleable personas.
  - `spectra/skills/spectra-update/SKILL.md` — change step 1's persona copy to **refresh
    only present** personas (the loop above); update the preservation note to the unified rule.
  - `spectra/protocol.md` — §5.4: keep the four core triggers + `user`; add **one** generic
    line so reviewers also scope in any *other* present persona whose facet the change touches
    (read its title/intro to decide). No per-optional-persona enumeration — that keeps the
    always-loaded protocol size flat regardless of how many optional personas exist.
  - `spectra/skills/spectra-install/SKILL.md` — Confirm step points at `/spectra-enable` as an
    optional next step (alongside the existing `/spectra-setup` pointer). Install still copies
    only the four core.
  - `spectra/.claude-plugin/plugin.json` — `description` mentions `/spectra-enable` and
    `/spectra-disable`.
  - `test.sh` — (a) optional personas exist in source under `personas/optional/` and are **not**
    copied by the install glob; (b) new persona files have a `See persona.md` line + a checklist;
    (c) rewrite the update test to the refresh-only-present loop and assert: disabled core
    persona stays absent, enabled optional persona refreshes, `user.md` preserved; (d)
    enable/disable skills have valid frontmatter (covered by the existing step-2 loop).
  - Repo-local: regenerate the README token block (`scripts/token-report.sh --write`) and
    reflect into `docs/overview/` (`features`, `architecture`, `learnings`).
- **Out:**
  - Auto-enabling any optional persona, or auto-detecting "this repo has a UI / collects PII /
    uses feature gates" to suggest one. Enabling is an explicit developer action.
  - Changing the four core persona *checklists* or *how* reviews are spawned — only *which*
    personas are eligible and how the active set is configured.
  - A config file / registry for the active set (a file-presence model is simpler, matches
    `0004`, and keeps the disabled state at literally zero always-loaded tokens).
  - Wiring any optional persona into *this* repo's own dogfood reviews (this repo has no UI;
    optional, not required).

## Approach
- **Why file-presence, not a config list.** `0004` already made "active = file present" the
  norm for `user.md`. Extending it to optional personas means: disabled = the file isn't in the
  repo, so it is never read and costs nothing; the protocol needs no per-persona switches; and
  enable/disable are just "copy a file in" / "remove a file." The shipped default set is defined
  by the source layout (`personas/*.md` = on by default; `personas/optional/*.md` = available),
  so there's no list to keep in sync.
- **`spectra-update` becomes "refresh only present."**
  ```sh
  for f in docs/spectra/personas/*.md; do
    b=$(basename "$f")
    for cand in "$SRC/personas/$b" "$SRC/personas/optional/$b"; do
      [ -f "$cand" ] && cp "$cand" "$f" && break
    done
  done
  ```
  `persona.md` and any present core persona refresh from `$SRC/personas/`; an enabled optional
  one refreshes from `$SRC/personas/optional/`; `user.md` (no source) is skipped; a disabled
  persona (no file) is never recreated. This single rule replaces both `0004`'s preservation
  reasoning and the new "don't re-enable a disabled persona" requirement.
- **`spectra-enable` / `spectra-disable` skills (terse).**
  - *enable* `<p>`: resolve `<p>.md` from `$SRC/personas/optional/` (or `$SRC/personas/` to
    re-add a disabled core one); `cp` into `docs/spectra/personas/`. No arg → number the
    personas available to enable (in source, not yet present) and act on the reply.
  - *disable* `<p>`: `rm docs/spectra/personas/<p>.md` if present. No arg → number the present
    toggleable personas and act on the reply.
  - Both **refuse `persona`** (the shared contract, not a reviewer) and leave `user.md` to
    `spectra-setup` (don't delete developer-owned content). Confirm the resulting active set.
- **Protocol scoping line.** One added sentence after the core triggers: *"Also scope in any
  other persona present in `docs/spectra/personas/` whose facet the change touches — read its
  title/intro to decide."* Optional personas thus participate exactly like the core ones once
  present, with no always-loaded cost when absent.
- **Token honesty.** The README rows stay meaningful: "protocol + core personas" is unchanged by
  optional personas (they don't load); "Everything" grows by the two new skills. Regenerate via
  `token-report.sh --write`; if useful, note that optional personas ship but load only when
  enabled.

## Acceptance
- [ ] `spectra/personas/optional/{designer,compliance,analytics}.md` exist, each with a
      `See persona.md` line and a concrete checklist matching the user's described focus areas.
- [ ] A fresh `spectra-install` copies only the four core personas + `persona.md`; no optional
      persona lands in the instance (zero tokens until enabled).
- [ ] `/spectra-enable` with no arg lists the enable-able personas as a numbered list and, given
      a number/reply, copies that persona in; with an arg it enables directly.
- [ ] `/spectra-disable` with no arg lists present toggleable personas numbered and removes the
      chosen one(s); refuses `persona`; never deletes `user.md`.
- [ ] Any core persona can be disabled and stays disabled across a `spectra-update`; an enabled
      optional persona is refreshed by update; `user.md` is preserved.
- [ ] `spectra/protocol.md` §5.4 scopes in present non-core personas via one generic line, with
      no per-optional enumeration; always-loaded protocol size is essentially flat.
- [ ] `plugin.json` mentions `/spectra-enable` and `/spectra-disable`.
- [ ] `test.sh` passes (optional-not-installed, refresh-only-present, persona-shape, frontmatter
      cases), README token figures regenerated, `docs/overview/` updated.
