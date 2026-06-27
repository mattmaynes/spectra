# 0009 - Plugin versioning & releases (plan)

Source: `docs/specs/0009-plugin-versioning-and-releases.md`. Supersedes closed PR #16.

## The seven version-bearing manifests
| File | `version` location |
|---|---|
| `.claude-plugin/marketplace.json` | `plugins[0].version` |
| `.agents/plugins/marketplace.json` | `plugins[0].version` |
| `.cursor-plugin/marketplace.json` | `plugins[0].version` |
| `spectra/.claude-plugin/plugin.json` | top-level `version` |
| `spectra/.codex-plugin/plugin.json` | top-level `version` |
| `spectra/.cursor-plugin/plugin.json` | top-level `version` |
| `spectra/gemini-extension.json` | top-level `version` |

Each has **exactly one** `"version"` token -> read/write keys on it. All seven are at `1.0.2`.

## Steps
1. **`VERSION`** (root) - single line `1.0.2`.
2. **`scripts/bump-version.sh`** (`chmod +x`), ASCII-only (Trellis bans em-dashes in non-.md):
   - `ROOT="${SPECTRA_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"`; manifest list as above.
   - `--help`/`-h`: usage. no arg: `cat VERSION`. `--check`: each manifest's lone `"version"`
     extracted (guard exactly one occurrence, file parses as JSON), all compared to `VERSION`;
     print mismatches; exit 1 on any drift/missing, else 0. `X.Y.Z`: validate
     `^[0-9]+\.[0-9]+\.[0-9]+$`; substitute the single version token in every manifest IN MEMORY,
     validate all parse, then commit to disk and write `VERSION` last (no half-bumped tree);
     re-run `--check` to confirm convergence.
3. **`.github/workflows/ci.yml`** - append a `release` job: `if: github.event_name == 'push'`,
   `needs: [test, readme-drift]`, job-scoped `permissions: { contents: write }`, `env: GH_TOKEN:
   ${{ github.token }}`. Read `v="$(cat VERSION)"`; if `gh release view "$v"` 404s, run
   `gh release create "$v" --target "$GITHUB_SHA"` with `--notes-file "docs/releases/$v.md"` when
   that file exists, else `--generate-notes`. Idempotent; only fires on a new `VERSION`.
4. **`docs/releases/README.md`** - document the convention: `docs/releases/<x.y.z>.md`'s first
   non-heading line becomes the README "What's new" headline (consumed by `whats-new.yml`); the
   file is the Release body. No back-seeding of 1.0.0-1.0.2 (already published).
5. **`test.sh`** - new step (after step 9, before commit-msg step renumber as needed):
   - `bump-version.sh --check` on the real tree -> expect 0.
   - reject `v1.2.3` `1.2` `nope` `1.2.3.4` `""` (exit non-zero each).
   - sandbox: copy the 7 manifests + `VERSION` into `$T` preserving paths, `SPECTRA_ROOT=$T
     bump-version.sh 9.9.9`, assert every copy + `$T/VERSION` reads `9.9.9` and `SPECTRA_ROOT=$T
     bump-version.sh --check` exits 0, and the **real** `VERSION` is untouched.
6. **Identity** - `owner` -> `{ "name": "rogueoak" }` (drop email) in the 3 marketplaces;
   `author` -> `{ "name": "rogueoak" }` in the 3 `plugin.json` (gemini-extension.json has no
   author field). Preserve formatting; confirm all parse.
7. **`AGENTS.md`** - "Releasing" subsection **outside** the `spectra:start/end` block: bump via
   `scripts/bump-version.sh X.Y.Z`, write `docs/releases/<v>.md`, PR, squash-merge -> CI tags
   `x.y.z` and publishes the Release; `whats-new.yml` refreshes the README headline.
8. **Reflect** - `docs/overview/features.md` (versioning + auto-release capability),
   `docs/overview/architecture.md` (release job, `VERSION` source-of-truth, `bump-version.sh`
   under repo-local tooling, identity now `rogueoak`).

## Verify
- `./test.sh` ends `PASS` (run **before** commit).
- `python3 -m json.tool` parses all 7 manifests after the identity edit.
- `scripts/token-report.sh --check` still passes (JSON-only changes; no Markdown drift).
- `scripts/bump-version.sh --check` exits 0 on the committed tree.
- `ci.yml` is valid YAML; the `release` job is push-only and job-scoped to `contents: write`.

## Review
Personas (per `personas.config` = engineer/tester/architect/security):
- **engineer** - shell/CI logic, the in-memory-then-commit write, the notes-file fallback.
- **tester** - test.sh additions + observable release behavior.
- **architect** - new release subsystem, `VERSION` source-of-truth boundary, whats-new compose.
- **security** - CI gains `contents: write`; a privileged automation that tags/publishes -
  confirm least-privilege (job-scoped), ambient `GITHUB_TOKEN` only, no untrusted interpolation.
