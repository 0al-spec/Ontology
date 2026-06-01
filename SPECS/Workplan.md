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
