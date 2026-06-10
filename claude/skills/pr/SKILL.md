---
name: pr
description: Open a GitHub pull request for the current branch with a structured description (why, what, test plan, linked issue, and optional sections for risk/screenshots/etc).
disable-model-invocation: true
---

# PR

Open a pull request on GitHub for the current branch.

## Process

1. Gather context in parallel:
   - `git status` — if the tree is dirty (uncommitted changes), invoke the `/commit` skill first to commit them before proceeding.
   - `git log <base>..HEAD` and `git diff <base>...HEAD` — review ALL commits on the branch, not just the latest.
   - `gh pr view` — if a PR already exists for this branch, abort and tell the user.
   - Current branch name (often contains an issue number, e.g. `123-fix-foo`).
   - Recent conversation context — any issue URL or `#N` the user mentioned.

2. Push the branch if needed: `git push -u origin HEAD`.

3. Identify the issue to link:
   - Prefer an explicit issue from the conversation context.
   - Fallback: parse from branch name.
   - If found, put `Closes #N` at the top of the body (GitHub auto-closes on merge).
   - If none is found, omit — don't fabricate one.

4. Write the title:
   - Short (<70 chars), imperative.
   - Check `gh pr list --state merged -L 5` to mirror the repo's style (emoji prefix? conventional commits? plain?).

5. Write the body using the template below. Omit any section that doesn't apply — empty headers are noise.

   ```md
   Closes #N

   ## Why
   <1–3 sentences: the motivation. What problem, user pain, or constraint drove this?>

   ## What
   <Bulleted summary of the change. Intent, not a commit-by-commit replay.>

   ## Test plan
   - [ ] <Concrete check a reviewer or CI can run>
   - [ ] <Edge case>
   - [ ] <Regression check on adjacent behaviour>

   ## Screenshots         ← UI changes only
   <Before / after, or short video for interactions>

   ## Breaking changes    ← only if any
   <What breaks, how callers migrate>

   ## Risk & rollback     ← only for risky changes (migrations, infra, hot paths)
   <What could go wrong, how to revert safely, any manual deploy steps>

   ## Reviewer focus      ← only for large or tricky diffs
   <Where to look first; what NOT to spend time on>

   ## Out of scope        ← only if reviewers might ask "why didn't you also…"
   <Deferred items, with links to follow-up issues if filed>

   ## Depends on          ← only if blocked by another PR
   <Links to PRs that must merge first>
   ```

6. Create the PR with a HEREDOC to preserve formatting:
   ```bash
   gh pr create --title "..." --body "$(cat <<'EOF'
   …body…
   EOF
   )"
   ```

7. Print the PR URL.

8. Spawn a fresh-context Agent to run `/review-fix-loop <pr-number>` on the PR. Use the `general-purpose` subagent so the review starts clean without this conversation's context. Run it in the background; report back when it completes.

## Rules

- No AI attribution, no "Generated with Claude" footer, no co-author lines. Ever.
- Be honest in the test plan: describe what should be checked, but don't claim you ran something you didn't.
- If `$ARGUMENTS` is provided, treat it as guidance for the body's emphasis or framing.
- Use the repo's default base branch unless the user specifies otherwise.
