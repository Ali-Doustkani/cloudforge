---
name: commit
description: Stage and commit changes using conventional commits for this project
disable-model-invocation: true
allowed-tools: Bash
---

1. Run `git status` to show all changes, then ask the user to confirm they want to commit everything
2. If confirmed, write a conventional commit message based on the changes:
   - Format: `<type>: <summary>`
   - Types: feat, fix, refactor, test, docs, chore, infra
   - Summary: present tense, under 72 chars
3. Stage everything with `git add -A` and run `git commit`
4. Do NOT push unless the user explicitly asks
