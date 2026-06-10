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
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-008_OntologyRules_Specification_Extraction/ONT-008_OntologyRules_Specification_Extraction.md`
- **Acceptance Criteria:**
  - Complete: Metadata and package-shape predicates are represented as named Swift specifications.
  - Complete: Concept reference syntax and local/imported reference checks are represented as named Swift specifications.
  - Complete: Unsafe YAML key/value/tag checks are represented as named Swift specifications.
  - Complete: Relation, policy, and state-machine predicates are represented as named Swift specifications.
  - Complete: `OntologyRulesTests` cover each extracted specification cluster.
  - Complete: Baseline regression tests and generated output hashes remain stable.

#### ONT-009: Ontology DecisionSpec Migration
- **Description:** Move classification logic into typed `SpecificationCore` decision specs for relation range shape, concept ref resolution, SpecGraph resolved/gap classification, compatibility changes, and CLI command classification where useful.
- **Priority:** P1
- **Dependencies:** ONT-008
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-009_Ontology_DecisionSpec_Migration/ONT-009_Ontology_DecisionSpec_Migration.md`
- **Acceptance Criteria:**
  - Complete: Relation range classification uses a typed decision spec.
  - Complete: Concept reference resolution uses a typed decision spec.
  - Complete: SpecGraph reference validation uses typed resolved-vs-gap decisions.
  - Complete: Compatibility diff uses typed compatible-vs-breaking decisions.
  - Complete: Decision tests cover all migrated branches.
  - Complete: Baseline regression tests and generated output hashes remain stable.

