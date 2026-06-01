---
name: "follow_up"
description: "Use when a review produced actionable findings and you need to create tracked follow-up tasks in the workplan."
---

# FOLLOW_UP — Create Subtasks from Review Findings

**Version:** 1.5.0

## Overview

After completing a review, extract actionable issues and add them as new tasks to the workplan. This ensures findings are tracked and addressed in future iterations.

## Inputs

| Variable | Description |
|----------|-------------|
| `REVIEW_FILE` | Review report filename (e.g., `REVIEW_api_refactor.md`) |
| `PARENT_TASK_ID` | Original task ID that was reviewed (e.g., `P2-T1`) |

## Steps

### 1. Extract Actionable Issues

Read the review report and identify items that require follow-up work:
- Bug fixes
- Missing functionality
- Performance improvements
- Documentation gaps
- Test coverage needs

### 2. Determine Task IDs

For each new task, assign an appropriate ID following the workplan convention:
- Use the same phase prefix as parent (e.g., `P2-T5` follows `P2-T4`)
- Or create a new category if the issue spans multiple areas

### 3. Add Tasks to Workplan

Update `SPECS/Workplan.md` with new task entries following the existing format:

```markdown
#### P2-T5: New Task Description
- **Description:** Brief description
- **Priority:** P1
- **Dependencies:** P2-T1
- **Parallelizable:** yes/no
- **Acceptance Criteria:** What needs to be true
```

### 4. Leave Review Report for ARCHIVE-REVIEW

Do not move or archive `${REVIEW_FILE}` during FOLLOW_UP. The main workflow has a separate ARCHIVE-REVIEW step that owns moving `REVIEW_{subject}.md` out of `SPECS/INPROGRESS/`.

## Postconditions

- New tasks added to `SPECS/Workplan.md`
- Review report remains in `SPECS/INPROGRESS/` for the ARCHIVE-REVIEW step
- No review files are moved during FOLLOW_UP

## Skip Conditions

Skip this step if:
- Review found no actionable issues
- All issues were minor and fixed during review
- Issues are duplicates of existing tasks
