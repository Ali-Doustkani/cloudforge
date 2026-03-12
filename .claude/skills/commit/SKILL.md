---
name: commit
description: Stage and commit changes using conventional commits for this project
disable-model-invocation: true
allowed-tools: Bash
---

1. Show changes with 'git status -s' and wait for confirmation
2. If confirmed stage everything with `git add -A` and run `git commit`. Use conventional commit message as follow: 
   - Format: `<type>: <summary>`
   - Types: feat, fix, refactor, test, docs, chore, infra
   - Summary: present tense, under 72 chars
3. Do NOT push unless the user explicitly asks
