# 0007 — Plugin versioning & releases (plan)

Source: `docs/specs/0007-plugin-versioning-and-releases.md`.

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

Each has **exactly one** `"version"` token → read/write keys on it.

## Steps
1. **`VERSION`** (root) — single line `0.1.0`.
2. **`scripts/bump-version.sh`** (`chmod +x`):
   - `ROOT="${SPECTRA_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"`.
   - Manifest list as above (relative to `ROOT`).
   - `--help`/`-h`: usage.
   - no arg: print `cat "$ROOT/VERSION"`.
   - `--check`: for each manifest, extract its lone `"version": "X"` (guard: exactly one
     occurrence, file parses as JSON); compare all to `VERSION`; print each mismatch; exit 1 on
     any drift or missing file, else 0.
   - `X.Y.Z`: validate `^[0-9]+\.[0-9]+\.[0-9]+$` (else error+exit 1); write `VERSION`; for each
     manifest do a format-preserving substitution of the single version token via `python3`
     (regex on the one `"version"` value), then assert it still `json.load`s. Re-run the
     `--check` logic at the end to confirm convergence.
3. **`.github/workflows/ci.yml`** — append a `release` job (see spec). `if: github.event_name ==
   'push'`, `needs: [test, readme-drift]`, `permissions: { contents: write }`, `env: GH_TOKEN:
   ${{ github.token }}`; guarded `gh release view` → `gh release create "$v" --target
   "$GITHUB_SHA" --generate-notes`.
4. **`test.sh`** — new step (after step 9):
   - `bump-version.sh --check` on the real tree → expect 0.
   - reject `v1.2.3` `1.2` `nope` `1.2.3.4` `""`; accept-and-revert is unnecessary — use a
     sandbox: copy the 7 manifests + `VERSION` into `$T` preserving paths, `SPECTRA_ROOT=$T
     bump-version.sh 9.9.9`, assert every copy + `$T/VERSION` now reads `9.9.9` and
     `SPECTRA_ROOT=$T bump-version.sh --check` exits 0, and the **real** `VERSION` is untouched.
5. **Identity** — set `owner`→`{ "name": "rogueoak" }` (drop email) in the 3 marketplaces;
   `author`→`{ "name": "rogueoak" }` in the 3 `plugin.json`. (`gemini-extension.json` has no
   author field.) Keep each file's existing formatting; confirm all still parse.
6. **`AGENTS.md`** — add a "Releasing" subsection **outside** the `spectra:start/end` block:
   bump via `scripts/bump-version.sh X.Y.Z`, PR, squash-merge → CI tags `x.y.z` and publishes
   the Release from the conventional-commit titles.
7. **Reflect** — `docs/overview/features.md` (versioning + auto-release capability),
   `docs/overview/architecture.md` (the release job, `VERSION` source-of-truth, `bump-version.sh`
   under repo-local tooling, identity now `rogueoak`).

## Verify
- `./test.sh` ends `PASS` (run **before** commit).
- `python3 -m json.tool` parses all 7 manifests after the identity edit.
- `scripts/token-report.sh --check` still passes (JSON-only changes; no Markdown drift).
- `scripts/bump-version.sh --check` exits 0 on the committed tree.

## Review
Personas (per `personas.config` = engineer/tester/architect/security): **engineer** (shell/CI
logic), **tester** (test.sh + observable release behavior), **architect** (new release
subsystem & source-of-truth boundary), **security** (CI gains `contents: write`; a privileged
automation that tags/publishes — confirm least-privilege, no untrusted interpolation, ambient
token only).
