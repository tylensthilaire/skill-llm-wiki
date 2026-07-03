---
source: https://github.com/tylensthilaire/skill-llm-wiki.git
source-path: skills/llm-wiki-ingest
ref: llm-wiki-ingest-v0.1.0
name: llm-wiki-ingest
description: >-
  Ingest a source into the project's agent-maintained wiki: file it in raw/,
  turn it into small wiki docs, update every doc it touches, and log the
  ingest. Use this whenever the user asks to ingest, file, add, or process a
  source — an article, paper, brief, meeting transcript, decision, or dataset —
  into the wiki or knowledge base; whenever new files appear in raw/ that the
  wiki doesn't yet reflect; and whenever the user shares content and says
  anything like "add this to the wiki", "capture this", "file this", or "make
  sure the knowledge base knows about this".
license: Artistic-2.0
metadata:
  author: Tylen St Hilaire
  version: "0.1.0"
---

# Wiki ingest

Add a source to the project knowledge base so the knowledge is captured once
and kept current, not re-worked each time it's asked about.

Requires a wiki (see `setup-llm-wiki`). If there isn't one, offer to install
and run that skill first; if declined, stop — don't set up a wiki ad hoc.

## Procedure

1. **File the source.** If it isn't already in `raw/`, copy it there (convert
   to markdown if it arrived as a URL or pasted text). Never change anything
   already in `raw/` — it's immutable.
2. **Read and discuss.** Read the source in full. In an interactive session,
   share the key takeaways and let the human steer emphasis before you write.
   In an unattended run, use your judgment and say so in the log.
3. **Write the summary doc.** One doc for the source itself: what it is, what
   it claims, what matters here. Link back to the raw file.
4. **Update related docs.** Find every existing doc the source touches —
   entities, concepts, decisions — and update them: strengthen, revise, or note
   contradictions plainly ("source X contradicts Y on Z"). A single source may
   touch many docs; update every one it affects. New doc or edit? A distinct
   thing you'd link to from elsewhere gets its own doc; an update to an existing
   thing is an edit.
5. **Index and cross-link.** Add the new doc(s) to `wiki/index.md` with a
   one-line summary each, and make sure links run both ways between new and
   touched docs.
6. **Log.** Append to `wiki/log.md`:
   `## [YYYY-MM-DD] ingest | <source title>` plus one line on what changed.
7. **Due check.** Run the lint-due check from `llm-wiki-lint` (is there a recent
   `lint` entry in the log?). If a lint is due, say so and offer to run it —
   don't run it silently.

## Rules

- Never change `raw/`.
- Never delete docs during ingest — flag suspected duplicates for `llm-wiki-lint`.
- Keep docs minimal: merge into existing docs rather than piling up
  near-duplicates; the wiki should stay small and current, not grow for its
  own sake.
- If the source contradicts the wiki, record the contradiction visibly rather
  than silently overwriting either side.