---
name: mark-review-item
description: Marks a code review item as completed by striking it through in the GitHub PR review comment. Accepts a review URL and item number.
disable-model-invocation: true
---

You are a skill that marks a single code review item as completed by applying strikethrough formatting to it in a GitHub PR review comment.

## Triggers

- "mark it as completed"
- "cross it out"
- "mark item N as completed"
- "cross out item N"

## Input

`$ARGUMENTS` — a string containing:
1. **Review URL** (required): `https://github.com/{owner}/{repo}/pull/{pr}#pullrequestreview-{id}`
2. **Item number** (required): which item to strike through (1-based)
3. **Explanation** (optional): reason/note to append below the struck-through item

Example:
```
/mark-review-item https://github.com/owner/repo/pull/42#pullrequestreview-123456 3 Fixed by extracting to a helper
```

## Process

### 1. Parse the URL

Extract from the review URL:
- `owner` and `repo` from the path
- `pr` number from `/pull/{pr}`
- `review_id` from `#pullrequestreview-{id}`

If the URL doesn't match this pattern, report the error and stop.

### 2. Fetch the current review body

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/reviews/{review_id} --jq '.body'
```

### 3. Identify item N

Items are numbered sequentially as they appear in the review body. An "item" is a block that starts with a numbered or bulleted line under a section header (like `### 🔴 Critical`, `### 🟠 Important`, `### 🟡 Suggestions`). Each item may span multiple lines (title line + body/detail lines) until the next item or section starts.

Count items across all sections in document order to find item N.

### 4. Apply strikethrough

For the identified item:
- Wrap the **title line** (the numbered/bulleted line) with `~~...~~` and append ` ✅`
- Wrap each **body line** belonging to that item with `~~...~~` (skip lines that are already struck through)
- Do NOT modify lines belonging to other items
- If an explanation was provided, add a blockquote line `> {explanation}` immediately after the last line of the item

Example before:
```
**2. Fix null check in UserService**
The guard statement on line 42 should handle the optional properly.
```

Example after (with explanation):
```
~~**2. Fix null check in UserService**~~ ✅
~~The guard statement on line 42 should handle the optional properly.~~
> Added proper optional binding with guard let
```

### 5. Update the review on GitHub

```bash
gh api --method PUT repos/{owner}/{repo}/pulls/{pr}/reviews/{review_id} -f body='<new body>'
```

Use a heredoc or temp file to avoid shell quoting issues with the body content.

### 6. Confirm

Output a brief confirmation: which item was marked and the review URL.

## Important Rules

1. **Only modify the target item** — leave all other items and text untouched
2. **Preserve formatting** — keep markdown structure, headers, and whitespace intact
3. **Idempotent** — if the item is already struck through, do nothing and report that
4. **Safe quoting** — the review body may contain special characters; use a temp file for the API call body to avoid shell injection
