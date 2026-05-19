---
description: Run N rounds of review → fix on a PR. Each review is a checkbox comment; fixer ticks items as it addresses them.
argument-hint: <pr-number-or-url> [rounds=3]
---

# Review/Fix Loop

Run up to **${2:-3}** review/fix cycles on the given PR. Stop early if the reviewer approves.

## Phase 0: Resolve PR number and verify

The first argument is `<pr>`. If it's a URL (e.g. `https://github.com/foo/bar/pull/152`), extract the trailing path segment as the number. Otherwise use it as the number directly. If the URL points to a different repo than the current working directory's `origin`, stop and report. Substitute the resolved number wherever `<pr>` appears below.

Verify the PR exists and is open:
```
gh pr view <pr> --json state,headRefName,baseRefName,title
```

Stop if it's not open. Capture `headRefName` so subsequent fixer pushes go to the right branch.

## Phase 1: Loop (max ${2:-3} rounds)

For each round 1..N:

### 1.1: Review

Spawn the `reviewer` subagent: "Review PR #<pr>. This is round <round-number>."

The reviewer:
- Reads the diff and surrounding code
- Posts a new `## Review (round <N>)` comment with `- [ ]` checkbox blocking items + bullet suggestions
- Or just `### Approved` if clean

### 1.2: Check outcome

Read the latest review comment:
```
gh api repos/{owner}/{repo}/issues/<pr>/comments \
  --jq '[.[] | select(.body | startswith("## Review (round"))] | last'
```

- **Approved (no `Blocking` section, or all items already ticked)**: break the loop, report success.
- **Blocking items present**: continue to fix step.

### 1.3: Fix

Spawn the `fixer` subagent: "Address the latest review on PR #<pr>, ticking each `- [ ]` item as you complete it."

The fixer addresses each blocking item, ticks it in the review comment via PATCH, commits incrementally, runs tests, and pushes.

### 1.4: Loop or bail

If round count reaches max and reviewer still has blocking items: **stop and report**. Do not silently exceed the cap.

## Phase 2: Final report

Print:
- PR link
- Number of rounds used
- Final state (approved / still blocking after max rounds)
- Brief list of suggestions that were intentionally skipped (from fixer's summary comments)

## Rules

- Never merge the PR — orchestrators or the user decide that
- Each round = one review comment + one fix pass; don't merge fix work into a single round
- If the fixer can't address an item (push back is reasonable), it should explain in its summary comment, leave the box unticked, and the next reviewer round picks it up
- Be concise
