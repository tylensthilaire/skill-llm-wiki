#!/usr/bin/env python3
"""stamp.py — write origin frontmatter into a skill's SKILL.md at release time.

Usage:
    ./stamp.py <name> <ref>        # e.g. ./stamp.py llm-wiki-lint llm-wiki-lint-v0.1.0

This repo holds several skills under skills/<name>/, so <name> selects which one
to stamp. Writes three top-level frontmatter keys that `skills-sync` reads to
trace an installed copy back to its source (see the skills-sync skill's
references/manifest-format.md):

    source       git URL of this repo (from `git remote get-url origin`)
    source-path  path to the skill folder within the repo (skills/<name>)
    ref          the tag/SHA passed on the command line

`ref` is the exact git ref this release is cut at — written verbatim so it feeds
a manifest's `ref` field and stays checkout-able. It is NOT the human-facing
metadata.version (which may read 0.1.0 while the tag is llm-wiki-lint-v0.1.0). In a
multi-skill repo, tags are prefixed with the skill name so each skill versions
independently — see CONTRIBUTING.md.

Refuses to run on a dirty working tree so you never tag a half-stamped state.
The flow is one atomic, reviewable step: stamp -> review -> commit -> tag.
Because `ref` is the tag name you choose up front, stamping before you tag is
self-consistent: the committed SKILL.md declares the same ref the tag points at.
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def sh(*args: str) -> str:
    return subprocess.run(
        args, cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.strip()


def resolve_skill_dir(name: str) -> Path:
    skills = ROOT / "skills"
    d = skills / name
    if not d.is_dir():
        have = ", ".join(sorted(p.name for p in skills.iterdir() if p.is_dir())) if skills.exists() else ""
        sys.exit(f"error: no skill '{name}' under {skills} (have: {have})")
    return d


def main() -> None:
    if len(sys.argv) != 3 or sys.argv[1] in ("-h", "--help"):
        sys.exit(__doc__)
    name = sys.argv[1].strip()
    ref = sys.argv[2].strip()

    # Clean tree only — stamp/review/commit/tag is one atomic, reviewable step.
    if sh("git", "status", "--porcelain"):
        sys.exit("error: working tree is dirty — commit or stash first, then stamp")

    try:
        source = sh("git", "remote", "get-url", "origin")
    except subprocess.CalledProcessError:
        sys.exit("error: no 'origin' remote — `git remote add origin <url>` so source can be recorded")

    skill_dir = resolve_skill_dir(name)
    source_path = skill_dir.relative_to(ROOT).as_posix()
    md = skill_dir / "SKILL.md"
    text = md.read_text()

    m = re.match(r"^(---\n)(.*?)(\n---\n)", text, re.DOTALL)
    if not m:
        sys.exit(f"error: {md} has no frontmatter block")
    open_, body, close = m.group(1), m.group(2), m.group(3)

    # Drop any prior top-level stamp, then re-add at the top of the block (idempotent).
    kept = [ln for ln in body.splitlines()
            if not re.match(r"^(source|source-path|ref):", ln)]
    stamp = [f"source: {source}", f"source-path: {source_path}", f"ref: {ref}"]
    md.write_text(open_ + "\n".join(stamp + kept) + close + text[m.end():])

    print(f"stamped {md}")
    for line in stamp:
        print(f"  {line}")
    print(f"\nreview, then:  git commit -am 'release {ref}'  &&  git tag {ref}")


if __name__ == "__main__":
    main()