#### ONT-010: Specification-Driven Refactor Documentation and Audit
- **Description:** Finalize documentation, validation reporting, and quality gates for the SpecificationCore-based `ontologyc` refactor.
- **Priority:** P1
- **Dependencies:** ONT-009
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-010_Specification_Driven_Refactor_Documentation_And_Audit/ONT-010_Specification_Driven_Refactor_Documentation_And_Audit.md`
- **Acceptance Criteria:**
  - Complete: `SPECS/ontology/ontologyc.md` documents the new module boundaries and `SpecificationCore` dependency decision.
  - Complete: `SPECS/ARCHIVE/ONT-010_Specification_Driven_Refactor_Documentation_And_Audit/ONT-010_Validation_Report.md` records build, tests, CLI checks, hashes, dependency audit, and residual risks.
  - Complete: Final no-diff and generated output hash checks pass.
  - Complete: Audit confirms no new Ruby tooling was introduced.
  - Complete: Workplan and archive-ready artifacts are consistent for Flow completion.

---

## Phase 5: Polish and Hardening

> Tasks in this phase were derived from the post-implementation code review on PR #13
> (Add Swift quality gates). They are backlog items; none block the completed ONT-001..010 slice.

#### ONT-011: Repository README and Contributor Guide
- **Description:** Replace the stub root `README.md` with real project documentation: what the Ontology layer and `ontologyc` are, how to build and run the CLI, how to run the local quality gate, and links into `SPECS/ontology/`.
- **Priority:** P2
- **Dependencies:** ONT-010
- **Parallelizable:** yes
- **Status:** Complete
- **Origin:** Post-implementation code review (PR #13).
- **Implementation Note:** Updated root README and contributor guidance to document the
  Ontology/SpecGraph layer boundary, examcalc CLI walkthrough, local/CI quality gate,
  SpecificationCore rule ownership, and key ontology spec links.
- **Acceptance Criteria:**
  - Complete: Root `README.md` describes the layer model and the `ontologyc` commands (`check`, `compile`, `validate-specgraph`, `diff`) over the `examcalc` example.
  - Complete: README documents local build/test and `tools/swift-quality.sh` usage (including `RUN_COVERAGE=1`).
  - Complete: README links to the key specs under `SPECS/ontology/` (glossary, core contracts, `ontologyc.md`).

#### ONT-012: Automated Competency-Question Resolution Test (T-009)
- **Description:** Add automated coverage for PRD test T-009: load `SPECS/ontology/examples/examcalc.competency-questions.yaml` and assert every referenced concept/relation/policy resolves against the compiled ontology, and that the missing-concept question emits an `OntologyGap`.
- **Priority:** P1
- **Dependencies:** ONT-003, ONT-006
- **Parallelizable:** yes
- **Status:** Complete
- **Origin:** Post-implementation code review (PR #13).
- **Implementation Note:** Implemented as a Swift regression test that parses the committed
  competency-question YAML, resolves references through the normalized IR index, and asserts
  CQ-005 emits an `OntologyGap`.
- **Acceptance Criteria:**
  - Complete: A Swift test parses the competency-question set and resolves each `examcalc:*` reference through the normalized IR.
  - Complete: CQ-005 (missing `CASFunction`) is asserted to produce an `OntologyGap`, not a silent miss.
  - Complete: The test is wired into the existing regression suite and CI quality gate.

#### ONT-013: Resolve SwiftLint Warnings in OntologyCompiler
- **Description:** Clear the advisory SwiftLint warnings in `OntologyCompiler` and decide whether to enforce them via `--strict`.
- **Priority:** P2
- **Dependencies:** ONT-007
- **Parallelizable:** yes
- **Status:** Complete
- **Origin:** Post-implementation code review (PR #13).
- **Implementation Note:** Fresh ONT-013 audit found SwiftLint clean on current `main`.
  The original force-unwrap/complexity findings had already been resolved by intervening
  refactors; this task locked the remaining contract by switching SwiftLint to strict mode.
- **Acceptance Criteria:**
  - Complete: `force_try`/`force_unwrapping` on the serialization path in `CompilerHelpers.swift` are absent in the current code.
  - Complete: `force_cast`, `force_try`, `force_unwrapping`, and implicitly unwrapped optionals are enforced as SwiftLint errors in local and CI quality gates.
  - Complete: `cyclomatic_complexity`/`function_parameter_count` in `PackageValidation.swift` and `function_body_length` in `Normalization.swift` are below the configured thresholds.
  - Complete: `swiftlint` reports zero warnings and strict mode is enabled so warning regressions fail CI.

#### ONT-014: Harden `ontologyc` CLI Argument Parsing
- **Description:** Make the `ontologyc` CLI robust: support `--help`, flag-order independence, and clear error messages instead of the current fixed-position/fixed-count argument checks in `Sources/OntologyC/main.swift`.
- **Priority:** P2
- **Dependencies:** ONT-007
- **Parallelizable:** yes
- **Status:** Complete
- **Origin:** Post-implementation code review (PR #13).
- **Implementation Note:** Implemented in the ONT-014 CLI help/argument parsing follow-up; archive artifacts are not yet materialized.
- **Acceptance Criteria:**
  - Complete: Each command accepts flags in any order and prints actionable usage on error.
  - Complete: `ontologyc --help` and `ontologyc <command> --help` are supported.
  - Complete: Public command output strings and exit codes relied on by the regression suite remain stable.

#### ONT-015: Ontology Governing-Concept Review
- **Description:** Review `central: true` usage in the `examcalc` package — four concepts (`Exam`, `CalculatorFunction`, `ExamPolicyProfile`, `ExamModeSession`) are currently marked central, diluting the single governing-concept signal the source intended (`ExamPolicyProfile`).
- **Priority:** P3
- **Dependencies:** ONT-003
- **Parallelizable:** yes
- **Status:** Complete
- **Origin:** Post-implementation code review (PR #13).
- **Implementation Note:** `ExamPolicyProfile` is the only governing concept in the
  canonical examcalc ontology, matching the ONT-001 source model. Supporting concepts remain
  ordinary domain concepts.
- **Acceptance Criteria:**
  - Complete: `central: true` is reduced to the governing concept justified by the source:
    `ExamPolicyProfile`.
  - Complete: Regenerated SDK artifacts and regression baselines are updated to match.

---

## Phase 6: Protocol Interfaces and Advanced Validation

#### ONT-016: Protocol Interfaces and Compiler Support
- **Description:** Wire up the `protocols` section and `implements` array that already exist in the YAML schema but are ignored by the compiler. Add validation, normalization, and TypeScript emit so classes can declare conformance to named protocols (e.g. `Signable`, `Auditable`) and the compiler generates corresponding interfaces and intersection types.
- **Priority:** P2
- **Dependencies:** ONT-010
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-016_Protocol_Interfaces_And_Compiler_Support/ONT-016_Protocol_Interfaces_And_Compiler_Support.md`
- **Implementation Note:** Implemented in PR #14; archived on 2026-06-02 during planning-state cleanup.
- **Acceptance Criteria:**
  - Complete: Protocol names validate against `OntologySymbolNameSpec`.
  - Complete: `implements` refs resolve to declared or imported protocols; unresolved refs produce diagnostics.
  - Complete: Classes that implement a protocol are checked for `requiredFields` and `requiredRelations`; violations produce `E_PROTO_FIELD_MISSING` / `E_PROTO_RELATION_MISSING`.
  - Complete: Normalized IR includes a `protocols` array and each class carries `implementedProtocols`.
  - Complete: `protocols.ts` is emitted with one TypeScript interface per protocol.
  - Complete: `types.ts` emits intersection types for conforming classes.
  - Complete: `registry.ts` includes a `protocols` entry.
  - Complete: Packages without protocols produce identical outputs to today.

