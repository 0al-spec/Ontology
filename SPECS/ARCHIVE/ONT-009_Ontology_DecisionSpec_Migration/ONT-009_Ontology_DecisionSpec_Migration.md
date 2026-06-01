# PRD: ONT-009 - Ontology DecisionSpec Migration

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Code Quality and Maintainability  
**Reasoning Effort:** high  
**Dependencies:** ONT-008  
**Parent PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## TL;DR

Move current classification branches into typed `SpecificationCore.DecisionSpec` implementations under `OntologyRules`, then wire `OntologyCompiler` through those decisions without changing behavior.

## Objective

Make non-boolean compiler decisions explicit, typed, and independently testable while preserving current `ontologyc` CLI outputs, diagnostics, generated artifacts, SpecGraph validation outputs, and compatibility reports.

## Scope

### In Scope

- Add typed decision contexts and result enums for:
  - relation range shape classification;
  - concept reference resolution classification;
  - SpecGraph resolved-vs-gap classification;
  - compatibility breaking-change classification.
- Implement decision specs using stable `SpecificationCore` primitives:
  - direct `DecisionSpec` conformance for payload-producing decisions;
  - existing ONT-008 boolean specs where they are useful building blocks.
- Wire compiler classification call sites through those decisions:
  - `relationRangeRefs`;
  - `normalizeRange`;
  - `resolves`;
  - SpecGraph validation loop;
  - compatibility breaking-change construction.
- Add focused `OntologyRulesTests` for each decision spec.
- Add ONT-009 validation report.

### Out of Scope

- Changing ontology validation semantics.
- Changing diagnostic codes, messages, or paths.
- Changing normalized IR, TypeScript output, SpecGraph output, or compatibility report shape.
- Replacing `[String: Any]` JSON/YAML representation with Codable models.
- Introducing `SpecificationCore` macros.
- Adding Ruby tooling.
- CLI command classification, unless it becomes necessary to preserve or simplify the above migrations. The current CLI switch is thin and not a maintenance bottleneck after ONT-007.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Relation range decision | `Sources/OntologyRules/RelationDecisionSpecs.swift` | Classifies scalar refs, `oneOf` refs, and invalid range values |
| D2 | Concept reference decision | `Sources/OntologyRules/ReferenceDecisionSpecs.swift` | Classifies refs as local, imported, unresolved, or invalid syntax |
| D3 | SpecGraph ref decision | `Sources/OntologyRules/SpecGraphDecisionSpecs.swift` | Classifies semantic refs as resolved or gap |
| D4 | Compatibility decision | `Sources/OntologyRules/CompatibilityDecisionSpecs.swift` | Classifies removed/changed items as compatible or breaking with current messages |
| D5 | Compiler integration | `Sources/OntologyCompiler/*.swift` | Existing branch sites call decision specs |
| D6 | Decision tests | `Tests/OntologyRulesTests/*DecisionSpecsTests.swift` | Each decision result branch is covered |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-009_Validation_Report.md` | Records build, tests, hashes, and no-Ruby audit |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Relation range classification MUST be represented as a decision spec. | Scalar, oneOf, and invalid shapes produce typed results. | `OntologyRulesTests` |
| FR-002 | Concept ref resolution MUST be represented as a decision spec. | Local, imported, unresolved, and invalid syntax cases produce typed results. | `OntologyRulesTests` |
| FR-003 | SpecGraph ref classification MUST be represented as a decision spec. | Known refs become resolved; missing refs become gaps. | `OntologyRulesTests`, regression tests |
| FR-004 | Compatibility classification MUST be represented as a decision spec. | Removed classes/relations and relation domain/range changes produce existing breaking messages. | `OntologyRulesTests`, regression tests |
| FR-005 | Compiler behavior MUST remain unchanged. | Baseline tests pass and generated output hash is unchanged. | `swift test --build-system swiftbuild`; hash check |
| FR-006 | New implementation MUST stay Swift-native. | No new Ruby files or Ruby commands are introduced. | no-Ruby audit |

## Implementation Roadmap

### Phase 1 - Decision Types

- Add typed result enums and context structs under `OntologyRules`.
- Keep contexts small and aligned to current compiler call-site inputs.
- Avoid moving materialization logic that depends on ordering or output IDs.

### Phase 2 - Compiler Wiring

- Replace relation range shape branches with `RelationRangeShapeDecisionSpec`.
- Replace boolean-only `resolves` implementation with `ConceptRefResolutionDecisionSpec`.
- Route SpecGraph resolved/gap branch through `SpecGraphRefDecisionSpec` while keeping de-duplication and ordinal assignment in the compiler.
- Route compatibility breaking-message construction through `CompatibilityChangeDecisionSpec`.

### Phase 3 - Validation

- Run `swift build`.
- Run `swift build --explicit-target-dependency-import-check error`.
- Run `swift test --build-system swiftbuild`.
- Run manual CLI regression for `check`, `compile`, `validate-specgraph`, and `diff`.
- Verify combined generated output hash remains unchanged.
- Run no-Ruby audit over changed files.

## Success Metrics

- `swift test --build-system swiftbuild` passes with all existing regression tests.
- Decision tests cover every result case introduced in ONT-009.
- Combined generated output hash remains `1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19`.
- Compatibility report remains byte-identical to the ONT-006 baseline.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Decision payload modeling changes output materialization | Behavioral regression | Keep ordering, de-duplication, and ordinal assignment in compiler orchestration |
| Compatibility decisions overreach beyond current behavior | Report drift | Classify only current removed/changed cases and keep current message strings |
| Decision specs duplicate helper logic | Future drift | Reuse ONT-008 specs where possible and keep decision tests close to branch semantics |
