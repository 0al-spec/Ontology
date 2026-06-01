# Workflow Commands

**Version:** 1.5.0

## Overview

This folder holds the command prompts that orchestrate the documentation-driven workflow. Each command focuses on one phase:

| Command | Purpose | Reference |
|---------|---------|-----------|
| **SETUP** | **Configure Flow for your project (run first!)** | [SETUP.md](./SETUP.md) |
| SELECT  | Pick the next task from the workplan | [SELECT.md](./SELECT.md) |
| PLAN    | Write the implementation PRD for the selected task | [PLAN.md](./PLAN.md) |
| EXECUTE | Run pre-flight/post-flight steps around your coding | [EXECUTE.md](./EXECUTE.md) |
| PROGRESS | Optional checkpointing inside `next.md` | [PROGRESS.md](./PROGRESS.md) |
| REVIEW  | Produce structured code reviews | [REVIEW.md](./REVIEW.md) |
| ARCHIVE | Move finished PRDs into `SPECS/ARCHIVE/` | [ARCHIVE.md](./ARCHIVE.md) |

Additional helpers live in `PRIMITIVES/` (toolchain, commits, doc updates, archive maintenance).
Main tasks tracker: `SPECS/Workplan.md`.

## Workflow

```
SELECT → updates SPECS/INPROGRESS/next.md
 PLAN  → creates SPECS/INPROGRESS/{TASK}.md
EXECUTE → tests, linting, commits
             ↓
          ARCHIVE → moves completed PRDs into SPECS/ARCHIVE/
```

Running `PROGRESS` lets you keep `next.md` up to date during long tasks, while `REVIEW` provides independent quality checkpoints before or after merging.

## Structure

```
.flow/
└── params.yaml                  # Your project config (survives Flow updates)

SPECS/
├── Workplan.md                  # Your task tracker        ← user data
├── ARCHIVE/                     # Completed PRDs           ← user data
│   ├── INDEX.md
│   └── {TASK_ID}_{TASK_NAME}/
│       ├── {TASK_ID}_{TASK_NAME}.md
│       └── {TASK_ID}_Validation_Report.md
├── INPROGRESS/                  # Active tasks             ← user data
│   ├── next.md
│   └── {TASK_ID}_{TASK_NAME}.md
├── COMMANDS/                    # ← managed by Flow, refreshed by installs
│   ├── README.md
│   ├── FLOW.md
│   ├── SETUP.md
│   ├── SELECT.md
│   ├── PLAN.md
│   ├── EXECUTE.md
│   ├── REVIEW.md
│   ├── ARCHIVE.md
│   ├── PROGRESS.md
│   └── PRIMITIVES/
│       ├── COMMIT.md
│       ├── ARCHIVE_TASK.md
│       ├── FOLLOW_UP.md
│       ├── DOCS.md
│       └── REFACTORING.md
└── ROLES/                       # ← role prompts managed by Flow
```

## Quick Start

1. Run `SELECT` to choose the highest-priority task from `SPECS/Workplan.md` and write `SPECS/INPROGRESS/next.md`.
2. Run `PLAN` to produce the PRD in `SPECS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`.
3. Run `EXECUTE` to follow the PRD, run tests/linting, and commit.
4. Repeat. When a task finishes, move it to `SPECS/ARCHIVE/` via ARCHIVE.

## Installation

```bash
# In the Flow repo, run:
./install.sh /path/to/your/repo

# Or from inside your repo:
/path/to/flow/install.sh
```

The script copies the `SPECS/COMMANDS/` and `SPECS/ROLES/` folders managed by Flow, then creates `SPECS/Workplan.md`, `SPECS/ARCHIVE/INDEX.md`, and `SPECS/INPROGRESS/next.md` from the example templates — skipping any user-owned files that already exist.

**To update Flow later:** run `install.sh` again. It refreshes the `SPECS/COMMANDS/` and `SPECS/ROLES/` folders managed by Flow only — your workplan, archive, and `.flow/params.yaml` are never touched.

## First-Time Setup

After installing:

1. Fill in `.flow/params.yaml` — see [`SETUP.md`](./SETUP.md) for the template
2. Edit `SPECS/Workplan.md` with your actual tasks

## Customization

Flow reads project-specific values from `.flow/params.yaml` at the repo root:

```yaml
project:
  name: MyProject
  default_branch: main

verify:
  tests: npm test
  lint: npm run lint
  coverage_threshold: 80

nfrs:
  api_response_ms: 200

structure:
  source: src/
  tests: tests/
```

Commands reference it as `[Params](.flow/params.yaml)`. See [SETUP.md](./SETUP.md) to create yours.

This file is yours — update Flow by replacing `SPECS/`, not `.flow/`.

## Notes

- **Run SETUP first** to create `.flow/params.yaml` for your project
- Keep `SPECS/INPROGRESS/` slim — only one task should be active at a time.
- Document completed work in `SPECS/ARCHIVE/` (PRDs stay for reference) and update `SPECS/Workplan.md` when needed.
- This workflow is language-agnostic. Configure your quality gates in `.flow/params.yaml` under `verify.*`.