#### ONT-017: Zod/JSON Schema Validators for ABox Instances
- **Description:** Extend `emitValidators` to generate a `schemas.ts` file with per-class Zod schemas, a discriminated-union `AnyOntologyEntitySchema`, and a `toJsonSchemaFor` utility. Protocol-required fields are injected into conforming class schemas once ONT-016 lands.
- **Priority:** P2
- **Dependencies:** ONT-016
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-017_Zod_JSON_Schema_Validators_For_ABox/ONT-017_Zod_JSON_Schema_Validators_For_ABox.md`
- **Implementation Note:** Implemented across PR #14 and the ONT-017 JSON Schema helper follow-up; archived on 2026-06-02 during planning-state cleanup.
- **Acceptance Criteria:**
  - Complete: `schemas.ts` is emitted alongside existing outputs for every `compile` invocation.
  - Complete: Each class produces a `<ClassName>Schema` Zod object with `$type` literal and optional `id` field.
  - Complete: `AnyOntologyEntitySchema` is a `z.discriminatedUnion` on `$type` covering all classes.
  - Complete: `toJsonSchemaFor` converts any class schema to JSON Schema draft-2020-12.
  - Complete: `validators.ts` exports a `parseOntologyEntity` wrapper; the `_ = ir` no-op is removed.
  - Complete: Protocol `requiredFields` appear in conforming class schemas (conditional on ONT-016).
  - Complete: Regression baselines include the generated `schemas.ts` output.

---

## Phase 7: Registry and Distribution

#### ONT-018: CLI Registry Commands (publish, pull, compat-check)
- **Description:** Add `ontologyc publish`, `ontologyc pull`, and `ontologyc compat-check` commands so authors can distribute packages through a semver registry, download published ontologies, and verify backward compatibility against a live registry version.
- **Priority:** P2
- **Dependencies:** ONT-010, ONT-014
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-018_CLI_Registry_Commands/ONT-018_CLI_Registry_Commands.md`
- **Implementation Note:** Implemented in PR #14; archived on 2026-06-02 during planning-state cleanup.
- **Acceptance Criteria:**
  - Complete: `publish` runs `check` before upload; packages with errors are not published.
  - Complete: `publish` reads the bearer token from `--token` or `ONTOLOGYC_TOKEN`; `--token` takes precedence.
  - Complete: `pull` writes the downloaded IR to `<out>/<id-dashed>-<version>.normalized.json`; `sourceDigest` is treated as the original YAML source digest, not an IR body integrity digest.
  - Complete: `compat-check` exits non-zero on breaking changes, zero on fully compatible diffs.
  - Complete: All registry HTTP operations retry up to 3 times with exponential back-off on transient errors.
  - Complete: Existing commands and regression hashes are unaffected.

