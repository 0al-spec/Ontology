---
name: flow-run
description: Run the complete task workflow for this repository by strictly following SPECS/COMMANDS/FLOW.md from BRANCH through ARCHIVE-REVIEW, including required commit checkpoints and quality gates. Use when asked to do the next task end-to-end, complete the full workflow, or execute "start to finish" task delivery in this project.
---

# Flow Run

Execute the workflow in `SPECS/COMMANDS/FLOW.md` exactly, without skipping required steps unless the workflow itself explicitly allows skipping.

## Required Inputs

Collect these before starting:
- Task identifier (for example `P5-T2`) and short description.
- Current branch and whether a feature branch already exists.
- Confirmation of which review subject name to use for `REVIEW_{subject}.md`.

If the task identifier is unknown, determine it from `SPECS/Workplan.md` and `SPECS/INPROGRESS/next.md` during SELECT.

Read `.flow/params.yaml` (`verify.*`) to get project-specific quality gate commands. If params are missing or incomplete, guide the user to run SETUP first.

## Execution Contract

Apply these rules throughout execution:
- Read `SPECS/COMMANDS/FLOW.md` at the beginning and treat it as the source of truth.
- Complete steps in order: `BRANCH -> SELECT -> PLAN -> EXECUTE -> ARCHIVE -> REVIEW -> FOLLOW-UP -> ARCHIVE-REVIEW`.
- Use the `flow-primitive-commit` skill (or standard git commits) for every commit checkpoint — stage only task-relevant files and use present-tense FLOW message patterns.
- Run required quality gates during EXECUTE (tests, linting, type checking if configured, coverage check).
- Read quality gate commands from `.flow/params.yaml` (`verify.*`); if not configured, use common defaults for the detected language.
- Record artifacts in expected locations under `SPECS/INPROGRESS/` and `SPECS/ARCHIVE/`.
- If REVIEW has no actionable issues, skip FOLLOW-UP and proceed directly to ARCHIVE-REVIEW, as FLOW permits.

## Step Procedure

1. BRANCH
- Ensure `main` is up to date.
- Create `feature/{TASK_ID}-{short-description}` if not already on the correct feature branch.
- Commit message pattern: `Branch for {TASK_ID}: {short description}`.

2. SELECT
- Choose the next task from `SPECS/Workplan.md`.
- Update `SPECS/INPROGRESS/next.md` with selected task metadata.
- Commit message pattern: `Select task {TASK_ID}: {TASK_NAME}`.

3. PLAN
- Create the task PRD at `SPECS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md`.
- Define deliverables, acceptance criteria, dependencies.
- Commit message pattern: `Plan task {TASK_ID}: {TASK_NAME}`.

4. EXECUTE
- Implement to the PRD.
- Run quality gates defined in FLOW and `.flow/params.yaml` (`verify.*`).
- Create `SPECS/INPROGRESS/{TASK_ID}_Validation_Report.md`.
- Commit message pattern: `Implement {TASK_ID}: {brief description of changes}`.
- For large tasks, commit incrementally after each logical unit of work.

5. ARCHIVE
- Run `SPECS/COMMANDS/ARCHIVE.md` workflow.
- Verify task archive folder exists under `SPECS/ARCHIVE/{TASK_ID}_{TASK_NAME}/`.
- Confirm `SPECS/INPROGRESS/next.md` and `SPECS/Workplan.md` are updated.
- Commit message pattern: `Archive task {TASK_ID}: {TASK_NAME} ({VERDICT})`.

6. REVIEW
- Run `SPECS/COMMANDS/REVIEW.md`.
- Save review report at `SPECS/INPROGRESS/REVIEW_{subject}.md`.
- Commit message pattern: `Review {TASK_ID}: {short subject}`.

7. FOLLOW-UP
- If review has actionable findings, run `SPECS/COMMANDS/PRIMITIVES/FOLLOW_UP.md`.
- Add follow-up tasks to `SPECS/Workplan.md`.
- Commit message pattern: `Follow-up {TASK_ID}: {short subject}`.
- If no actionable findings, explicitly note FOLLOW-UP skipped.

8. ARCHIVE-REVIEW
- Move `REVIEW_{subject}.md` to `SPECS/ARCHIVE/_Historical/` or relevant task folder.
- Update `SPECS/ARCHIVE/INDEX.md`.
- Commit message pattern: `Archive REVIEW_{subject} report`.

## Optional Post-FLOW Actions

If the user explicitly asks for PR and CI handling, do it after ARCHIVE-REVIEW:
- Open a pull request from the feature branch into `main`.
- Include quality gate results and reference the validation report.
- Review CI outcomes and iterate on fixes if checks fail.

## Completion Criteria

Consider the run complete only when all are true:
- FLOW step sequence has been fully executed (or optional FOLLOW-UP formally skipped due to no findings).
- Required artifacts exist in `SPECS/INPROGRESS/` and/or `SPECS/ARCHIVE/`.
- Required quality gates were run and outcomes captured.
- Every commit checkpoint was created with FLOW message patterns.

## Trigger Phrases

Use this skill when requests look like:
- "Do the next task from start to end."
- "Run the full FLOW workflow for the next task."
- "Take this task all the way through branch, plan, execute, archive, and review."
- "Strictly follow the instructions in the @SPECS/COMMANDS/FLOW.md file carefully for the next task. Do not stop between steps. Complete each phase of the FLOW process one by one without asking questions or pausing."
