# LLM Wiki Agent Skill

Three skills to help your agent to create and maintain a 'brain' for 
itself, right inside your repo. using a Karpathy-style 
**agent-maintained wiki** in your repo — a `wiki/`folder of small,
cross-linked markdown docs an agent sets up, feeds, and keeps healthy.

**Version:** Setup: 0.1.0, Ingest: 0.1.0, Lint: 0.1.0 · **License:** Artistic-2.0

> Maintaining or releasing these skills? See [CONTRIBUTING.md](./CONTRIBUTING.md)
> for the repo layout, build, stamping, and per-skill release process.

## The skills

| Skill | What it does | When |
|-------|--------------|------|
| [`setup-llm-wiki`](./skills/setup-llm-wiki) | **One-shot.** Creates the `wiki/` folder, adds the contract lines to `AGENTS.md`, and seeds the knowledge-operations conventions doc that governs everything else. | Once per project, first. |
| [`llm-wiki-ingest`](./skills/llm-wiki-ingest) | Ingests a source into the wiki: files the original in `raw/`, turns it into small cross-linked docs, updates every doc it touches, logs the ingest. | Whenever you add/file/capture a source. |
| [`llm-wiki-lint`](./skills/llm-wiki-lint) | Health-checks the wiki: dead links, orphans, contradictions, stale claims, coverage gaps, index drift, suspected duplicates. | After batches of ingests; on a schedule. |

They form a lifecycle: **set up** the wiki once, **ingest** into it continually,
**lint** it periodically. `setup-llm-wiki` seeds the conventions the other two
depend on, which is why the three are one repo.

## Installing

Three ways to start, via [`skills-sync`](https://github.com/tylensthilaire/skill-skills-sync),
(recommended for consistency across teams and environments), via agent (for casual use),
and manually (for Claude Desktop users).

**Via skills-sync (recommended)** With `skills-sync` installed, ask your agent to add the llm-wiki skills:

> Add the llm-wiki skills from
> https://github.com/tylensthilaire/skill-llm-wiki to this project with
> skills-sync, pinned at each skill's latest release tag, and install them.

skills-sync will add pointers to the latest release to a `skills.json` config file,
then fetch, verify and copy it into your skills folder. That way you or your team always
get the same version of the skill.
Install one or all skills — a project that only wants `llm-wiki-lint` gets just that one.

`setup-llm-wiki` is a one-shot: once the wizard has run, it will suggest removing 
its own `skills.json` entry and skill files — the conventions it leaves behind 
in the wiki are all you need.

**2 Via agent** Point your agent at this repo and ask:

> Install the llm-wiki skills from
> https://github.com/tylensthilaire/skill-llm-wiki into this project: clone it at
> the latest release tag for each skill, copy `skills/setup-llm-wiki`,
> `skills/llm-wiki-ingest`, and `skills/llm-wiki-lint` into `.claude/skills/`,
> then run `setup-llm-wiki` first.

Copy only the skills you want, and run `setup-llm-wiki` before the other two —
it seeds the conventions doc they depend on. You get the files without the
content-hash guarantee skills-sync gives you; re-running the ask is how you take
an update.

**3 As plugins** Download a skill's `.plugin` from this repo's
[Releases](../../releases) (release assets are named `<skill>.plugin`, tagged
`<skill>-vX.Y.Z`) and install it in your plugin manager.
