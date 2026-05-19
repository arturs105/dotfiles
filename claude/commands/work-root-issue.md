---
description: Process all sub-issues of a root/PRD issue iteratively. Each sub gets a PR, review/fix loop, and auto-merges into a shared feature branch.
argument-hint: <root-issue-number-or-url>
---

# Work Root Issue

Iterate through all sub-issues of the given root issue. Each sub-issue gets its own branch, PR, review/fix loop, and auto-merges into a shared `feature/<root-slug>` branch on success. The feature branch accumulates the work; nothing is pushed to `main`.

## Phase -1: Resolve root issue number

The argument is `<root>`. If it's a URL (e.g. `https://github.com/foo/bar/issues/141`), extract the trailing path segment as the number. Otherwise use it as the number directly. If the URL points to a different repo than the current working directory's `origin`, stop and report. Substitute the resolved number wherever `<root>` appears below.

## Phase 0: Set up the feature branch

Derive the feature branch name from the root issue title — slug of 4-5 words, prefixed `feature/` (e.g. `feature/tags-system`).

Check if it already exists:
```
git fetch origin
git ls-remote --heads origin feature/<slug>
```

- **Exists**: reuse it. `git checkout feature/<slug> && git pull`.
- **Doesn't exist**: confirm the derived name with the user via `AskUserQuestion`, then create it from main:
  ```
  git checkout main && git pull
  git checkout -b feature/<slug>
  git push -u origin feature/<slug>
  ```
  Post a comment on the root issue: `🤖 Feature branch: \`feature/<slug>\``.

Store the feature branch name for use in later phases.

## Phase 1: Discover sub-issues

Try in order:

1. **GitHub native**: `gh api repos/{owner}/{repo}/issues/<root>/sub_issues`
2. **Body reference**: `gh issue list --search "in:body #<root>" --json number,title,body,state,labels --limit 100`, filter to those whose body contains `## Parent` or `Parent:` referencing `#<root>`.
3. **Task list**: parse root body for `- [ ] #N` / `- [x] #N` lines.

Combine, deduplicate, sort ascending by issue number.

## Phase 2: Iterate over pending sub-issues

For each sub-issue in order, classify status:
- **Done**: an open or merged PR with base `feature/<slug>` exists for this sub
- **Pending**: no PR yet

Skip done ones. For each pending sub-issue (in order):

### 2.1: Verify ready to implement

- Has `plan-approved` label, OR body has detailed acceptance criteria.
- If neither, stop and ask the user.

### 2.2: TDD on a branch off the feature branch

Spawn `tdd` subagent with prompt:

> Implement issue #<N> via TDD. Branch from `feature/<slug>` (not main). The plan is in #<N>'s body and comments. Use the branch name from the plan comment (or derive `claude/<4-5-word-slug>` from the issue title if not present).

The agent runs `git checkout feature/<slug> && git pull && git checkout -b claude/<sub-slug>` before TDD work.

### 2.3: Open PR against the feature branch

```
git push -u origin claude/<sub-slug>
gh pr create \
  --base feature/<slug> \
  --head claude/<sub-slug> \
  --title "<concise title>" \
  --body "Closes #<N>\n\nPart of #<root>\n\n<short summary>"
```

Capture PR number.

### 2.4: Review/fix loop

Follow `/review-fix-loop <pr-number> 5` — 5 rounds max, checkbox comments, items ticked as fixed. If still blocking after 5 rounds → **stop the entire iteration and report**. Don't proceed to next sub-issue. The feature branch is left as-is for the user to take over.

### 2.5: Wait for CI checks

Before merging, wait for all PR checks to complete:
```
gh pr checks <pr-number> --watch --fail-fast
```

- Exit 0 → checks green, proceed to 2.6.
- Non-zero → **stop the entire iteration and report**. Do not merge. Surface failing check names + run URLs.
- No checks registered at all → proceed (nothing to gate on); note it in the report.

### 2.6: Auto-merge into feature branch

On reviewer approval AND green checks:
```
gh pr merge <pr-number> --squash --delete-branch
git checkout feature/<slug> && git pull
```

The next sub-issue's branch will fork from this updated feature branch.

## Phase 3: Final report

When all sub-issues are done (or one stopped the loop):

- List all PRs created (merged + any failed)
- State of `feature/<slug>`: ahead of main by N commits, ready for review
- Optionally open a draft umbrella PR `feature/<slug>` → `main` so the user can see the cumulative diff. Title: "<root issue title>", body: "Closes #<root>\n\nUmbrella PR — auto-built from sub-issues. See individual PRs for review history."

## Rules

- **Never push to `main` directly.** Everything merges into `feature/<slug>` only.
- **Never auto-merge `feature/<slug>` to `main`** — that's the user's call.
- If the review/fix loop fails on any sub-issue, stop the entire iteration and report.
- Each sub-issue PR is independently reviewable (small diff vs. feature branch).
- Be concise.
