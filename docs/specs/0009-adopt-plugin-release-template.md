# 0009 - Adopt the Trellis plugin-release template

## Problem
Spectra hand-rolls its release mechanics. Its version is duplicated across seven manifests with no
single source of truth and no drift guard (two were stranded at `0.1.1` until `feedback/0013`-era
fixes), releases are cut by hand, and its "What's new" automation is a bespoke
`scripts/whats-new.sh` + a `release: [published]` workflow that only ever worked because releases
were created manually with a personal token. Trellis now ships exactly this machinery as the
opt-in **plugin-release** template (Trellis 0.4.1), already dogfooded and proven there. Spectra
should consume it so the two repos operate identically and Spectra stops maintaining its own copy.

## Outcome
- Spectra installs the template via `/trellis-install --template plugin-release`: the owned files
  (`scripts/bump-version.sh`, `scripts/whats-new.sh`, `.github/workflows/release.yml`,
  `.github/workflows/whats-new.yml`, `docs/releases/README.md`) land at functional paths and are
  tracked in `docs/rules/.trellis-templates` + `docs/rules/.trellis-owned-plugin-release`, so
  `/trellis-update` keeps them current. Spectra owns only `VERSION`, `.version-manifests`, and the
  per-release notes.
- `VERSION` is the single source of truth (`1.0.2`); `.version-manifests` lists Spectra's seven
  manifests; `bump-version.sh --check` is wired into `test.sh` as the CI drift guard.
- Releases automate: merging a `VERSION` bump runs CI, then `release.yml` (on `workflow_run` of
  `CI`) tags + publishes, then `whats-new.yml` (on `workflow_run` of `Release`) refreshes the
  README headline through a self-merged PR.
- Spectra's bespoke whats-new is retired: the `release: [published]` workflow and
  `spectra:whats-new:start/end` markers are replaced by the template's `workflow_run` workflow and
  neutral `whats-new:start/end` markers.

## Scope
- **In:**
  - Install the template (owned + seed) and record it in the registry/owned-list.
  - Seed `VERSION` = `1.0.2`; write `.version-manifests` with Spectra's seven manifests.
  - Migrate the README "What's new" markers `spectra:whats-new:*` -> `whats-new:*`.
  - `test.sh`: trim section 10 to just the README marker-pair integrity check (the script is now
    owned + unit-tested in Trellis); add section 11 running `bump-version.sh --check`.
  - Reflect in `docs/overview/architecture.md` + `features.md` (release automation now comes from
    the owned template; identical pipeline to Trellis).
- **Out:**
  - Changing any shipped `spectra/` behavior - the manifests keep version `1.0.2`; token figures
    are untouched (the new files live at functional paths, not under `spectra/`).
  - Rewriting historical `docs/specs/0008` / `docs/plans/0008` (point-in-time records of the old
    bespoke whats-new).
  - The first automated release itself - the pipeline fires on the next `VERSION` bump.

## Approach
- **Consume, do not fork.** The template's owned files are copied verbatim and never hand-edited;
  Spectra's only inputs are `VERSION` and `.version-manifests`. A future template fix reaches
  Spectra through `/trellis-update`, exactly as rules do. This is the whole point of adopting
  rather than keeping a parallel implementation.
- **Name alignment, not edits.** `release.yml` waits on a workflow named `CI` and `whats-new.yml`
  on one named `Release`; Spectra's CI is already `CI` and the template's release workflow is
  `Release`, so no owned file needs a Spectra-specific edit.
- **Retire the duplicate.** The bespoke `whats-new.sh`/`whats-new.yml` are overwritten by the
  owned versions (the install clobbers owned paths); the README markers and `test.sh` section 10
  are migrated to match. Spectra stops testing the now-owned script (Trellis does).

## Acceptance
- [ ] `docs/rules/.trellis-templates` lists `plugin-release`; `.trellis-owned-plugin-release` lists
      the five owned files; all five are present at their functional paths.
- [ ] `VERSION` is `1.0.2`; `.version-manifests` lists the seven manifests; `bump-version.sh
      --check` exits 0.
- [ ] README carries exactly one `<!-- whats-new:start/end -->` pair; no `spectra:whats-new` marker
      remains in the README.
- [ ] `whats-new.yml` triggers on `workflow_run` of `Release`; `release.yml` on `workflow_run` of
      `CI`; both job-scoped write + SHA-pinned.
- [ ] `test.sh` passes (section 10 marker check + section 11 `--check`); `token-report.sh --check`
      still passes; compliance clean.
- [ ] `docs/overview/architecture.md` + `features.md` describe the owned template pipeline.
