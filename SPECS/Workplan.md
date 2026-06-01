# Project Workplan — Ontology

This workplan tracks the specification work for the Ontology repository. The initial source material is preserved in `SPECS/raw/`.

---

## Phase 1: Foundation

#### ONT-001: Ontology Layer and SpecGraph Semantic Import
- **Description:** Define the lower-level Ontology Layer, TypeScript-oriented ontology compiler contract, SpecGraph semantic import/reference artifacts, and the `examcalc` golden ontology example.
- **Priority:** P0
- **Dependencies:** None
- **Parallelizable:** no
- **Status:** INPROGRESS
- **PRD:** `SPECS/INPROGRESS/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import.md`
- **Source:** `SPECS/raw/Агентная_Операционная_Система_-_Branch_SpecGraph_-_Онтологии.json`
- **Acceptance Criteria:**
  - Core artifacts `OntologyImport`, `ConceptRef`, `SemanticBinding`, `OntologyGap`, and `OntologyLockfile` are specified.
  - `DomainOntologyPackage` YAML schema contract is specified.
  - TypeScript foundation model and normalized compiler IR are specified.
  - `ontologyc` validation and compile behavior is specified.
  - `examcalc` ontology example contains required classes, relations, policies, and state machine.
  - SpecGraph examples reference ontology concepts without duplicating domain definitions.
  - Security rule forbids executing ontology YAML.

---

## Phase 2: Implementation Candidates

#### ONT-002: Ontology Package Schema and Fixtures
- **Description:** Implement machine-readable schema files and valid/invalid fixtures for `DomainOntologyPackage`.
- **Priority:** P1
- **Dependencies:** ONT-001
- **Parallelizable:** yes
- **Status:** Not Started
- **Acceptance Criteria:**
  - Schema validates required metadata, classes, relations, policies, and state machines.
  - Invalid fixtures cover missing metadata, invalid inheritance, unknown relation refs, and unsafe executable-looking YAML.

#### ONT-003: `examcalc` Golden Ontology Package
- **Description:** Materialize the exam-controlled calculator ontology package from the PRD.
- **Priority:** P1
- **Dependencies:** ONT-001
- **Parallelizable:** yes
- **Status:** Not Started
- **Acceptance Criteria:**
  - Ontology defines `Exam`, `ExamPolicyProfile`, `CalculatorFunction`, `FunctionSet`, `ExamModeSession`, and audit concepts.
  - Relations and policies match the PRD.
  - Example SpecGraph requirement resolves all `examcalc:*` semantic refs.

#### ONT-004: Ontology Compiler Prototype
- **Description:** Prototype `ontologyc check` and `ontologyc compile` from YAML to normalized IR and TypeScript SDK artifacts.
- **Priority:** P1
- **Dependencies:** ONT-001, ONT-002
- **Parallelizable:** no
- **Status:** Not Started
- **Acceptance Criteria:**
  - Compiler parses YAML as inert data.
  - Compiler emits deterministic normalized IR.
  - Compiler emits `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and validators.

---

## Phase 3: SpecGraph Integration

#### ONT-005: SpecGraph Semantic Reference Validation
- **Description:** Specify and/or prototype validation for `OntologyImport`, lockfiles, `ConceptRef`, `SemanticBinding`, and `OntologyGap`.
- **Priority:** P1
- **Dependencies:** ONT-001, ONT-003
- **Parallelizable:** yes
- **Status:** Not Started
- **Acceptance Criteria:**
  - Known ontology refs resolve to canonical URIs.
  - Missing refs create `OntologyGap`.
  - Compatibility reports classify breaking ontology changes.

---

## Task Status Legend

- **Not Started** — Task defined but not yet begun.
- **INPROGRESS** — Task currently being planned or executed.
- **PRD Ready** — Implementation-ready PRD exists in `SPECS/INPROGRESS/`.
- **Complete** — Task finished and archived.
