---
name: simulator-release
description: Releases the claimed simulator back to the shared pool. Use before ending a session that claimed a simulator.
disable-model-invocation: true
---

# Release Simulator

Releases the simulator claimed by this session back to the pool.

## Process

1. Resolve the caller ID:
   ```bash
   CALLER_ID=$(basename "$(pwd)")
   ```

2. Release the simulator:
   ```bash
   bash ~/.claude/simulators/release.sh --caller-id "$CALLER_ID"
   ```

3. Report success or failure to the user.
