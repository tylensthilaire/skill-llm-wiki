#!/usr/bin/env bash
# Build the distributable .plugin for a skill in this repo.
#
#   ./build.sh <name>            -> dist/<name>.plugin
#   ./build.sh <name> /some/dir  -> writes the .plugin into /some/dir
#   ./build.sh --all [outdir]    -> build every skill under skills/
#   ./build.sh                   -> build the sole skill, if there's exactly one
#
# This repo holds several skills under skills/<name>/, so a <name> selects which
# one to build. The .plugin is a build artifact (gitignored) — attach it to a
# GitHub Release. The plugin version is read from the skill's `metadata.version`
# frontmatter, so the two can never drift — bump the skill, rebuild, and the
# manifest follows.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plain glob, so it works on bash 3.2 (macOS). Skill names are kebab-case (no
# spaces), so unquoted word-splitting of this list is safe.
list_skills() {
  for d in "$ROOT"/skills/*/; do [ -d "$d" ] && basename "${d%/}"; done
}

# Read name / version / description from a skill's frontmatter (single source of
# truth). metadata.version is nested; description is a YAML folded scalar (>-).
read_fm() {
  local SKILL="$1" FIELD="$2"
  python3 - "$SKILL" "$FIELD" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
lines = (m.group(1) if m else "").splitlines()
field = sys.argv[2]

def scalar(key):
    """Top-level `key:` — plain value or a folded/literal block scalar body."""
    for i, ln in enumerate(lines):
        s = re.match(rf"^{key}:\s*(.*)$", ln)
        if not s:
            continue
        first = s.group(1).strip()
        if first in (">", ">-", ">+", "|", "|-", "|+"):
            body, j = [], i + 1
            while j < len(lines) and (lines[j].startswith("  ") or lines[j].strip() == ""):
                body.append(lines[j].strip())
                j += 1
            return " ".join(x for x in body if x)
        return first.strip("'\"")
    return ""

def nested(parent, key):
    """`key:` indented under a top-level `parent:` block."""
    inside = False
    for ln in lines:
        if re.match(rf"^{parent}:\s*$", ln):
            inside = True
            continue
        if inside:
            if re.match(r"^\S", ln):
                break
            s = re.match(rf"^\s+{key}:\s*(.*)$", ln)
            if s:
                return s.group(1).strip().strip("'\"")
    return ""

print(scalar("name") if field == "name"
      else scalar("description") if field == "description"
      else nested("metadata", "version"))
PY
}

build_one() {
  local NAME="$1"
  local OUT_DIR="${2:-$ROOT/dist}"
  local SKILL_DIR="$ROOT/skills/$NAME"
  local SKILL="$SKILL_DIR/SKILL.md"

  [ -d "$SKILL_DIR" ] || { echo "error: no skill '$NAME' under $ROOT/skills" >&2; echo "available: $(list_skills | tr '\n' ' ')" >&2; return 1; }
  [ -f "$SKILL" ] || { echo "error: skill not found at $SKILL" >&2; return 1; }

  local FM_NAME VERSION DESC
  FM_NAME="$(read_fm "$SKILL" name)"
  VERSION="$(read_fm "$SKILL" version)"
  DESC="$(read_fm "$SKILL" description)"

  [ -n "$VERSION" ] || { echo "error: no metadata.version in $SKILL" >&2; return 1; }
  [ "$FM_NAME" = "$NAME" ] || { echo "error: frontmatter name '$FM_NAME' != skill folder '$NAME'" >&2; return 1; }

  # Keywords: derive from the skill name so this needs no per-skill edits.
  local KEYWORDS
  KEYWORDS="$(NAME="$NAME" python3 -c 'import json,os;print(json.dumps(os.environ["NAME"].split("-")+["claude-skill"]))')"

  local STAGE PKG
  STAGE="$(mktemp -d)"
  # shellcheck disable=SC2064
  trap "rm -rf '$STAGE'" RETURN
  PKG="$STAGE/$NAME"
  mkdir -p "$PKG/.claude-plugin" "$PKG/skills"

  # Package the whole skill folder (SKILL.md + scripts/ references/ knowledge/ …).
  cp -R "$SKILL_DIR" "$PKG/skills/$NAME"
  # Prefer a skill-specific README if present, else the repo README for context.
  if [ -f "$SKILL_DIR/README.md" ]; then
    cp "$SKILL_DIR/README.md" "$PKG/README.md"
  elif [ -f "$ROOT/README.md" ]; then
    cp "$ROOT/README.md" "$PKG/README.md"
  fi

  local DESC_JSON
  DESC_JSON="$(DESC="$DESC" python3 -c 'import json,os;print(json.dumps(os.environ["DESC"]))')"
  cat > "$PKG/.claude-plugin/plugin.json" <<JSON
{
  "name": "$NAME",
  "version": "$VERSION",
  "description": $DESC_JSON,
  "author": { "name": "Tylen St Hilaire" },
  "keywords": $KEYWORDS
}
JSON

  # Validate before zipping.
  python3 - "$PKG" <<'PY'
import json, re, os, sys
base = sys.argv[1]; ok = True
def chk(c, m):
    global ok; print(("[PASS] " if c else "[FAIL] ") + m); ok = ok and c
pj = json.load(open(f"{base}/.claude-plugin/plugin.json"))
name = pj.get("name", "")
chk(re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name) is not None, "name is kebab-case")
chk(re.fullmatch(r"\d+\.\d+\.\d+", pj.get("version", "")) is not None, f"version is semver ({pj.get('version')})")
sm = f"{base}/skills/{name}/SKILL.md"
chk(os.path.isfile(sm), "SKILL.md present")
t = open(sm).read()
chk(t.count("```") % 2 == 0, "code fences balanced")
fm = re.match(r"^---\n(.*?)\n---\n", t, re.DOTALL)
chk(fm is not None, "frontmatter present")
chk(fm is None or "[[" not in fm.group(1), "no vault wikilinks in frontmatter")
sys.exit(0 if ok else 1)
PY

  mkdir -p "$OUT_DIR"
  local PLUGIN STAGE_ZIP
  PLUGIN="$OUT_DIR/$NAME.plugin"
  STAGE_ZIP="$STAGE/$NAME.plugin"
  ( cd "$PKG" && zip -rq "$STAGE_ZIP" . -x "*.DS_Store" )
  cp "$STAGE_ZIP" "$PLUGIN"

  echo "built $PLUGIN (v$VERSION)"
}

# --- arg handling -----------------------------------------------------------
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0
fi

if [ "${1:-}" = "--all" ]; then
  OUT_DIR="${2:-$ROOT/dist}"
  for n in $(list_skills); do build_one "$n" "$OUT_DIR"; done
  exit 0
fi

if [ $# -ge 1 ]; then
  build_one "$1" "${2:-$ROOT/dist}"
  exit 0
fi

# No args: build the sole skill if there's exactly one, else require a name.
count=0; sole=""
for d in "$ROOT"/skills/*/; do [ -d "$d" ] || continue; sole="$(basename "${d%/}")"; count=$((count + 1)); done
if [ "$count" -eq 1 ]; then
  build_one "$sole"
else
  echo "error: several skills under $ROOT/skills — name one, or use --all:" >&2
  list_skills | sed 's/^/  /' >&2
  exit 2
fi
