---
name: review
description: Reviews code or a pull request for quality, readability, SOLID principles, performance, possible bugs, and race conditions.
disable-model-invocation: true
---

# Code Review

Performs a thorough code review.

## Process

1. Determine the scope:
   - If `$ARGUMENTS` contains a PR number, run `gh pr view <number>` for details and `gh pr diff <number>` for the diff.
   - If `$ARGUMENTS` contains a file path, review that file.
   - If no arguments, review the current uncommitted changes (`git diff` and `git diff --cached`).

2. Review the code considering:
   - **Code quality** — Is the code clean and readable?
   - **SOLID principles** — Are responsibilities well-separated?
   - **Performance** — Any unnecessary allocations, O(n²) loops, or redundant work?
   - **Bugs** — Logic errors, off-by-ones, nil/null issues?
   - **Race conditions** — Shared mutable state, async hazards?
   - **Best approach** — Is this the best way to achieve the goal, or is there a simpler/more idiomatic solution?

3. Be thorough. Report findings grouped by severity (critical, warning, suggestion).

4. If reviewing a PR (step 1 resolved a PR number), post the review as a comment on the PR using `gh pr review <number> --comment --body "<review>"`. Use a HEREDOC for the body to preserve formatting.
