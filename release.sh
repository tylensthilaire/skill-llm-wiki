#!/usr/bin/env bash
# release.sh — cut a versioned release for ONE skill: stamp -> review -> commit -> tag -> build.
#
#   ./release.sh <name> v0.1.0                 # stamp, show diff, prompt, then commit + tag + build
#   ./release.sh <name> v0.1.0 -m "…"          # custom commit/tag message
#   ./release.sh <name> v0.1.0 -y              # skip the review prompt
#   ./release.sh <name> v0.1.0 --skip-version-check
#
# This repo holds several skills under skills/<name>/, so tags are prefixed with
# the skill name — <name>-vX.Y.Z (e.g. llm-wiki-lint-v0.1.0) — so each skill versions
# independently. Pass the plain vX.Y.Z; the script builds the prefixed tag.
#
# This is the CLI-tagging path and it does LOCAL work only: it never pushes and
# never creates the GitHub Release — it prints those commands for you to run, so
# the outward-facing actions stay in your hands. Prefer tagging in the GitHub UI?
# Don't use this script; follow the manual steps in CONTRIBUTING.md.
set -euo pipefail

usage() {
  cat >&2 <<'U'
usage: ./release.sh <name> vX.Y.Z [-m msg] [-y] [--skip-version-check]

Cuts a versioned release for one skill locally: stamp origin frontmatter -> review ->
commit -> tag -> build. The tag is <name>-vX.Y.Z. Never pushes and never creates
the GitHub Release — those commands are printed for you to run. Prefer tagging in
the GitHub UI? See CONTRIBUTING.md.
U
}

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

NAME=""
VERSION=""
MSG=""
ASSUME_YES=0
SKIP_VERSION_CHECK=0
while [ $# -gt 0 ]; do
  case "$1" in
    -m) MSG="${2:-}"; shift 2 ;;
    -y|--yes) ASSUME_YES=1; shift ;;
    --skip-version-check) SKIP_VERSION_CHECK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "error: unknown option $1" >&2; usage; exit 2 ;;
    *)
      if [ -z "$NAME" ]; then NAME="$1"
      elif [ -z "$VERSION" ]; then VERSION="$1"
      else echo "error: unexpected argument $1" >&2; exit 2; fi
      shift ;;
  esac
done

[ -n "$NAME" ] && [ -n "$VERSION" ] || { usage; exit 2; }

# Version is vMAJOR.MINOR.PATCH; the tag prepends the skill name.
echo "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$' || {
  echo "error: version '$VERSION' is not vX.Y.Z" >&2; exit 2; }
TAG="${NAME}-${VERSION}"

SKILL_DIR="$ROOT/skills/$NAME"
SKILL="$SKILL_DIR/SKILL.md"
[ -d "$SKILL_DIR" ] || {
  echo "error: no skill '$NAME' under $ROOT/skills" >&2
  echo "available:" >&2; for d in "$ROOT"/skills/*/; do [ -d "$d" ] && echo "  $(basename "${d%/}")" >&2; done
  exit 2; }

# Preflight ------------------------------------------------------------------
[ -z "$(git status --porcelain)" ] || { echo "error: working tree is dirty — commit or stash first" >&2; exit 1; }
git remote get-url origin >/dev/null 2>&1 || { echo "error: no 'origin' remote — git remote add origin <url>" >&2; exit 1; }
if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  echo "error: tag $TAG already exists" >&2; exit 1
fi

# metadata.version must match the version (minus the leading v), unless overridden.
FILE_VERSION="$(python3 - "$SKILL" <<'PY'
import re, sys
fm = re.match(r"^---\n(.*?)\n---\n", open(sys.argv[1]).read(), re.DOTALL)
lines = (fm.group(1) if fm else "").splitlines()
inside = False
for ln in lines:
    if re.match(r"^metadata:\s*$", ln):
        inside = True; continue
    if inside:
        if re.match(r"^\S", ln):
            break
        m = re.match(r"^\s+version:\s*(.*)$", ln)
        if m:
            print(m.group(1).strip().strip("'\"")); break
PY
)"
EXPECTED="${VERSION#v}"
if [ "$SKIP_VERSION_CHECK" -eq 0 ] && [ "$FILE_VERSION" != "$EXPECTED" ]; then
  echo "error: metadata.version ('$FILE_VERSION') != version ('$VERSION' -> '$EXPECTED')." >&2
  echo "       Bump metadata.version in $SKILL first, or pass --skip-version-check." >&2
  exit 1
fi

[ -n "$MSG" ] || MSG="release: $NAME $VERSION"

# Stamp ----------------------------------------------------------------------
echo "==> stamping origin frontmatter ($TAG)"
python3 "$ROOT/stamp.py" "$NAME" "$TAG"

echo
echo "==> review the stamp diff:"
git --no-pager diff -- "$SKILL"

if [ "$ASSUME_YES" -eq 0 ]; then
  printf '\nCommit, tag %s, and build? [y/N] ' "$TAG"
  read -r reply || reply=""
  case "$reply" in
    y|Y|yes|YES) ;;
    *) echo "aborted — the stamp is in your working tree; revert with:  git checkout -- $SKILL"; exit 1 ;;
  esac
fi

# Commit + tag + build -------------------------------------------------------
echo "==> committing"
git commit -qam "$MSG"
echo "==> tagging $TAG"
git tag -a "$TAG" -m "$MSG"
echo "==> building plugin"
"$ROOT/build.sh" "$NAME"

cat <<DONE

released $NAME $VERSION locally (tag $TAG). Next (outward-facing — run when ready):
  git push --follow-tags
  gh release create $TAG dist/$NAME.plugin --title "$NAME $VERSION" --notes "…"
DONE
