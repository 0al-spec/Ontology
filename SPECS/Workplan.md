# Project Workplan — Ontology

This workplan tracks the specification work for the Ontology repository. The initial source material is preserved in `SPECS/raw/`.

---

## Phase 1: Foundation

#### ONT-001: Ontology Layer and SpecGraph Semantic Import
- **Description:** Define the lower-level Ontology Layer, TypeScript-oriented ontology compiler contract, SpecGraph semantic import/reference artifacts, and the `examcalc` golden ontology example.
- **Priority:** P0
- **Dependencies:** None
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import.md`
- **Source:** `SPECS/raw/Агентная_Операционная_Система_-_Branch_SpecGraph_-_Онтологии.json`
- **Acceptance Criteria:**
  - Complete: Core artifacts `OntologyImport`, `ConceptRef`, `SemanticBinding`, `OntologyGap`, and `OntologyLockfile` are specified.
  - Complete: `DomainOntologyPackage` YAML schema contract is specified.
  - Complete: TypeScript foundation model and normalized compiler IR are specified.
  - Complete: `ontologyc` validation and compile behavior is specified.
  - Complete: `examcalc` ontology example contains required classes, relations, policies, and state machine.
  - Complete: SpecGraph examples reference ontology concepts without duplicating domain definitions.
  - Complete: Security rule forbids executing ontology YAML.

---

## Phase 2: Implementation Candidates

#### ONT-002: Ontology Package Schema and Fixtures
- **Description:** Implement machine-readable schema files and valid/invalid fixtures for `DomainOntologyPackage`.
- **Priority:** P1
- **Dependencies:** ONT-001
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-002_Ontology_Package_Schema_and_Fixtures/ONT-002_Ontology_Package_Schema_and_Fixtures.md`
- **Acceptance Criteria:**
  - Complete: Schema validates required metadata, classes, relations, policies, and state machines.
  - Complete: Invalid fixtures cover missing metadata, invalid inheritance, unknown relation refs, and unsafe executable-looking YAML.

#### ONT-003: `examcalc` Golden Ontology Package
- **Description:** Materialize the exam-controlled calculator ontology package from the PRD.
- **Priority:** P1
- **Dependencies:** ONT-001
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-003_examcalc_Golden_Ontology_Package/ONT-003_examcalc_Golden_Ontology_Package.md`
- **Acceptance Criteria:**
  - Complete: Ontology defines `Exam`, `ExamPolicyProfile`, `CalculatorFunction`, `FunctionSet`, `ExamModeSession`, and audit concepts.
  - Complete: Relations and policies match the PRD.
  - Complete: Example SpecGraph requirement resolves all `examcalc:*` semantic refs.

#### ONT-004: Ontology Compiler Prototype
- **Description:** Prototype `ontologyc check` and `ontologyc compile` from YAML to normalized IR and TypeScript SDK artifacts.
- **Priority:** P1
- **Dependencies:** ONT-001, ONT-002
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-004_Ontology_Compiler_Prototype/ONT-004_Ontology_Compiler_Prototype.md`
- **Acceptance Criteria:**
  - Complete: Compiler parses YAML as inert data.
  - Complete: Compiler emits deterministic normalized IR.
  - Complete: Compiler emits `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and validators.

---

## Phase 3: SpecGraph Integration

#### ONT-005: SpecGraph Semantic Reference Validation
- **Description:** Specify and/or prototype validation for `OntologyImport`, lockfiles, `ConceptRef`, `SemanticBinding`, and `OntologyGap`.
- **Priority:** P1
- **Dependencies:** ONT-001, ONT-003
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-005_SpecGraph_Semantic_Reference_Validation/ONT-005_SpecGraph_Semantic_Reference_Validation.md`
- **Acceptance Criteria:**
  - Complete: Known ontology refs resolve to canonical URIs.
  - Complete: Missing refs create `OntologyGap`.
  - Complete: Compatibility reports classify breaking ontology changes.

---

## Phase 4: Code Quality and Maintainability

