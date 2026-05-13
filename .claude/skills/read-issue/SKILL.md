---
name: read-issue
description: This skill should be used when the user asks to "read issue", "show issue", "open issue", "fetch issue", "load issue", or references a GitHub issue number or URL. Fetches and presents a GitHub issue.
allowed-tools: Bash
---

Use `$ARGUMENTS` as the issue reference (number or full GitHub URL).

1. If `$ARGUMENTS` is empty, ask the user for the issue number or URL before proceeding.
2. Run `gh issue view $ARGUMENTS --json number,title,state,author,createdAt,labels,assignees,body` to get issue metadata.
3. Present the issue with:
   - Title, number, state, author, and labels on the first line
   - Body as-is (preserve code blocks and formatting)
4. If the issue is not found or `gh` returns an error, show the error and stop.
