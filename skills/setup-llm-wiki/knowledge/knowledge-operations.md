# Knowledge operations

How this project's knowledge base is structured and maintained. This doc was
seeded by the `setup-llm-wiki` skill — see its origin frontmatter (`from` and
`version`) for where it came from.

## The three layers

- **`raw/`** — the source collection: articles, briefs, transcripts, data
  files, and conventions contributed by skills. Sources are added here (by
  humans, by `llm-wiki-ingest` when it files a new one, or by a skill seeding its
  conventions); nothing already in `raw/` is **ever changed** — sources are
  immutable — except that the skill that added a file (matched by its
  `from` field) may replace its own file when it updates. It is the
  project's source of truth.
- **`wiki/`** — agent-written markdown docs built from the sources. Agents own
  this layer: they create docs and keep them current, cross-linked, and
  consistent. Humans read it and may edit it, but agents do the upkeep.
- **`AGENTS.md`** — the contract between the two: how the wiki is structured
  and which conventions apply. Keep it short. When a workflow improvement
  proves useful, record it (here or in this doc) so later sessions inherit it.

## Doc discipline

- One concept per doc. If a doc covers two ideas, split it.
- Link every doc from `wiki/index.md` (one line each: link + one-line summary)
  and cross-link it to related docs with relative markdown links.
- Use prose for anything explanatory; use bullets only for genuine lists.
- A doc states what's true now. History belongs in the log, not in docs.
- Keep docs minimal — merge rather than pile up; a small, current wiki beats a
  large, stale one.

## Reading and writing

- **Query** — to answer from project knowledge, start at `wiki/index.md` and
  follow links; don't grep blindly when the index can point you there.
- **File answers back** — when a query produces a synthesis, comparison, or new
  connection worth keeping, save it as a doc (linked and indexed) so the work
  isn't lost when the chat ends.
- **Ingest and lint are skills** — the steps for adding sources and
  health-checking the wiki live in the `llm-wiki-ingest` and `llm-wiki-lint` skills
  (see the project's skills manifest), not in this doc. Small fixes in passing
  are always welcome: repair what you notice.
- **Log every wiki write** — append one entry to `wiki/log.md` using the
  grep-able prefix format:

  ```
  ## [YYYY-MM-DD] ingest | Article title
  one line on what changed and why
  ```

  Operations: `ingest`, `query`, `lint`, `edit`. The log is
  append-only; `grep "^## \[" wiki/log.md | tail -5` shows recent activity.

## Skill-contributed conventions

Some sources in `raw/` are conventions contributed by skills. They carry
origin frontmatter recording `from` (the skill) and `version` (the skill
version they came from), and they're ingested into the wiki like any other
source.

The skill owns these files. Update them through the skill (via
`skills-sync`), which replaces the skill's own `raw/` file and re-ingests —
don't hand-edit the raw copy. The wiki docs built from them are ordinary docs:
maintain them like any other.