---

## Phase 8: Ontology Induction and Authoring

#### ONT-019: SpecGraph Ontology Induction Protocol and Prompt Contracts
- **Description:** Materialize the raw roadmap for turning product/domain intent into validated
  `DomainOntologyPackage` YAML through a staged ontology induction protocol, prompt
  contracts, quality rubric, and golden intent seeds.
- **Priority:** P1
- **Dependencies:** ONT-001, ONT-002, ONT-003, ONT-004, ONT-015
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-019_SpecGraph_Ontology_Induction_Protocol_And_Prompt_Contracts/ONT-019_SpecGraph_Ontology_Induction_Protocol_And_Prompt_Contracts.md`
- **Origin:** `SPECS/raw` roadmap: SpecGraph Ontology Induction Protocol, prompt contracts,
  rubric + validators, golden intent set, and ontology governance.
- **Implementation Note:** Added SG-OIP protocol docs, ontology authoring guide, nine
  stage-specific prompt contracts, quality rubric, golden intent seeds, and README entry
  points. No compiler behavior changed.
- **Acceptance Criteria:**
  - Complete: Protocol doc defines the staged intent-to-ontology pipeline from product intent to
    approved `DomainOntologyPackage`.
  - Complete: Prompt contracts are split by stage and have explicit inputs, outputs, forbidden
    behavior, and quality checks.
  - Complete: Quality rubric defines reviewer criteria for ontology drafts and separates automated
    checks from human/agent review.
  - Complete: Authoring guide explains how the final YAML is checked and compiled with `ontologyc`.
  - Complete: At least two golden intent seeds are included for future stability tests.

---

## Phase 9: Hypercode Bridge

#### ONT-020: Hypercode IR Import Spike
- **Description:** Add the first deterministic bridge from Hypercode resolved graph IR
  (`hypercode.ir/v1`) into a `DomainOntologyPackage` draft. The importer treats Hypercode
  node types as candidate ontology classes and emits review scaffolding, not an approved
  domain ontology.
- **Priority:** P2
- **Dependencies:** ONT-019
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/INPROGRESS/ONT-020_Hypercode_IR_Import_Spike.md`
- **Origin:** Cross-repo Hypercode tooling integration.
- **Implementation Note:** Implemented as a small `ontologyc import-hypercode` spike.
- **Acceptance Criteria:**
  - Complete: CLI accepts `import-hypercode <hypercode-ir.json> --out <draft.yaml> --id <package-id> --namespace <namespace> --version <semver>`.
  - Complete: Importer rejects non-`hypercode.ir/v1` JSON before writing output.
  - Complete: Hypercode node `type` values are deterministically mapped to ontology class names.
  - Complete: Output package is marked `approvalStatus: draft` and includes review policy/lifecycle scaffolding.
  - Complete: Generated draft passes `ontologyc check`.
  - Complete: README documents the command as a draft bridge, not a full ontology induction workflow.

#### ONT-021: Golden Intent Semantic Expectations
- **Description:** Add machine-readable semantic expectation files for the initial golden
  intent seeds so future induction outputs can be compared against minimum expected
  domain semantics without treating one draft as byte-exact truth.