#### ONT-006: SpecificationCore Baseline and Regression Harness
- **Description:** Add the first behavior-preserving ONT-006 implementation slice: Swift regression tests for current `ontologyc` behavior plus the pinned `SpecificationCore` dependency and `OntologyRules` target scaffold.
- **Priority:** P1
- **Dependencies:** ONT-004, ONT-005
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/ONT-006_SpecificationCore_Baseline_and_Regression_Harness.md`
- **Acceptance Criteria:**
  - Complete: Swift regression tests cover current `check`, `compile`, `validate-specgraph`, and `diff` behavior.
  - Complete: Valid and invalid fixture behavior is locked before production refactoring.
  - Complete: Generated IR, TypeScript artifacts, SpecGraph validation outputs, and compatibility report hashes are recorded and verified.
  - Complete: `SpecificationCore` 1.0.0 is added as a pinned SwiftPM dependency.
  - Complete: `OntologyRules` target builds and imports `SpecificationCore`.
  - Complete: No production compiler behavior changes are introduced.
  - Complete: New implementation and tests are Swift-native; no Ruby tooling is introduced.

#### ONT-007: `ontologyc` Compiler Module Split
- **Description:** Split the current monolithic Swift compiler implementation into a thin CLI executable and an importable `OntologyCompiler` target with focused compiler phase files.
- **Priority:** P1
- **Dependencies:** ONT-006
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-007_ontologyc_Compiler_Module_Split/ONT-007_ontologyc_Compiler_Module_Split.md`
- **Acceptance Criteria:**
  - Complete: `Sources/OntologyC/main.swift` becomes a thin CLI entry point.
  - Complete: `OntologyCompiler` contains diagnostics, IO, package loading, validation, normalization, TypeScript emission, SpecGraph validation, and compatibility diff code in focused files.
  - Complete: Public CLI commands and output strings remain unchanged.
  - Complete: Baseline regression tests and generated output hashes remain stable.
  - Complete: No ontology validation semantics change.

#### ONT-008: OntologyRules Specification Extraction
- **Description:** Move current validation predicates into named `SpecificationCore` specifications for package shape, metadata, references, security, relations, policies, and state machines.
- **Priority:** P1
- **Dependencies:** ONT-007
- **Parallelizable:** no
- **Status:** Not Started
- **PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`
- **Acceptance Criteria:**
  - Metadata and package-shape predicates are represented as named Swift specifications.
  - Concept reference syntax and local/imported reference checks are represented as named Swift specifications.
  - Unsafe YAML key/value/tag checks are represented as named Swift specifications.
  - Relation, policy, and state-machine predicates are represented as named Swift specifications.
  - `OntologyRulesTests` cover each extracted specification cluster.
  - Baseline regression tests and generated output hashes remain stable.

#### ONT-009: Ontology DecisionSpec Migration
- **Description:** Move classification logic into typed `SpecificationCore` decision specs for relation range shape, concept ref resolution, SpecGraph resolved/gap classification, compatibility changes, and CLI command classification where useful.
- **Priority:** P1
- **Dependencies:** ONT-008
- **Parallelizable:** no
- **Status:** Not Started
- **PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`
- **Acceptance Criteria:**
  - Relation range classification uses a typed decision spec.
  - Concept reference resolution uses a typed decision spec.
  - SpecGraph reference validation uses typed resolved-vs-gap decisions.
  - Compatibility diff uses typed compatible-vs-breaking decisions.
  - Decision tests cover all migrated branches.
  - Baseline regression tests and generated output hashes remain stable.

#### ONT-010: Specification-Driven Refactor Documentation and Audit
- **Description:** Finalize documentation, validation reporting, and quality gates for the SpecificationCore-based `ontologyc` refactor.
- **Priority:** P1
- **Dependencies:** ONT-009
- **Parallelizable:** no
- **Status:** Not Started
- **PRD:** `SPECS/INPROGRESS/ONT-006_Specification_Driven_OntologyC_Refactor.md`
- **Acceptance Criteria:**
  - `SPECS/ontology/ontologyc.md` documents the new module boundaries and `SpecificationCore` dependency decision.
  - `SPECS/INPROGRESS/ONT-006_Validation_Report.md` records build, tests, CLI checks, hashes, dependency/license audit, and residual risks.
  - Final no-diff and generated output hash checks pass.
  - Audit confirms no new Ruby tooling was introduced.
  - Workplan and archive-ready artifacts are consistent for Flow completion.

---

## Task Status Legend

- **Not Started** — Task defined but not yet begun.
- **INPROGRESS** — Task currently being planned or executed.
- **PRD Ready** — Implementation-ready PRD exists in `SPECS/INPROGRESS/`.
- **Complete** — Task finished and archived.
