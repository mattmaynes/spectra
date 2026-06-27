# Release notes

One file per published version: `docs/releases/<x.y.z>.md` (bare semver, no `v`). The CI
`release` job in `.github/workflows/ci.yml` uses it as the GitHub Release body when you bump
`VERSION` to that number; if the file is absent it falls back to `--generate-notes` (the
conventional-commit titles since the previous tag).

## Convention

- **The first non-heading line is the headline.** `whats-new.yml` extracts it verbatim and
  writes it into the README "What's new" block, so make it a single, plain sentence - no leading
  `#` heading, no list marker. Everything after it is the Release body.
- Keep it ASCII and in the repo voice (see `docs/rules/language.md`).

## Releasing

1. `scripts/bump-version.sh X.Y.Z` - rewrites `VERSION` + all seven manifests.
2. Write `docs/releases/X.Y.Z.md` (headline first, then the details).
3. Open a PR, squash-merge to `main`.
4. CI tags `X.Y.Z` at the merge commit and publishes the Release from your notes; the
   `release` event then refreshes the README "What's new" headline automatically.

## Example

```
A protocol clarification: learnings must generalize past the change that taught them.

## What changed
Section 6 (Reflect) now requires a learning to outlive the change that taught it...
```

Releases 1.0.0-1.0.2 predate this convention and were published by hand; they have no file here.
