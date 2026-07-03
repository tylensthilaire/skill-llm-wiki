# Contributing / maintaining

This is the maintainer's guide for the **llm-wiki** suite — the `setup-llm-wiki`,
`llm-wiki-ingest`, and `llm-wiki-lint` skills. End users don't need any of this — see
[README.md](./README.md) for installing and using the skills.

The three share one contract (the knowledge-operations conventions and the
`AGENTS.md` wiki lines), so they live in one repo and are built, stamped, and
released with one shared set of tooling. Each skill still versions and ships
**independently** — releases are per-skill (below).

## Repository layout

```
.
├── skills/
│   ├── setup-llm-wiki/       # each: SKILL.md (source of truth) + scripts/ references/ knowledge/
│   ├── llm-wiki-ingest/
│   └── llm-wiki-lint/
├── release.sh                # cut a release for ONE skill: stamp → commit → tag → build (CLI path)
├── build.sh                  # builds a skill's distributable .plugin
├── stamp.py                  # writes origin frontmatter at release time
├── .gitignore
├── README.md                 # user-facing (the suite)
└── CONTRIBUTING.md           # this file
```

The tooling is **skill-aware**: `build.sh`, `stamp.py`, and `release.sh` all take
a `<name>` (a folder under `skills/`) to select which skill they act on.

## Editing a skill

`skills/<name>/SKILL.md` is that skill's single source of truth; supporting files
live beside it. A few rules keep each bundle buildable:

- **Version lives in `metadata.version`** — SemVer, quoted (e.g. `"0.1.0"`).
  It is the human-facing version; the release *tag* is what gets pinned (below).
- **Code fences must stay balanced.** `build.sh` validates this before zipping.
- **No vault wikilinks in frontmatter.** Keep `[[…]]` out of the frontmatter
  block — `build.sh` rejects it.

Changing the shared contract (the knowledge-operations conventions in
`skills/setup-llm-wiki/knowledge/`, or the `AGENTS.md` wiki lines) usually means
touching `llm-wiki-ingest` and `llm-wiki-lint` too — that's the whole reason these are
one repo. Make such changes in one commit and release the affected skills together.

## Building a .plugin

```bash
./build.sh llm-wiki-lint             # -> dist/llm-wiki-lint.plugin
./build.sh llm-wiki-lint /path/out   # -> writes the .plugin into /path/out
./build.sh --all                 # build every skill under skills/
```

`build.sh` reads the version from the skill's `metadata.version` (so the plugin
manifest can never drift from the skill), generates `.claude-plugin/plugin.json`,
validates the bundle (kebab-case name, semver version, present `SKILL.md`,
balanced fences, no vault wikilinks), and zips the whole skill folder to a
`.plugin`. Output is gitignored.

> Why a script and not copy-paste commands? It is the single source of truth for
> *how to build*, so the docs and the build can't disagree.

## Stamping origin frontmatter

An installed copy traces back to its source through three frontmatter keys —
`source`, `source-path`, `ref` — read by `skills-sync` (see that skill's
`references/manifest-format.md`). In a multi-skill repo all three skills share one
`source` (the repo URL) and differ by `source-path` (`skills/<name>`). `stamp.py`
writes them at release time so you never hand-edit them:

```bash
./stamp.py llm-wiki-lint llm-wiki-lint-v0.1.0   # stamps source (origin URL), source-path, ref
```

`ref` is the exact tag the release is cut at — written verbatim so it feeds a
manifest's `ref` field and stays checkout-able. It is **not** the human-facing
`metadata.version` (which may read `0.1.0` while the tag is `llm-wiki-lint-v0.1.0`).
`stamp.py` refuses to run on a dirty tree, so stamping is always one reviewable
step: stamp → review → commit → tag.

## Versioning

Each skill follows [SemVer](https://semver.org/) + [Conventional
Commits](https://www.conventionalcommits.org/). Because the repo holds several
skills, **tags are prefixed with the skill name** — `<name>-vX.Y.Z`, e.g.
`llm-wiki-lint-v0.1.0` — so each skill versions independently on one shared history.
Version history lives in git (tags + release notes); the file carries only
`metadata.version`. `0.x` while these are maturing tools.

> The content `hash` a consumer pins in `skills.json` is over the skill folder,
> not the repo, so per-skill integrity holds regardless of the shared history —
> the prefixed tag is a convenience for humans, not a correctness requirement.

## Releasing a new version (per skill)

Bump `metadata.version` in `skills/<name>/SKILL.md` to the version you're
releasing (SemVer) and commit any pending work so the tree is clean. Then
`release.sh` runs the whole local sequence — stamp → review → commit → tag →
build — for one named skill. It does **local work only**: it never pushes and
never creates the GitHub Release, so the outward-facing steps stay in your hands.

```bash
./release.sh llm-wiki-lint v0.1.0        # stamp, show the diff, prompt, then commit + tag (llm-wiki-lint-v0.1.0) + build
#   -m "…"                            custom commit/tag message
#   -y                                skip the review prompt
#   --skip-version-check              allow metadata.version != version

# when ready (outward-facing):
git push --follow-tags
gh release create llm-wiki-lint-v0.1.0 dist/llm-wiki-lint.plugin --title "llm-wiki-lint v0.1.0" --notes "…"
```

It refuses to run on a dirty tree, without an `origin` remote, if the tag already
exists, or if `metadata.version` doesn't match the version (bump it first, or
pass `--skip-version-check`).
