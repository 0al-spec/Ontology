# Project Workplan — Example

Replace this file with your own tasks. Installed to `SPECS/Workplan.md` by `install.sh`.
Delete the example phases below and add your own.

---

## Phase 1: Foundation

#### P1-T1: Project Setup
- **Description:** Initialize repository, tooling, and basic structure
- **Priority:** P0
- **Dependencies:** None
- **Parallelizable:** no
- **Acceptance Criteria:**
  - Repository initialized with proper structure
  - Basic tooling configured (linting, tests)
  - CI/CD pipeline set up

#### P1-T2: Core Architecture
- **Description:** Design and implement core system architecture
- **Priority:** P0
- **Dependencies:** P1-T1
- **Parallelizable:** no
- **Acceptance Criteria:**
  - Architecture document approved
  - Basic module structure implemented
  - Integration tests passing

---

## Phase 2: Features

#### P2-T1: Feature A Implementation
- **Description:** Implement the main feature A
- **Priority:** P1
- **Dependencies:** P1-T2
- **Parallelizable:** yes
- **Acceptance Criteria:**
  - Feature A functional
  - Unit tests >80% coverage
  - Documentation complete

#### P2-T2: Feature B Implementation
- **Description:** Implement feature B
- **Priority:** P1
- **Dependencies:** P1-T2
- **Parallelizable:** yes
- **Acceptance Criteria:**
  - Feature B functional
  - Integration with Feature A verified

---

## Phase 3: Polish

#### P3-T1: Documentation
- **Description:** Complete user and developer documentation
- **Priority:** P2
- **Dependencies:** P2-T1, P2-T2
- **Parallelizable:** yes
- **Acceptance Criteria:**
  - README complete
  - API documentation published
  - Usage examples provided

#### P3-T2: Performance Optimization
- **Description:** Optimize critical paths
- **Priority:** P2
- **Dependencies:** P2-T1, P2-T2
- **Parallelizable:** no
- **Acceptance Criteria:**
  - Benchmarks meet NFRs
  - Performance regression tests added

---

## Task Status Legend

- **Not Started** — Task defined but not yet begun
- **INPROGRESS** — Task currently being worked on
- **✅ Complete** — Task finished and archived

## Adding New Tasks

When adding tasks, follow this format:

```markdown
#### {PHASE}-{NUMBER}: {Task_Name}
- **Description:** Brief description of the task
- **Priority:** P0/P1/P2 (P0 = critical, P1 = important, P2 = nice-to-have)
- **Dependencies:** Comma-separated list of task IDs or "None"
- **Parallelizable:** yes/no (can this be worked on in parallel with others)
- **Acceptance Criteria:**
  - Criterion 1
  - Criterion 2
```
