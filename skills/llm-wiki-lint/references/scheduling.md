# Scheduling llm-wiki-lint (optional, host-level)

The skill's own due check (step 0) is the portable default: it needs no
infrastructure and works in any agent runtime. Use the recipes below only if
you want lint to run unattended. Scheduling belongs to your environment, not
the skill — so pick whichever fits.

## GitHub Actions (team wikis in a repo)

```yaml
name: llm-wiki-lint
on:
  schedule:
    - cron: "0 6 * * 1"   # Mondays 06:00 UTC
  workflow_dispatch: {}
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install -g @anthropic-ai/claude-code
      - run: claude -p "Run the llm-wiki-lint skill and commit the report" \
               --allowedTools "Bash,Read,Write,Edit"
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
      - run: |
          git config user.name llm-wiki-lint
          git config user.email llm-wiki-lint@users.noreply.github.com
          git add wiki/ && git commit -m "chore: wiki lint report" && git push || true
```

Review the report like any other change — lint proposes, humans approve.

## Local cron / launchd (personal wikis)

```
0 7 * * 1  cd ~/path/to/project && claude -p "Run the llm-wiki-lint skill" >> ~/.llm-wiki-lint.log 2>&1
```

Substitute your agent's headless invocation if you're not using Claude Code
(`codex exec ...`, etc.) — the skill is the same; only the runner changes.

## No scheduler at all

Perfectly fine. The due check fires whenever `llm-wiki-ingest` finishes, so
an actively-fed wiki gets lint offered at the right moments anyway. A wiki
that isn't being fed doesn't drift much.
