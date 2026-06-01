---
name: flow-setup
description: Install and initialize Flow in a target repository using either the local installer (`install.sh`) or the pinned-and-verified bootstrap flow. Use when asked to set up Flow in a new repo, re-install Flow-managed command files safely, scaffold required SPECS files, or create `.flow/params.yaml` for a project stack.
---

# Flow Setup

Install Flow in the target repository and leave it ready for SELECT/PLAN execution.

## Required Inputs

Collect these before running setup:
- Target repository path (default: current directory).
- Preferred install mode:
  - Local installer from a checked-out Flow repo.
  - Pinned release bootstrap with checksum verification (recommended for production repos).
- Project values for `.flow/params.yaml`:
  - `project.name`
  - `project.language`
  - `project.default_branch`
  - `verify.tests`
  - `verify.lint`
  - optional coverage threshold and extra sections used by the project.

## Install Mode Selection

1. Use pinned bootstrap for production repositories, CI usage, or when reproducibility matters.
2. Use local installer when actively developing Flow and applying local changes immediately.

## Setup Procedure

1. Validate target path
- Ensure the target repo exists.
- Ensure shell commands can run in that directory.

2. Run installation
- Local install:
```bash
bash /path/to/Flow/install.sh /path/to/target-repo
```
- From inside Flow repo:
```bash
./install.sh /path/to/target-repo
```
- Pinned + verified bootstrap (from Flow repo):
```bash
bash docs/flow-bootstrap.sh /path/to/target-repo
```
- Pinned + verified bootstrap with explicit version:
```bash
FLOW_VERSION=v1.5.0 bash docs/flow-bootstrap.sh /path/to/target-repo
```

3. Verify install artifacts
- Confirm managed directories exist in target repo:
  - `SPECS/COMMANDS/`
  - `SPECS/ROLES/`
  - `SPECS/VERSION`
- Confirm user-owned scaffolding exists:
  - `SPECS/Workplan.md`
  - `SPECS/ARCHIVE/INDEX.md`
  - `SPECS/INPROGRESS/next.md`
  - `.flow/`

4. Configure `.flow/params.yaml`
- Create or update `.flow/params.yaml` using `SPECS/COMMANDS/SETUP.md` as the source of truth.
- Populate at least:
  - `project.name`
  - `project.language`
  - `project.default_branch`
  - `verify.tests`
  - `verify.lint`

5. Prepare first run state
- Replace example tasks in `SPECS/Workplan.md` with real project tasks.
- Ensure `SPECS/INPROGRESS/next.md` points to the next task.
- Confirm repository is ready to run `FLOW.md` from BRANCH through ARCHIVE-REVIEW.

## Idempotency Rules

- Re-running install is allowed.
- `install.sh` updates Flow-managed content (`SPECS/COMMANDS`, `SPECS/ROLES`, `SPECS/VERSION`) and preserves user-owned files when they already exist.
- Never overwrite user task history or archive records unless explicitly requested.

## Completion Checklist

- Installation command succeeded.
- Required directories/files are present.
- `.flow/params.yaml` exists and matches the project toolchain.
- Workplan and next-task files are no longer placeholders.
- User can proceed with SELECT/PLAN or full `flow-run`.
