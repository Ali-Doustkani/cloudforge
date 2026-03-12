---
name: commit
description: Stage and commit changes using conventional commits for this project
disable-model-invocation: true
allowed-tools: Bash
---

1. Check file changes with `git status -s` if it was more than three files wait for confirmation otherwise commit
2. Use conventional commit message as follow: 
   - Format: `<type>: <summary>`
   - Types: feat, fix, refactor, test, docs, chore, infra
   - Summary: present tense, under 72 chars
3. Do NOT push unless the user explicitly asks