- **Priority:** P1
- **Dependencies:** ONT-019
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-021_Golden_Intent_Semantic_Expectations/ONT-021_Golden_Intent_Semantic_Expectations.md`
- **Origin:** Follow-up to ONT-019 golden intent seeds and raw roadmap stage 4,
  "Golden intent set."
- **Implementation Note:** Added structured minimum semantic expectation files for the
  first two golden intents, plus README and authoring-guide discoverability links.
- **Acceptance Criteria:**
  - Complete: Expectations exist for `exam-controlled-calculator.intent.md` and
    `voice-recorder-ai-transcription.intent.md`.
  - Complete: Each expectation defines expected domain frame, governing concept, minimum concept
    coverage, policy/lifecycle/evidence expectations, competency question expectations,
    and forbidden surface concepts.
  - Complete: Expectations are minimum semantic criteria, not byte-exact ontology outputs.
  - Complete: A README explains how expectation files should be used by future repeatability checks.
  - Complete: Documentation links from ontology authoring docs or README make the expectations
    discoverable.

#### ONT-022: Golden Intent Repeatability Harness
- **Description:** Add a deterministic harness that consumes golden intent semantic expectations
  and evaluates candidate ontology outputs against minimum semantic criteria.
- **Priority:** P1
- **Dependencies:** ONT-021
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-022_Golden_Intent_Repeatability_Harness/ONT-022_Golden_Intent_Repeatability_Harness.md`
- **Origin:** Follow-up to ONT-021 and raw roadmap stage 4, "Golden intent set."
- **Acceptance Criteria:**
  - Complete: Harness accepts a golden intent expectation file and a candidate ontology artifact.
  - Complete: Harness reports pass/fail results for required concepts, relations, policies,
    lifecycle, and forbidden concept checks; competency question expectations are emitted as
    manual review anchors until candidates carry first-class CQ data.
  - Complete: Harness treats expectations as minimum semantic criteria, not byte-exact ontology truth.
  - Complete: Harness output is deterministic and suitable for CI/regression use.

#### ONT-023: Ontology Governance Protocol
- **Description:** Define the approval, rejection, merge, versioning, and audit protocol for
  generated ontology deltas before they become accepted ontology packages.
- **Priority:** P1
- **Dependencies:** ONT-022
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-023_Ontology_Governance_Protocol/ONT-023_Ontology_Governance_Protocol.md`
- **Origin:** Raw roadmap stage 5, "Ontology governance."
- **Acceptance Criteria:**
  - Complete: Protocol defines candidate, approved, rejected, superseded, and merged states.
  - Complete: Protocol defines reviewer inputs, decision records, and provenance requirements.
  - Complete: Protocol explains versioning and compatibility handling for accepted ontology deltas.
  - Complete: Protocol defines how governance results feed back into golden intent expectations.

#### ONT-024: Governance Decision YAML Schema
- **Description:** Define a machine-readable `OntologyGovernanceDecision` YAML schema,
  canonical examples, and documentation so governance decisions become typed artifacts
  instead of free-form Markdown.
- **Priority:** P1
- **Dependencies:** ONT-023
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/ONT-024_Governance_Decision_YAML_Schema.md`
- **Origin:** Follow-up to ONT-023 enforcement boundary and SpecGraph integration proposal work.
- **Implementation Note:** Added a YAML/JSON Schema-compatible governance decision
  contract, valid and invalid examples, and documentation links. Compiler enforcement is
  deferred to ONT-025.
- **Acceptance Criteria:**
  - Complete: Schema defines `apiVersion`, `kind`, metadata, package identity, decision state,
    reviewer identity, rationale, evidence references, and optional digest fields.
  - Complete: Schema constrains approval/rejection actors to human reviewer intent and keeps
    generated agents out of approval authority.
  - Complete: Valid and invalid governance decision examples are included.
  - Complete: Governance protocol, authoring guide, and ontology docs link to the schema and examples.
  - Complete: No compiler enforcement or registry behavior changes are introduced in this task.

#### ONT-025: Governance Decision CLI Validation
- **Description:** Add `ontologyc validate-governance-decision` to validate governance
  decision YAML against the schema contract and related ontology package/golden intent evidence.
