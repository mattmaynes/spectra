# Release notes

One file per published version: `docs/releases/<x.y.z>.md` (bare semver, no `v`). The
`Release` workflow uses it as the GitHub Release body when you bump `VERSION` to that number; if
the file is absent it falls back to auto-generated notes from your Conventional Commit titles.

This file is shipped and owned by Trellis's plugin-release template (refreshed by
`trellis-update`). The per-version `<x.y.z>.md` notes are yours.

## Convention

- **The first non-heading line is the headline.** The "What's new" automation extracts it
  verbatim into the README, so make it a single plain sentence - no leading `#`, no list marker.
  Everything after it is the Release body.
- Keep it ASCII and in the repo's voice.
- The auto-generated fallback (no `<x.y.z>.md`) yields a raw commit bullet as the headline, so
  write the file for any release whose headline matters.

## Releasing

1. `scripts/bump-version.sh X.Y.Z` - rewrites `VERSION` + every manifest in `.version-manifests`.
2. Write `docs/releases/X.Y.Z.md` (headline first, then details).
3. Open a PR and squash-merge to `main`.
4. Your CI workflow runs; on success the `Release` workflow tags `X.Y.Z` and publishes the
   Release from your notes. The "What's new" block then refreshes from the headline.
