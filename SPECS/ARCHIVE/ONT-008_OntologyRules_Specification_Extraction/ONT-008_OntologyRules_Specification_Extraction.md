# PRD: ONT-008 - OntologyRules Specification Extraction

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Code Quality and Maintainability  
**Reasoning Effort:** high  
**Dependencies:** ONT-007  
**Parent PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`

## TL;DR

Move existing validation predicates into named `SpecificationCore` specifications under `OntologyRules`, then wire the compiler through those specs without changing behavior.

## Objective

Make ontology validation rules explicit, reusable, and independently testable while preserving the current `ontologyc` outputs and diagnostics.

## Scope

### In Scope

- Add `OntologyRules` domain contexts for reference resolution, trigger resolution, and state validation.
- Add named `SpecificationCore` specs for:
  - metadata and package shape patterns;
  - concept reference syntax and resolution;
  - unsafe YAML keys, tags, and executable-looking values;
  - relation range shape;
  - allowed policy enforceability;
  - state name and transition state checks.
- Add `OntologyRulesTests` for each rule cluster.
- Wire `OntologyCompiler` validation helpers through `OntologyRules` specs.
- Keep all CLI behavior and generated outputs byte-stable.
- Add ONT-008 validation report.

### Out of Scope

- `DecisionSpec` migration for relation range shape, ref resolution, SpecGraph gaps, or compatibility changes.
- Changing diagnostic codes, messages, or paths.
- Changing normalized IR or TypeScript output.
- Adding new ontology semantics.
- Removing legacy Ruby validators.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Rule domain contexts | `Sources/OntologyRules/DomainTypes.swift` | Contexts model current compiler predicate inputs |
| D2 | Metadata/package specs | `Sources/OntologyRules/MetadataSpecs.swift`, `PackageShapeSpecs.swift` | Current naming/version/package predicates are represented |
| D3 | Reference specs | `Sources/OntologyRules/ReferenceSpecs.swift` | Concept and trigger reference checks are represented |
| D4 | Security specs | `Sources/OntologyRules/SecuritySpecs.swift` | Unsafe YAML checks are represented |
| D5 | Relation/policy/state specs | `Sources/OntologyRules/RelationSpecs.swift`, `PolicySpecs.swift`, `StateMachineSpecs.swift` | Current relation, policy, and state predicates are represented |
| D6 | Rule tests | `Tests/OntologyRulesTests/` | Each spec cluster has focused unit tests |
| D7 | Compiler integration | `Sources/OntologyCompiler/*.swift` | Compiler uses named specs for current predicates |
| D8 | Validation report | `SPECS/INPROGRESS/ONT-008_Validation_Report.md` | Records build, tests, hashes, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Metadata and package-shape predicates MUST be named specs. | ID, namespace, version, symbol name, state name, and concept ref patterns are specs. | `OntologyRulesTests` |
| FR-002 | Reference checks MUST be named specs. | Local, imported, resolvable, and local trigger refs are specs. | `OntologyRulesTests` |
| FR-003 | Security checks MUST be named specs. | Unsafe key, tag, and executable-looking value checks are specs. | `OntologyRulesTests` |
| FR-004 | Relation, policy, and state checks MUST be named specs. | Range shape, enforceability, and transition state predicates are specs. | `OntologyRulesTests` |
| FR-005 | Compiler behavior MUST remain unchanged. | ONT-006 regression tests pass and generated output hash is unchanged. | `swift test`; hash check |

## Implementation Roadmap

### Phase 1 - Rule Types and Tests

- Replace the ONT-006 scaffold with real rule files.
- Add focused tests for each rule cluster.

### Phase 2 - Compiler Wiring

- Make `OntologyCompiler` depend on `OntologyRules`.
- Route existing helper predicates through named specs.
- Avoid changing diagnostic creation sites except predicate implementation calls.

### Phase 3 - Validation

- Run `swift build`.
- Run `swift test`.
- Run Flow file gates.
- Verify generated output hash remains unchanged.
- Save ONT-008 validation report.

## Success Metrics

- `swift build` passes.
- `swift test` passes.
- `OntologyRulesTests` cover all extracted clusters.
- Generated output hash remains `1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19`.
- No CLI output changes are observed by regression tests.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Predicate extraction changes edge behavior | Hidden validation regression | Keep specs equivalent to current helper logic and rely on invalid fixture tests |
| Rule contexts become too broad | Harder future decision migration | Keep contexts small and focused |
| ONT-009 work leaks into ONT-008 | Scope creep | Do not introduce decision-returning specs in this task |