- **Priority:** P1
- **Dependencies:** ONT-024
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/ONT-025_Governance_Decision_CLI_Validation.md`
- **Origin:** Follow-up to ONT-024 and the ONT-023 enforcement boundary.
- **Implementation Note:** Added `OntologyCompiler.validateGovernanceDecision` and
  `ontologyc validate-governance-decision` with package/golden-report evidence checks.
  Registry publish enforcement is deferred to ONT-026.
- **Acceptance Criteria:**
  - Complete: CLI accepts a decision YAML path and optional package / golden intent report evidence paths.
  - Complete: Validation rejects invalid `apiVersion`, `kind`, lifecycle state, missing actor,
    missing rationale, malformed evidence, and approval records tied to failing reports.
  - Complete: Validation confirms decision package/version metadata matches the supplied package when provided.
  - Complete: Output is deterministic and suitable for CI.
  - Complete: Unit and CLI regression tests cover pass/fail cases.

#### ONT-026: Registry Publish Governance Gate
- **Description:** Integrate governance decision validation into registry publication so
  trusted package publishing requires an approved governance decision artifact.
- **Priority:** P1
- **Dependencies:** ONT-025
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/ONT-026_Registry_Publish_Governance_Gate.md`
- **Origin:** Follow-up to ONT-025 and the registry distribution workflow.
- **Implementation Note:** Added `--channel candidate|trusted` to `ontologyc publish`.
  Candidate remains default. Trusted publication requires an approved governance decision
  validated against the package and optional golden intent report before any registry
  network call.
- **Acceptance Criteria:**
  - Complete: `ontologyc publish` accepts a governance decision artifact for trusted publication.
  - Complete: Publish rejects missing, non-approved, package-mismatched, version-mismatched, or evidence-failing decisions.
  - Complete: The policy boundary documents that governance is mandatory for trusted publication and optional for candidate publication.
  - Complete: Registry tests cover approval pass/fail behavior without requiring a live external registry.
  - Complete: Existing pull and compat-check behavior remains unchanged.

#### ONT-027: CI SwiftPM And Quality Tool Cache Optimization
- **Description:** Add deterministic CI cache layers for SwiftPM dependencies, DocC
  plugin artifacts, and quality tool installation so repeated PR/main runs avoid
  rebuilding stable system-like dependencies when inputs have not changed.
- **Priority:** P2
- **Dependencies:** ONT-026
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization.md`
- **Origin:** Follow-up to repeated ONT-026 CI runs and prior ISOInspector cache patterns.
- **Implementation Note:** Added cache key and tool installer scripts, restored quality-tool
  and SwiftPM cache layers in CI, made `tools/swift-quality.sh` accept a stable CI scratch
  path, and documented cache invalidation policy.
- **Acceptance Criteria:**
  - Complete: CI restores SwiftPM dependency/build caches using keys tied to Swift version,
    package resolution, and quality configuration.
  - Complete: SwiftFormat/SwiftLint installation avoids repeated Homebrew work when cached
    binaries are available.
  - Complete: DocC workflow restores package/plugin caches before documentation generation.
  - Complete: Cache misses remain safe and fall back to ordinary installation/build behavior.
  - Complete: The cache policy is documented with invalidation boundaries and residual risk.

#### ONT-028: Node24 Cache Action Migration
- **Description:** Replace Node20-targeting GitHub cache action usage with the Node24
  cache action release so CI no longer relies on runtime-forcing compatibility warnings.
- **Priority:** P2
- **Dependencies:** ONT-027
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/ONT-028_Node24_Cache_Action_Migration.md`
- **Origin:** Follow-up to ONT-027 post-merge CI annotations from `actions/cache@v4`.
- **Acceptance Criteria:**
  - Complete: Swift Quality cache steps use a Node24-native cache action release.
  - Complete: DocC cache steps use a Node24-native cache action release.
  - Complete: Temporary Node24 force environment variables are removed when no longer needed.
  - Complete: CI cache policy documents the Node24 action requirement.
  - Complete: Local workflow syntax/key generation checks pass; PR CI remains required before merge.

#### ONT-029: Agent Model Selection Guidance
- **Description:** Document how ontology-authoring agents should choose models by role,
  risk, and validation results instead of always defaulting to the strongest or most
  expensive available model.
