# Learnings

Process lessons and feedback distilled into guidance. Append as they arise (newest first).

- **Document the host's activation step, not just the package step.** The README's Claude
  quick start installed the plugin then jumped straight to `/spectra-install` — but in Claude
  Code a freshly installed plugin's commands aren't loaded until `/reload-plugins`, so the next
  step silently did nothing. An install walkthrough isn't complete at "package installed"; it's
  complete when the agent can *see* the new commands — include whatever the harness needs to
  load them, especially host-specific steps with no equivalent in the other tools' flows. — from
  [`feedback/0012`](../feedback/0012-reload-plugins-after-install.md)
- **A feedback loop only closes when the lessons are read back in.** The protocol told agents
  to *write* `overview/learnings.md` (§6 Reflect) but never to *read* it — so the learning
  store was write-only and an agent could repeat a logged mistake verbatim. Added **§0 Orient**:
  read `learnings.md` (and apply it), `features.md`, and `architecture.md` *before* routing any
  change. Treat `overview/` as input first, output last; recording a lesson is only half the
  loop — the protocol has to make the next agent consult it. The sibling of
  [`feedback/0010`](../feedback/0010-lesson-doesnt-auto-apply.md): that one says *applying* a
  just-written lesson is manual; §0 makes *reading* the store a standing step. — from
  [`feedback/0011`](../feedback/0011-orient-on-overview-docs.md)
- **A just-written lesson is most at risk in the very next change.** `feedback/0009` ("key a
  regression guard on the structural line, not adjacent text") landed in PR #11; the Gemini guard
  added in PR #12 immediately repeated it — grepping the TOML for the injection string anywhere
  instead of parsing it and asserting the `prompt` *value*. Recording a lesson isn't applying it:
  when you write another guard of the shape you just learned about, re-run the lesson against it
  before moving on. — from [`feedback/0010`](../feedback/0010-lesson-doesnt-auto-apply.md)
- **Presence-of-good is not absence-of-bad.** A `test.sh` guard for the tool-neutral `$SRC`
  asserted neutral tokens were present but never that the Claude-only form was gone — so the exact
  regression it claimed to block sailed through (neutrality lived in prose; the one executable line
  stayed Claude-only). When a text-assert guards a regression, key it on the structural line the
  regression would change and that the bad state can't also satisfy — and prefer making the
  behavior real (a concrete `SRC="${SPECTRA_SRC…` line to grep) over guarding intent that exists
  only in description. Extends [`feedback/0008`](../feedback/0008-assert-on-uninstructed-text.md).
  — from [`feedback/0009`](../feedback/0009-presence-asserts-miss-regressions.md)
- **Don't overload one signal with two questions — give each its own representation.** A persona
  being "active = file present" forced the file to answer both *"is it installed?"* and *"did the
  developer enable it?"*; `spectra-update` (wants every file) and `/spectra-disable` (wants a file
  gone) then pulled in opposite directions. Splitting them — Spectra-owned files always copied,
  enabled set in a developer-owned `personas.config` update never touches — let update stay
  additive *and* disables stick. When operations on a piece of state start fighting, it's usually
  carrying two meanings. — from [`feedback/0006`](../feedback/0006-update-becomes-non-additive.md)
- **A skill is an interface with untrusted input — validate it like code.** `spectra-disable`
  told the agent to `rm -f …/<persona>.md` from a user-supplied name with only a loose guard; a
  `../` could escape the personas dir. Prose that instructs an agent to delete/copy by name must
  spell out the input contract (bare-segment shape + allowlist membership) explicitly; "the
  agent will be careful" is not an access control. — from [`feedback/0007`](../feedback/0007-skill-input-validation.md)
- **When you can't execute the artifact, assert on its text.** The update test re-implemented
  the skill's loop inline, so a regression to the old bulk-copy glob would stay green. For
  behavior that lives in an instruction file the suite can't run, add must-contain/must-not-contain
  checks on the file itself — a test that copies the logic only tests the copy. — from
  [`feedback/0008`](../feedback/0008-assert-on-uninstructed-text.md)
- **A learning is a correction, not a feature write-up.** The Reflect step on PR #8 logged
  "never ship `user.md` so update can't clobber it" as a learning — but that's just *how the
  feature works*, already captured in `architecture.md`. The developer rejected it: only record
  a learning when feedback or friction tells you to do something *differently*; restating what
  you shipped is `features.md`/`architecture.md`, and inventing a "learning" to fill the section
  is noise. — from [`feedback/0005`](../feedback/0005-learning-vs-feature.md)
- **Put the cheapest outcome first — but don't let the guidance outweigh what it saves.**
  Persona selection now gates on "pure docs, no behavior change? → no personas" before the
  add-on triggers (engineer/tester/architect/security), decided from the diff alone, before
  reading any persona file — the runtime win is spawning fewer sub-agents. The protocol text
  is read on *every* change, so the rewrite also had to be **smaller** than the list it
  replaced: a first ASCII-art-tree draft nearly doubled the block and was rejected for that
  reason. Keep the "why" in the feedback doc (read once), the rule in the protocol (read
  always). — from [`feedback/0004`](../feedback/0004-persona-decision-tree.md)
- **A local-only guard isn't a guarantee — promote it to CI.** The README token-drift check
  lived solely in an *untracked* `.git/hooks/pre-commit`, so anyone without the hook (fork PRs,
  fresh clones) bypassed it silently. CI (`.github/workflows/ci.yml`) re-runs `test.sh` and the
  same `--check` so the standard is enforced where everyone can see it, not just on the
  original author's machine. Keep CI checkers dependency-free and dogfoodable
  (`check-commit-msg.sh` mirrors `token-report.sh`), and feed untrusted inputs like a PR title
  through `env:` — never interpolate them into the run command.
- **A repeated instruction belongs in one place.** The review-comment contract was copy-pasted
  into all four personas; factor it into a shared `personas/persona.md` and let each persona
  carry only its distinct lens (with a per-persona emoji for attribution). Make persona
  checklists opinionated and actionable, not generic. — from [`feedback/0003`](../feedback/0003-persona-depth-and-shared-format.md)
- **A marketing claim that can rot should be machine-checked.** The README's "low token
  cost" is a selling point, so its numbers are generated from `spectra/` and enforced by a
  `pre-commit` guard + `test.sh` rather than hand-maintained — the old hand-written "~2.6k"
  had already drifted (~2.9k actual). Generate, don't transcribe; gate drift at commit time.
- **Write hook/CI scripts for the POSIX tools actually present.** macOS ships **BSD awk**,
  which rejects multi-line strings passed via `-v` ("newline in string"). Pass multi-line
  data through a temp file read with `getline` instead. Keep the token heuristic
  dependency-free (`wc -c`, `~4 chars/token`) so the hook runs anywhere, no tokenizer.
- **Scope reviews; comment inline; isolate builds.** Triage which personas review (don't run
  all four by reflex); post review findings as **inline** PR comments on the relevant lines;
  build changes in a **git worktree** off `main`. — from [`feedback/0002`](../feedback/0002-review-and-workflow-refinements.md)
- **Make contracts explicit, not implicit.** Test *before* committing (protocol step 5), and
  give review comments a fixed shape (`_Spectra <Persona>_` / severity / comment). Treat
  every `major`/`blocker` as feedback. — from [`feedback/0001`](../feedback/0001-testing-and-review-format.md)
