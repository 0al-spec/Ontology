# EXECUTE — Task Execution Wrapper

**Version:** 1.5.0

## Purpose

EXECUTE is a lightweight workflow wrapper for implementing tasks. It ensures the environment is ready, shows the PLAN PRD, lets you execute the implementation, and then validates/tests before committing.

## Inputs

- `SPECS/INPROGRESS/{TASK_ID}_{TASK_NAME}.md` produced by PLAN.
- `SPECS/INPROGRESS/next.md` to know the chosen task.
- [Params](.flow/params.yaml) — project configuration (`verify.*` and `structure.*` sections).
- REQUIRED Role Prompt: [TDD Executor Role](../ROLES/TDD_Executor.md) when implementation should follow an explicit outside-in TDD loop.

## Steps

1. **Pre-flight checks**
   - Confirm the working tree is clean: `git status -sb` (if not, remind to commit or stash other work).
   - Verify toolchain is available (language runtime, package manager, etc.).
   - Print the PRD summary and key acceptance criteria from the `SPECS/INPROGRESS` doc so you know the story.

2. **Work period**
   - If role prompts are enabled, use [TDD Executor Role](../ROLES/TDD_Executor.md) to drive the red-green-refactor loop during implementation.
   - Start by writing or updating tests before making implementation changes (test-first approach).
   - Follow the step-by-step tasks in the PRD. This is when you edit files, run tests, etc.
   - Use the PRD task plan for your commits (one commit per major change is ideal).

3. **REQUIRED Post-flight validation**
   Run your project's quality gates from [Params](.flow/params.yaml) under `verify.*`:

   **Common patterns (if params not yet configured):**
   - Tests: `npm test`, `pytest`, `cargo test`, `go test`, etc.
   - Linting: `npm run lint`, `ruff check src/`, `cargo clippy`, `golangci-lint`, etc.
   - Type checking: `npm run typecheck`, `mypy src/`, `cargo check`, etc. (if configured)
   - Coverage: `pytest --cov`, `npm run test:coverage`, `cargo tarpaulin`, etc.

4. **Refactor structure pass (if needed)**
   - Apply [`SPECS/COMMANDS/PRIMITIVES/REFACTORING.md`](./PRIMITIVES/REFACTORING.md) to split mixed changes into focused files before final commit.
   - Re-run validation after refactoring.

5. **Finalize**
   - Stage relevant files and commit per [`SPECS/COMMANDS/PRIMITIVES/COMMIT.md`](./PRIMITIVES/COMMIT.md).
   - Optionally update `SPECS/INPROGRESS/next.md` if metadata (priority, status) changed.
   - Suggest next task from `SPECS/Workplan.md` (SELECT will capture it later).

## Quality Gate Examples

### JavaScript/TypeScript (Node.js)

```bash
# Using npm/yarn/pnpm
npm test                    # Run tests
npm run lint               # ESLint or similar
npm run typecheck          # TypeScript check (if using TS)
npm run test:coverage      # Coverage report
```

### Python

```bash
# Using pytest
pytest                     # Run all tests
pytest -v                  # Verbose output
pytest --cov=src           # With coverage
ruff check src/            # Linting
mypy src/                  # Type checking
```

### Rust

```bash
# Using cargo
cargo test                 # Run tests
cargo clippy               # Linting
cargo check                # Type check
cargo tarpaulin --cov    # Coverage (requires cargo-tarpaulin)
```

### Go

```bash
# Using go toolchain
go test ./...              # Run tests
go test -cover ./...       # With coverage
golangci-lint run          # Linting
go vet ./...               # Static analysis
```

## Project Structure

Your project's directory layout is defined in [Params](.flow/params.yaml) under `structure.*`.

**Generic structure (if params not yet configured):**
```
/
├── src/ or lib/ or app/     # Source code (language-dependent)
├── tests/ or __tests__/     # Test files
├── docs/ or SPECS/          # Documentation
│   ├── Workplan.md          # Task tracker
│   ├── INPROGRESS/          # Active tasks
│   └── COMMANDS/            # Workflow commands
├── package.json / pyproject.toml / Cargo.toml / go.mod  # Config
└── Makefile / justfile      # Build automation (optional)
```

## Quality Gate Checklist

Before committing, ensure (as defined in your QualityGates.md template):
- [ ] All tests pass
- [ ] Linting passes with no errors
- [ ] Code coverage meets threshold (e.g., ≥80%)
- [ ] No regressions in existing tests
- [ ] Type checking passes (if applicable)

## Notes

- EXECUTE does not invent steps; it only organizes pre/post validations around the PRD.
- Read [Params](.flow/params.yaml) for your project's quality gate commands.
- Run `SETUP` if `.flow/params.yaml` does not exist yet.
- When the task is complete, mark the PRD ready for ARCHIVE.

## Role References (Optional)

- [TDD Executor Role](../ROLES/TDD_Executor.md) — enforces failing tests first, minimal implementation steps, green validation, and documentation updates during execution.

Use this role when you want EXECUTE to be explicitly test-first rather than just following the high-level PRD.
