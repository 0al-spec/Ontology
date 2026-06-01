---
name: flow-update
description: Update Flow in an existing repository using either local `install.sh` or pinned-and-verified `docs/flow-bootstrap.sh`, while preserving user-owned planning artifacts. Use when asked to upgrade Flow command files, refresh SPECS/ROLES/COMMANDS from a newer Flow release, or verify that a repo is on the expected Flow version.
---

# Flow Update

Upgrade Flow-managed files in place and confirm user-owned artifacts remain intact.

## Required Inputs

Collect before update:
- Target repository path.
- Current Flow source:
  - Local Flow checkout path, or
  - Pinned release version (for bootstrap).
- Preferred mode:
  - Local `install.sh` update (fast for development).
  - Pinned `docs/flow-bootstrap.sh` update (recommended for production).

## Pre-Update Safety Checks

1. Inspect target repo state
- Check branch and uncommitted changes.
- If the repo has unrelated local changes, warn before updating.

2. Detect current Flow footprint
- Check whether these paths already exist:
  - `SPECS/COMMANDS/`
  - `SPECS/ROLES/`
  - `SPECS/VERSION`
  - `.flow/params.yaml`

3. Capture current version
- If `SPECS/VERSION` exists, record it.
- If missing, continue and treat as unknown legacy state.

## Update Procedure

1. Choose update mode
- Use pinned bootstrap for team/CI reproducibility.
- Use local installer when testing local Flow changes.

2. Run update command
- Local update:
```bash
bash /path/to/Flow/install.sh /path/to/target-repo
```
- Pinned + verified update:
```bash
cd /path/to/Flow
bash docs/flow-bootstrap.sh /path/to/target-repo
```
- Pinned + verified update for specific release:
```bash
cd /path/to/Flow
FLOW_VERSION=v1.5.0 bash docs/flow-bootstrap.sh /path/to/target-repo
```

3. Validate update result
- Confirm managed directories/files exist after update:
  - `SPECS/COMMANDS/`
  - `SPECS/ROLES/`
  - `SPECS/VERSION`
- Confirm user-owned artifacts still exist:
  - `SPECS/Workplan.md`
  - `SPECS/ARCHIVE/INDEX.md`
  - `SPECS/INPROGRESS/next.md`
  - `.flow/params.yaml`

4. Verify version bump or refresh
- Read `SPECS/VERSION` after update.
- Compare pre/post version when pre-version was known.

5. Summarize repo impact
- Show changed files in the target repo.
- Call out whether any user-owned files changed unexpectedly.

## Expected Behavior Contract

- `install.sh` updates Flow-managed content (`SPECS/COMMANDS`, `SPECS/ROLES`, `SPECS/VERSION`).
- Existing user files are preserved and only created when missing:
  - `SPECS/Workplan.md`
  - `SPECS/ARCHIVE/INDEX.md`
  - `SPECS/INPROGRESS/next.md`
  - `.flow/`
- Bootstrap mode must fail on checksum mismatch.

## Completion Checklist

- Update command succeeded without errors.
- Flow-managed files are present and refreshed.
- User-owned planning/state files remain available.
- `SPECS/VERSION` is confirmed and reported.
- Target repository is ready to continue with `flow-run`.
