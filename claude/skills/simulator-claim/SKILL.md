---
name: simulator-claim
description: Claims a simulator from the shared pool for this session. Use at session start when working on iOS projects that need a simulator.
disable-model-invocation: true
---

# Claim Simulator

Claims a simulator from the shared pool so multiple Claude Code instances don't collide.

## Process

1. Resolve the caller ID:
   ```bash
   CALLER_ID=$(basename "$(pwd)")
   ```

2. Claim a simulator:
   ```bash
   bash ~/.claude/simulators/claim.sh --caller-id "$CALLER_ID" --pid $PPID
   ```

3. Parse the output. It returns lines like:
   ```
   UDID=<uuid>
   DESTINATION=platform=iOS Simulator,id=<uuid>
   NAME=<simulator name>
   STATUS=new|existing
   ```

4. Store the UDID and DESTINATION values. Report to the user which simulator was claimed.

5. For the rest of the session, use the claimed UDID in all xcodebuild commands:
   ```
   -destination 'platform=iOS Simulator,id=<UDID>'
   ```

## Important Rules

- **Never** use `name=iPhone ...` in xcodebuild destinations — always use `id=<UDID>` from the pool.
- If the claim fails with "All simulators are claimed", run `bash ~/.claude/simulators/status.sh` and show the output to the user. Ask which simulator to free up.