- **Priority:** P2
- **Dependencies:** ONT-019, ONT-021, ONT-023
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/ONT-029_Agent_Model_Selection_Guidance.md`
- **Origin:** Empirical prompt runs showed small quality deltas between stronger and
  cheaper models on ontology-authoring prompts when judged against benchmark outputs.
- **Acceptance Criteria:**
  - Complete: Authoring guide gives role-level model selection guidance.
  - Complete: Induction protocol states that validation artifacts are normative, model
    choice is operational.
  - Complete: Quality rubric distinguishes semantic quality from model cost/latency.
  - Complete: README points authors to role-specific model selection.
  - Complete: No compiler behavior changes are introduced.

---

## Phase 10: SpecGraph Value Loop Closure

> Tasks in this phase are derived from the post-ONT-029 repository review and the
> SpecGraph integration follow-up discussion. The phase priority is to close the
> live loop: intent -> induction artifacts -> `DomainOntologyPackage` ->
> `ontologyc` validation/compile -> generated SDK/IR -> SpecGraph semantic refs ->
> lockfile/gaps -> governance -> publish/pull.

#### ONT-030: TypeScript SDK Smoke Gate
- **Description:** Add a local and CI quality gate that compiles the generated examcalc
  TypeScript SDK with `tsc --noEmit` and exercises the generated Zod schemas through a
  minimal smoke fixture.
- **Priority:** P0
- **Dependencies:** ONT-017, ONT-028
- **Parallelizable:** no
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-030_TypeScript_SDK_Smoke_Gate/ONT-030_TypeScript_SDK_Smoke_Gate.md`
- **Origin:** Post-ONT-029 review finding that generated TypeScript artifacts are snapshot-locked
  but not checked by the TypeScript compiler.
- **Implementation Note:** Added a lockfile-backed TypeScript smoke package at
  `SPECS/ontology`, local helper,
  CI workflow step, Node24 action guard coverage, and documentation. The gate runs
  `tsc --noEmit` plus a runtime Zod smoke fixture against the generated examcalc SDK.
- **Acceptance Criteria:**
  - Complete: `SPECS/ontology` has a minimal package setup and `typescript-smoke/`
    has a fixture that imports the committed generated examcalc SDK.
  - Complete: A local script or documented command runs `tsc --noEmit` against the generated SDK and smoke fixture.
  - Complete: The smoke fixture parses at least one class schema and calls `toJsonSchemaFor`.
  - Complete: CI runs the TypeScript smoke gate before any class-field emitter expansion.
  - Complete: Swift quality gates remain unchanged and green.

#### ONT-031: SpecGraph Ontology Integration Process PRD
- **Description:** Define the minimal implementation process for SpecGraph consuming Ontology
  artifacts without redefining ontology semantics locally.
- **Priority:** P0
- **Dependencies:** ONT-005, ONT-019, ONT-026, ONT-030
- **Parallelizable:** yes
- **Status:** Complete
- **PRD:** `SPECS/ARCHIVE/ONT-031_SpecGraph_Ontology_Integration_Process_PRD/ONT-031_SpecGraph_Ontology_Integration_Process_PRD.md`
- **Origin:** SpecGraph integration discussion and SpecGraph proposal 0060 external ontology
  import plane.
- **Acceptance Criteria:**
  - Complete: PRD describes the bridge workflow: ontology import -> lockfile -> semantic refs ->
    `ConceptRef`/`OntologyGap` outputs -> delta request -> governance evidence -> publish/pull.
  - Complete: PRD identifies which artifacts are owned by Ontology and which are owned by SpecGraph.
  - Complete: PRD includes one concrete examcalc-style requirement/binding example.
  - Complete: PRD defines the minimum acceptance criteria for a future SpecGraph-side smoke slice.
  - Complete: PRD explicitly prevents SpecGraph from copying or redefining `DomainOntologyPackage` semantics.

#### ONT-032: Class Field Semantics And Rich SDK Generation
- **Description:** Add first-class class field semantics to `DomainOntologyPackage` and project
  them into normalized IR, generated TypeScript interfaces, generated Zod schemas, JSON Schema,
  and compatibility reports.
