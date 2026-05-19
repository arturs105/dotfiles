---
description: Run the full issue → PR pipeline (plan → TDD → PR → review → fix loop).
argument-hint: <issue-number-or-url>
---

# Work Issue

Orchestrate the full pipeline for the given issue. Spawn each phase as a subagent. Be concise throughout.

## Phase 0: Resolve issue number

The argument is `<issue>`. If it's a URL (e.g. `https://github.com/foo/bar/issues/42`), extract the trailing path segment as the number. Otherwise use it as the number directly. If the URL points to a different repo than the current working directory's `origin`, stop and report — this command operates on the local repo. Substitute the resolved number wherever `<issue>` appears below.

## Phase 1: Plan (skipped if already approved)

Check if the issue already has the `plan-approved` label:
```
gh issue view <issue> --json labels --jq '.labels[].name' | grep -q '^plan-approved$' && echo SKIP
```

**If `plan-approved` label is present**: skip the planner. The issue body or an existing comment is the plan. Extract the branch name:
- If a comment with `**Branch:**` exists, use that.
- Otherwise, derive a 4-5 word semantic slug from the issue title: `claude/<slug>` (e.g. `claude/fix-waveform-zoom-drift`). Show the user the derived branch name and confirm via `AskUserQuestion` before proceeding.

**Otherwise**: spawn the `issue-planner` subagent: "Plan issue #<issue>." The planner will read the issue, grill-me through Q&A with the user, and post a plan comment that ends with adding the `plan-approved` label and includes a semantic branch name.

Once the planner returns:
- Verify the issue has the `plan-approved` label
- Read the plan comment and extract the branch name

If anything is off, stop and report.

## Phase 2: TDD Implementation

Spawn the `tdd` subagent: "Implement issue #<issue> via TDD on the branch named in the plan comment."

The agent will:
- Create the branch
- Drive red-green-refactor in vertical slices
- Run the project's full test suite at the end

When it returns, run the project's test command yourself to verify (look it up from `CLAUDE.md`, or infer from the project type — `package.json` → `npm test`, `Cargo.toml` → `cargo test`, `*.xcodeproj` → `xcodebuild test ...`, `pyproject.toml` → `pytest`, etc.).

## Phase 3: Open PR

Push the branch and open a PR linked to the issue:

```
git push -u origin <branch>
gh pr create --title "<concise title>" --body "Closes #<issue>\n\n<short summary>" --base main
```

Capture the PR number for later phases.

## Phase 4: Review/Fix Loop

Follow the protocol from `/review-fix-loop <pr-number> 5` — 5 rounds max, reviewer posts checkbox comments, fixer ticks items as it addresses them. If after 5 rounds the reviewer still has blocking items, stop and report. Do not merge.

## Phase 5: Wait for CI checks

After the review/fix loop, wait for all PR checks to finish:
```
gh pr checks <pr-number> --watch --fail-fast
```

- Exit 0 → green, proceed to final report.
- Non-zero → record failing checks + run URLs; surface in the final report so the user doesn't merge a red PR.
- No checks registered → note it (the PR has nothing gating it on CI).

## Phase 6: Final Report

Post a final summary comment on the issue with:
- PR link
- Number of review cycles used
- CI check status (green / failing checks + run URLs / none registered)
- Any unresolved suggestions the user might want to address manually

## Rules

- Be concise in all output and commit messages — match the project's style
- Never merge the PR — that's the user's call
- If any phase fails or returns ambiguous results, stop and report rather than guessing
- Each subagent gets a fresh context — pass enough info in the prompt that it doesn't need to re-derive things
