# PRD: ONT-007 - `ontologyc` Compiler Module Split

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Code Quality and Maintainability  
**Reasoning Effort:** high  
**Dependencies:** ONT-006  
**Parent PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## TL;DR

Split the monolithic Swift `ontologyc` implementation into a thin CLI executable and an importable `OntologyCompiler` target. This task is strictly behavior-preserving: command lines, stdout/stderr text, exit codes, diagnostics, generated files, and baseline hashes must remain unchanged.

## Objective

Reduce `Sources/OntologyC/main.swift` from a single-file compiler into focused compiler modules while preserving the ONT-006 regression baseline.

## Scope

### In Scope

- Add an `OntologyCompiler` Swift target.
- Move production compiler implementation out of `Sources/OntologyC/main.swift`.
- Keep `OntologyC` as the public executable target.
- Keep CLI dispatch and process exit behavior equivalent.
- Split compiler code into focused files:
  - diagnostics;
  - compiler orchestration;
  - package loading;
  - package validation;
  - normalization;
  - TypeScript emission;
  - SpecGraph validation;
  - compatibility diff;
  - JSON/YAML IO helpers;
  - reference/string helpers.
- Update tests to continue using the public `ontologyc` CLI.
- Add ONT-007 validation report.

### Out of Scope

- Extracting real `OntologyRules` specifications.
- Migrating branches to `DecisionSpec`.
- Changing validation semantics.
- Changing generated TypeScript or normalized IR shape.
- Changing CLI output strings.
- Removing legacy Ruby validators.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | `OntologyCompiler` target | `Package.swift`, `Sources/OntologyCompiler/` | Compiler phases are importable and build under SwiftPM |
| D2 | Thin CLI executable | `Sources/OntologyC/main.swift` plus optional `CLI.swift` | CLI delegates to `OntologyCompiler` APIs and preserves behavior |
| D3 | Focused compiler files | `Sources/OntologyCompiler/*.swift` | No unrelated phases remain concentrated in `main.swift` |
| D4 | Regression validation | `Tests/OntologyCompilerTests/` | Existing ONT-006 regression tests pass unchanged or with path-only updates |
| D5 | Validation report | `SPECS/INPROGRESS/ONT-007_Validation_Report.md` | Records build, tests, CLI checks, hashes, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Public `ontologyc` commands MUST remain unchanged. | `check`, `compile`, `validate-specgraph`, and `diff` accept the same arguments. | ONT-006 regression tests |
| FR-002 | CLI output strings MUST remain unchanged. | PASS/error output remains byte-equivalent for tested scenarios. | Regression tests |
| FR-003 | Generated artifacts MUST remain byte-stable. | Compile output matches committed generated files. | Regression tests and hash check |
| FR-004 | `OntologyCompiler` MUST be importable. | SwiftPM builds a library target used by executable code. | `swift build` |
| FR-005 | `Sources/OntologyC/main.swift` MUST be thin. | It contains command invocation only, not validation/normalization/emission internals. | Code review |

## Implementation Roadmap

### Phase 1 - Target Setup

- Add `OntologyCompiler` library target.
- Move `Yams` dependency from `OntologyC` to `OntologyCompiler`.
- Make `OntologyC` depend on `OntologyCompiler`.

### Phase 2 - Mechanical Code Move

- Move `Diagnostic`, `LoadedPackage`, `JSONObject`, and `OntologyCompiler` into `Sources/OntologyCompiler/`.
- Keep method bodies behavior-equivalent.
- Make APIs public/internal only where needed by the CLI.

### Phase 3 - File Split

- Split the compiler extension into focused files.
- Preserve helper names and algorithms unless access control requires small signature changes.
- Keep sorting, hashing, and YAML/JSON output behavior unchanged.

### Phase 4 - Validation

- Run `swift build`.
- Run `swift test`.
- Run Flow file gates.
- Verify generated output hash remains unchanged.
- Save ONT-007 validation report.

## Success Metrics

- `swift build` passes.
- `swift test` passes.
- `Sources/OntologyC/main.swift` is only CLI entry code.
- Generated output combined hash remains `1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19`.
- No production behavior changes are observed by the ONT-006 regression harness.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Access-control changes alter behavior | Hidden regression | Keep APIs minimal and rely on CLI regression tests |
| Mechanical split introduces drift | Generated files differ | Compare outputs byte-for-byte and hash generated tree |
| Over-splitting makes follow-up harder | Review friction | Split by existing compiler phases, not tiny helpers |
| Accidentally starts ONT-008 work | Scope creep | Do not move predicates into `OntologyRules` in ONT-007 |
