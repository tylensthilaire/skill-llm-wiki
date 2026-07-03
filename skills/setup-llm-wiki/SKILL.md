---
source: https://github.com/tylensthilaire/skill-llm-wiki.git
source-path: skills/setup-llm-wiki
ref: setup-llm-wiki-v0.1.0
name: setup-llm-wiki
description: >-
  Set up an agent-maintained wiki in a project: a wiki/ folder of small,
  cross-linked markdown docs, a few contract lines in AGENTS.md, and the
  knowledge-operations conventions doc that governs them. Use this whenever the
  user asks to set up a wiki, knowledge base, or "second brain" for a project;
  whenever another skill needs a wiki to seed its conventions into and
  none exists; whenever a project has scattered documentation with no home for
  agent-readable knowledge; or whenever someone asks "where should project
  knowledge live". Runs once per project: it sets up the wiki, seeds its
  conventions, and is then no longer needed.
license: Artistic-2.0
metadata:
  author: Tylen St Hilaire
  version: "0.1.0"
---

# Setup LLM wiki

Set up a wiki for a project: one place where project knowledge lives — facts,
conventions, decisions, findings — maintained by agents, owned by the project.
Run this once per project.

## Lifecycle

1. **Probe first.** This often runs on projects that already have a wiki, so
   check before acting.
2. **Create only what's missing.**
3. **Seed this skill's conventions** into `raw/` from `knowledge/`, recording
   its name and version; the agent then ingests them into the wiki.
4. **Then stop.** If installed via a manifest, suggest removing it from
   `skills.json`; if installed by hand, offer to delete the skill folder.

## Step 1 — Probe

Check, in order:

- Does `wiki/` exist at the project root?
- Does `AGENTS.md` exist, and does it reference the wiki?
- Do any files in `raw/` carry origin frontmatter (a `from` field) naming
  this skill?

If a wiki already exists and carries this skill's origin frontmatter at the
current version: report that, do nothing, and stop. If it exists but is missing
pieces (no AGENTS.md contract, conventions not seeded), create only the gaps.
If the seed exists from an **older** version of this skill, replace this
skill's own file in `raw/` with the newer version and re-ingest (see
`skills-sync`).

## Step 2 — Interview (lightly)

Ask only what you can't infer:

- Is there existing documentation to use as source material? (a `docs/` folder,
  a README with real content, briefs) If so, note it — you'll offer to ingest
  it at the end, not now.
- Anything the wiki should explicitly NOT cover? (e.g. secrets, client names)

Don't interrogate. Two questions maximum; use sensible defaults otherwise.

## Step 3 — Create the structure

Create what's missing:

```
raw/                      # sources incl. skill conventions (seeded in step 4); add, never change existing
wiki/
├── index.md              # contents: one line per doc, grouped by topic
└── log.md                # append-only: ## [YYYY-MM-DD] op | title
```

Then add the contract to `AGENTS.md` (create the file if absent). Keep it
short — a few lines at most:

```markdown
## Project knowledge
Sources live in `raw/` (add new ones; never change what's there). Project
knowledge lives in `wiki/` — start at `wiki/index.md`. Agents maintain the
wiki; humans own everything outside it. The knowledge-operations conventions
are in the wiki, ingested from a seed in `raw/`.
```

## Step 4 — Seed the conventions

Copy each file in this skill's `knowledge/` directory into `raw/`, adding
origin frontmatter to each:

```yaml
---
from: setup-llm-wiki
version: <this skill's version, from its manifest entry or release tag>
---
```

Then ingest them into the wiki like any source (see `llm-wiki-ingest`): write a
wiki doc for each, index it, and link it back to the raw file. The raw copy is
the immutable source of truth; the wiki doc is the agent-maintained version.

## Step 5 — Finish

- Offer to add the two operation skills as dependencies: `llm-wiki-ingest` (files
  sources) and `llm-wiki-lint` (health-checks, and runs its own due check). Pin
  them at the **same source and ref as this skill** so the set updates
  together. First check for `skills.json`:
  - if it's present, add the entries and have `skills-sync` install and pin
    them;
  - if it's absent, offer `skills-sync` (its `init` creates the manifest);
    if that's declined, report where the two skills live and stop.

  Don't half-install, and don't handle a missing manifest yourself —
  `skills-sync` owns that.
- Offer (don't force) to ingest any source material found in step 2 — via
  `llm-wiki-ingest` if installed, one source at a time.
- Report what you created, as a short list.
- Note that this skill is now done for this project and can be removed from the
  manifest / skills folder.

## What NOT to do

- Don't restructure or rewrite existing human-authored documentation.
- Don't write more than the few contract lines into AGENTS.md.
- Don't seed or ingest anything if the user declines the wiki — stop cleanly
  with nothing written.