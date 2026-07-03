---
name: llm-wiki-lint
description: >-
  Health-check the project's agent-maintained wiki and produce a lint report:
  dead links, orphan docs, contradictions, stale claims, coverage gaps, index
  drift, and suspected duplicates. Use this whenever the user asks to lint,
  health-check, audit, or tidy the wiki or knowledge base; whenever they ask
  "is the wiki up to date" or "how healthy is the knowledge base"; after any
  large batch of ingests; and whenever the due check shows a lint is due (no
  lint entry in the log within the threshold).
license: Artistic-2.0
metadata:
  author: Tylen St Hilaire
  version: "0.1.0"
---

# Wiki lint

Keep the wiki healthy as it grows: catch the any broken or missing cross-links that appear over time. Report and repair safe things; never destroy.

## Step 0 — due check

To decide whether a lint is due (other skills can call this, e.g. at the end
of `llm-wiki-ingest`):

```
grep "^## \[" wiki/log.md | tail -20
```

A lint is due if, since the last `lint` entry, there have been **10+ ingests**
or **14+ days** (defaults; a project may override them in its conventions doc).
When called only for the due check, report due/not-due and stop.

To run lint unattended on a schedule, see `references/scheduling.md` —
scheduling belongs to your environment, not the skill.

## Checks (run in order)

1. **Structure** — docs missing from `index.md`; index entries pointing at
   missing files.
2. **Dead links** — links to docs or raw files that don't exist.
3. **Orphans** — docs with no inbound links. Suggest which docs should link to
   them.
4. **Contradictions** — docs that disagree with each other; claims a newer
   source has superseded. Cite both sides.
5. **Coverage gaps** — entities or concepts mentioned across several docs that
   lack their own doc. Flag for `llm-wiki-ingest`/the human; don't create content
   docs during lint.
6. **Bloat and duplicates** — near-identical docs, or docs that have collected
   content belonging elsewhere. Flag with a proposed merge; never delete on
   your own.

## Repairs

Apply without asking: index entries for existing unlisted docs, and obviously
broken relative links with one clear target. Everything else — deletions,
merges, content rewrites, contradiction fixes — goes in the report as a
proposed action needing approval.

## Report

Write the report as a dated doc under `wiki/` (linked from the index — lint
findings are project knowledge too), with sections matching the checks, an
overall status line (green / yellow / red), and a numbered next-steps list
marking which actions need approval. Append to the log:
`## [YYYY-MM-DD] lint | <status>: <one-line summary>`.

## Hard rules

- Never delete files on your own.
- Never create content docs during lint (reports excepted) — creating docs is
  ingest's job.
- Never change `raw/`.
- Always log the pass, even when everything is green — the due check depends
  on it.