- **Priority:** P0
- **Dependencies:** ONT-030, ONT-031
- **Parallelizable:** no
- **Status:** Not Started
- **Origin:** Post-ONT-029 review finding that the generated SDK currently carries semantic refs
  and protocol-required fields but no first-class per-class data fields.
- **Acceptance Criteria:**
  - `domain-ontology-package.schema.yaml` accepts a constrained `fields` section for classes.
  - Compiler validation rejects unsupported field types, invalid field names, and invalid required/optional declarations.
  - Normalized IR includes deterministic field metadata.
  - `types.ts` and `schemas.ts` project fields into generated TypeScript/Zod outputs.
  - Compatibility diff classifies field additions/removals/type changes according to documented semver rules.
  - The TypeScript smoke gate from ONT-030 covers field-bearing generated output.

#### ONT-033: File And Git Registry Transport
- **Description:** Add a filesystem/git-backed registry transport for `publish`, `pull`, and
  `compat-check` so the registry loop can be dogfooded without an HTTP service.
- **Priority:** P1
- **Dependencies:** ONT-018, ONT-026, ONT-031
- **Parallelizable:** yes
- **Status:** Not Started
- **Origin:** Post-ONT-029 review recommendation to close the registry loop before building a
  reference HTTP registry server.
- **Acceptance Criteria:**
  - `ontologyc publish` can materialize candidate/trusted packages into a local registry directory.
  - `ontologyc pull` can resolve packages from the local registry directory using the same package reference model.
  - `ontologyc compat-check` works against the local registry transport.
  - Trusted publication keeps the existing governance decision gate.
  - Documentation explains how to use a git repository as the reviewable registry backing store.

#### ONT-034: Induction Artifact Schemas And Draft Validation
- **Description:** Add machine-readable schemas and validation for the core intermediate
  ontology-induction artifacts produced before final `DomainOntologyPackage` YAML assembly.
- **Priority:** P1
- **Dependencies:** ONT-019, ONT-021, ONT-022, ONT-031
- **Parallelizable:** yes
- **Status:** Not Started
- **Origin:** Post-ONT-029 review finding that prompt-contract outputs are described in Markdown
  but not validated as deterministic artifacts.
- **Acceptance Criteria:**
  - Schemas exist for the first minimal artifact set: `IntentClassification`,
    `ProductOntologyDraft`, `DraftCritique`, and `DomainOntologyPackageDraft`.
  - Valid and invalid fixtures cover required fields, uncertainty/provenance fields, and unsupported schema drift.
  - `ontologyc validate-draft` validates the artifact set without approving ontology truth.
  - The validation report is deterministic and suitable for CI.
  - Authoring docs explain that final trust still comes from compiler validation and governance.

#### ONT-035: SpecGraph Proposal 0060 Minimal Consumer Slice
- **Description:** Coordinate the first SpecGraph-side implementation slice for proposal 0060:
  one requirement or binding imports an Ontology package through a lockfile, resolves known
  refs, and reports a gap for one unresolved ref.
- **Priority:** P1
- **Dependencies:** ONT-031, ONT-033
- **Parallelizable:** no
- **Status:** Not Started
- **Origin:** SpecGraph proposal `0060_external_ontology_import_plane.md` and the Ontology
  value-loop closure review.
- **Acceptance Criteria:**
  - SpecGraph-side work consumes Ontology-generated IR or registry materialization instead of
    duplicating Ontology package semantics.
  - A minimal requirement/binding fixture resolves at least one known examcalc concept.
  - A missing concept produces an explicit gap artifact instead of a local pseudo-concept.
  - The slice records the imported ontology version and digest/lock metadata.
  - Ontology docs link to the SpecGraph-side consumer slice once it exists.

---

## Task Status Legend

- **Not Started** — Task defined but not yet begun.
- **INPROGRESS** — Task currently being planned or executed.
- **PRD Ready** — Implementation-ready PRD exists in `SPECS/INPROGRESS/`.
- **Complete** — Task finished and archived.
