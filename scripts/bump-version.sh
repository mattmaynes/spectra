#!/bin/sh
# Plugin version bump - keeps a marketplace plugin's version honest across every manifest.
#
# Shipped by Trellis's "plugin-release" template and OWNED by Trellis: re-run
# `trellis-update` to refresh it. Do not hand-edit; your edits are overwritten by design.
#
# The single source of truth is the root VERSION file. The manifests that must agree are
# listed, one path per line, in the root `.version-manifests` (which you own and edit). Each
# manifest must contain EXACTLY ONE "version" token; this script keeps them identical via a
# format-preserving surgical substitution - no JSON re-serialize that would reflow the files.
#
# Dependency-light: POSIX sh + python3, so it runs identically in CI and a local shell.
#
# Usage:
#   scripts/bump-version.sh                 print the current version (cat VERSION)
#   scripts/bump-version.sh --check         verify VERSION == every manifest's version (exit 1 on drift)
#   scripts/bump-version.sh X.Y.Z           write VERSION + all manifests to X.Y.Z (semver, no v)
#   scripts/bump-version.sh -h|--help       usage
set -eu

# Root override (BUMP_VERSION_ROOT) lets a test suite run this against a sandbox tree.
ROOT="${BUMP_VERSION_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

manifests_file="$ROOT/.version-manifests"

# Read the manifest list: one path per line, '#' comments and blank lines ignored.
read_manifests() {
  [ -f "$manifests_file" ] || {
    echo "bump-version: missing $manifests_file (list one manifest path per line)" >&2
    exit 1
  }
  sed -e 's/#.*$//' -e 's/[[:space:]]*$//' "$manifests_file" | grep -v '^[[:space:]]*$' || true
}

usage() {
  echo "usage: $0 [--check | X.Y.Z]"
  echo "  (no arg)   print the current version"
  echo "  --check    verify VERSION matches every manifest's version (exit 1 on drift)"
  echo "  X.Y.Z      write VERSION + every listed manifest to X.Y.Z (semver, no 'v' prefix)"
}

# check -> compare VERSION against every manifest's lone version token; exit 1 on any
# drift/missing/malformed, else 0.
check() {
  ROOT="$ROOT" MANIFESTS="$(read_manifests)" python3 - <<'PY'
import json, os, re, sys

root = os.environ["ROOT"]
manifests = [m for m in os.environ["MANIFESTS"].split("\n") if m]
drift = False

vfile = os.path.join(root, "VERSION")
try:
    want = open(vfile).read().strip()
except OSError as e:
    print(f"bump-version: cannot read VERSION: {e}", file=sys.stderr)
    sys.exit(1)

if not manifests:
    print("bump-version: .version-manifests lists no manifests", file=sys.stderr)
    sys.exit(1)

for rel in manifests:
    path = os.path.join(root, rel)
    try:
        raw = open(path).read()
    except OSError:
        print(f"bump-version: missing manifest: {rel}")
        drift = True
        continue
    try:
        json.loads(raw)
    except Exception as e:
        print(f"bump-version: {rel} does not parse as JSON: {e}")
        drift = True
        continue
    found = re.findall(r'"version"\s*:\s*"([^"]*)"', raw)
    if len(found) != 1:
        print(f"bump-version: {rel} has {len(found)} version tokens (expected exactly 1)")
        drift = True
        continue
    if found[0] != want:
        print(f"bump-version: {rel} version {found[0]} != VERSION {want}")
        drift = True

sys.exit(1 if drift else 0)
PY
}

# write NEW -> surgically substitute the single version token in each manifest, then VERSION.
write() {
  new="$1"
  # Validate every manifest substitution IN MEMORY first and write the files only once all
  # pass; write VERSION LAST. So a guard failure (a stray second "version" token, a file that
  # wouldn't parse) aborts with nothing changed on disk - never a half-bumped tree.
  ROOT="$ROOT" MANIFESTS="$(read_manifests)" NEW="$new" python3 - <<'PY'
import json, os, re, sys

root = os.environ["ROOT"]
manifests = [m for m in os.environ["MANIFESTS"].split("\n") if m]
new = os.environ["NEW"]

if not manifests:
    print("bump-version: .version-manifests lists no manifests", file=sys.stderr)
    sys.exit(1)

pending = {}
for rel in manifests:
    path = os.path.join(root, rel)
    try:
        raw = open(path).read()
    except OSError as e:
        print(f"bump-version: missing manifest: {rel} ({e})", file=sys.stderr)
        sys.exit(1)
    updated, n = re.subn(
        r'("version"\s*:\s*")[^"]*(")',
        lambda m: m.group(1) + new + m.group(2),
        raw,
    )
    if n != 1:
        print(f"bump-version: {rel} had {n} version tokens (expected exactly 1)", file=sys.stderr)
        sys.exit(1)
    try:
        json.loads(updated)
    except Exception as e:
        print(f"bump-version: {rel} would not parse after substitution: {e}", file=sys.stderr)
        sys.exit(1)
    pending[path] = updated

for path, content in pending.items():
    open(path, "w").write(content)
PY
  printf '%s\n' "$new" > "$ROOT/VERSION"
}

if [ "$#" -eq 0 ]; then
  cat "$ROOT/VERSION"
  exit 0
fi

case "$1" in
  -h|--help)
    usage
    exit 0
    ;;
  --check)
    if check; then exit 0; else exit 1; fi
    ;;
  *)
    # Reject anything outside digits and dots first - this also rejects a multiline argument
    # (a newline is a non-[0-9.] char), closing the per-line match a bare regex would allow.
    case "$1" in
      *[!0-9.]*)
        echo "bump-version: '$1' is not a semantic version (digits and dots only)." >&2
        echo "  expected: X.Y.Z   e.g. '1.2.3'   (no 'v' prefix, exactly three numeric parts)" >&2
        exit 1
        ;;
    esac
    if ! printf '%s' "$1" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      echo "bump-version: '$1' is not a semantic version." >&2
      echo "  expected: X.Y.Z   e.g. '1.2.3'   (no 'v' prefix, exactly three numeric parts)" >&2
      exit 1
    fi
    write "$1"
    if ! check; then
      echo "bump-version: version did not converge after write." >&2
      exit 1
    fi
    ;;
esac
