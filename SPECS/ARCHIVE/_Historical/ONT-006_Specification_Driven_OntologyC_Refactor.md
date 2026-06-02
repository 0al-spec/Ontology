# PRD: ONT-006 - Specification-Driven `ontologyc` Refactor

**Status:** Superseded historical draft
**Priority:** P1  
**Phase:** Code Quality and Maintainability  
**Reasoning Effort:** high  
**Dependencies:** ONT-004, ONT-005  
**Source Inputs:**
- `SPECS/Workplan.md`
- `SPECS/ontology/ontologyc.md`
- `SPECS/ontology/compiler-ir.md`
- `SPECS/ontology/domain-ontology-package.schema.yaml`
- `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`
- `SPECS/ontology/packages/examcalc/generated/ontology.normalized.json`
- `SPECS/specgraph/semantic-validation/*.yaml`
- `Sources/OntologyC/main.swift`
- `/Users/egor/Development/GitHub/0AL/Hyperprompt/Sources/HypercodeGrammar/`
- `/Users/egor/Development/GitHub/0AL/Hyperprompt/Sources/EditorEngine/*DecisionSpecs.swift`
- `/Users/egor/Development/GitHub/0AL/Hyperprompt/Tests/HypercodeGrammarTests/`

## TL;DR

Refactor the Swift `ontologyc` prototype into a specification-driven compiler structure using the same `SpecificationCore` dependency pattern already proven in Hyperprompt. The refactor must preserve current behavior exactly: no validation rule changes, no generated artifact shape changes, no diagnostic semantic changes, and no Ruby in new test or validation paths.

## Conceptual Checklist

- Lock current `ontologyc` behavior with regression tests before production refactoring.
- Split the executable into a thin CLI target and importable compiler/rules targets.
- Add `SpecificationCore` as the shared rules engine for ontology validation rules.
- Move validation predicates into named, independently tested specs.
- Move classification logic into typed decision specs.
- Preserve byte-for-byte generated outputs and deterministic validation artifacts.
- Keep all new implementation and tests Swift-native.

## Objective

Improve the maintainability, testability, and reviewability of `ontologyc` without changing its functional behavior.

The current compiler is concentrated in one Swift file, `Sources/OntologyC/main.swift`, which mixes CLI parsing, YAML loading, security scanning, validation, normalization, TypeScript emission, SpecGraph reference validation, and compatibility diffing. This PRD defines a behavior-preserving refactor that separates these concerns and introduces a specification-driven rules layer inspired by Hyperprompt.

## Architectural Decision

Use `SpecificationCore` directly for ONT-006 instead of creating a local clone of the pattern.

```swift
import SpecificationCore
```

Rationale:

- Hyperprompt demonstrates the desired architecture using `SpecificationCore`.
- Ontology should participate in the same 0AL dependency stack instead of maintaining a local pattern clone.
- Successful use in `ontologyc` promotes `SpecificationCore` as a reusable foundation for specification-driven tools.
- The additional SwiftPM surface, including macro-related `swift-syntax` dependencies, is accepted for ecosystem consistency.
- ONT-006 must use the existing stable primitives only: `Specification`, `DecisionSpec`, `PredicateSpec`, `AnySpecification`, and `FirstMatchSpec`.
- ONT-006 must not modify `SpecificationCore` itself.

Dependency target:

```swift
.package(url: "https://github.com/SoundBlaster/SpecificationCore", from: "1.0.0")
```

Reference pin from Hyperprompt:

```text
SpecificationCore 1.0.0
revision af5b0642282541ae36baffd1328a5dd7c5e61146
```

## Scope

### In Scope

- Add Swift regression coverage for current `ontologyc` behavior.
- Add importable Swift targets for compiler core and ontology rules.
- Add `SpecificationCore` as a SwiftPM dependency.
- Keep `ontologyc` executable as the public CLI.
- Move logic out of `main.swift` into focused Swift files and modules.
- Use `SpecificationCore` primitives for specifications and decisions.
- Implement named specs for:
  - package shape;
  - metadata patterns;
  - concept reference syntax;
  - local/imported reference resolution;
  - unsafe YAML key/value detection;
  - relation range shape;
  - policy enforceability;
  - state machine state and trigger checks.
- Implement decision specs for:
  - relation range classification;
  - concept ref resolution;
  - SpecGraph gap vs resolved ref classification;
  - compatibility change classification.
- Preserve current generated `examcalc` IR, TypeScript artifacts, SpecGraph validation outputs, and compatibility report.

### Out of Scope

- Changing ontology validation semantics.
- Changing diagnostic codes or messages unless required only by file/module names in stack traces.
- Changing generated TypeScript API shape.
- Changing normalized IR schema.
- Adding registry/network resolution.
- Adding Rust implementation in parallel.
- Adding Ruby validators, Ruby test harnesses, or Ruby-based tooling.
- Full replacement of `JSONObject = [String: Any]` with Codable models.
- Modifying, forking, or extending `SpecificationCore`.
- Introducing `SpecificationCore` macros into ontology rules.

## Current Baseline

The following behavior is the compatibility baseline for this refactor.

### Build

```bash
swift build
```

Expected result:

```text
Build complete
```

### Core Checks

```bash
.build/debug/ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Expected output:

```text
ontologyc check: PASS SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Each invalid fixture must exit with code `1`:

```text
SPECS/ontology/fixtures/invalid/invalid-inheritance.yaml
SPECS/ontology/fixtures/invalid/missing-metadata.yaml
SPECS/ontology/fixtures/invalid/unknown-relation-ref.yaml
SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml
```

### SpecGraph Validation

```bash
.build/debug/ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/ontologyc-prd-baseline-valid
```

Expected output:

```text
ontologyc validate-specgraph: PASS SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml resolved=25 gaps=0
```

```bash
.build/debug/ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/ontologyc-prd-baseline-missing
```

Expected output:

```text
ontologyc validate-specgraph: PASS SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml resolved=2 gaps=1
```

### Compatibility Diff

```bash
.build/debug/ontologyc diff \
  --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml \
  --out /tmp/ontologyc-prd-baseline-compatibility.yaml
```

Expected output:

```text
ontologyc diff: PASS /tmp/ontologyc-prd-baseline-compatibility.yaml
```

### Baseline Hashes

```text
bb626c69bb0989ab6e7e5605e0dde73dee9e220b6b203d584924e22a6e20936d  SPECS/ontology/packages/examcalc/generated/ontology.normalized.json
7d829d13f9a530c84a847fd19dfff7a336f1e50e4a0f8d239279f9a39aa4807c  SPECS/specgraph/semantic-validation/out/valid/concept-refs.yaml
f048a385f216eb32e5e35e3b6c4b399148eafd227b5ee8533a6b7d70a22c2b1b  SPECS/specgraph/semantic-validation/out/missing/ontology-gaps.yaml
0e545b2d6f7ce398c43b6154692abe7fb2c8f6ac16b4cb84e719a346da7f7216  SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

Combined generated output hash:

```text
1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19
```

## Target Architecture

### Swift Package Targets

```text
Ontology
├── OntologyC              executable, CLI only
├── OntologyCompiler       compiler orchestration and emitters
└── OntologyRules          specification and decision rules; depends on SpecificationCore
```

### Source Layout

```text
Sources/OntologyC/
  main.swift
  CLI.swift

Sources/OntologyCompiler/
  Diagnostics.swift
  OntologyCompiler.swift
  PackageLoading.swift
  PackageValidation.swift
  Normalization.swift
  TypeScriptEmitter.swift
  SpecGraphValidation.swift
  CompatibilityDiff.swift
  JSONYAMLIO.swift

Sources/OntologyRules/
  DomainTypes.swift
  PackageShapeSpecs.swift
  MetadataSpecs.swift
  ReferenceSpecs.swift
  SecuritySpecs.swift
  RelationSpecs.swift
  PolicySpecs.swift
  StateMachineSpecs.swift
  SpecGraphDecisionSpecs.swift
  CompatibilityDecisionSpecs.swift
```

### Test Layout

```text
Tests/OntologyCompilerTests/
  OntologyCRegressionTests.swift
  PackageValidationTests.swift
  SpecGraphValidationTests.swift
  CompatibilityDiffTests.swift
  GeneratedOutputDeterminismTests.swift

Tests/OntologyRulesTests/
  MetadataSpecsTests.swift
  ReferenceSpecsTests.swift
  SecuritySpecsTests.swift
  RelationSpecsTests.swift
  PolicySpecsTests.swift
  StateMachineSpecsTests.swift
  SpecGraphDecisionSpecsTests.swift
  CompatibilityDecisionSpecsTests.swift
```

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Regression test suite | `Tests/OntologyCompilerTests/` | Current valid, invalid, compile, validate-specgraph, and diff behavior is covered |
| D2 | Thin CLI target | `Sources/OntologyC/` | CLI parsing delegates to compiler APIs; command outputs remain unchanged |
| D3 | Compiler core target | `Sources/OntologyCompiler/` | Existing compiler phases are importable and covered by tests |
| D4 | Specification rules target | `Sources/OntologyRules/` | Named specs and decisions use `SpecificationCore` and cover existing validation predicates |
| D5 | Package manifest update | `Package.swift`, `Package.resolved` | Adds `SpecificationCore` 1.0.0 and SwiftPM builds all targets and tests without Ruby |
| D6 | Updated compiler docs | `SPECS/ontology/ontologyc.md` | Documents module boundaries and behavior-preserving refactor policy |
| D7 | Validation report | Historical draft path, superseded by archived ONT-006 artifacts | Records commands, hashes, changed files, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | The public `ontologyc` CLI MUST preserve all existing commands. | `check`, `compile`, `validate-specgraph`, and `diff` still work with identical argument forms. | CLI regression tests |
| FR-002 | The refactor MUST preserve valid package behavior. | `examcalc` package check exits `0` with the same PASS line. | `ontologyc check` test |
| FR-003 | The refactor MUST preserve invalid fixture behavior. | All ONT-002 invalid fixtures exit non-zero. | Invalid fixture tests |
| FR-004 | The refactor MUST preserve generated IR and TypeScript output. | Re-running compile produces no git diff and baseline IR hash remains unchanged. | Determinism test |
| FR-005 | SpecGraph validation MUST preserve resolved/gap counts. | Valid fixture remains `resolved=25 gaps=0`; missing fixture remains `resolved=2 gaps=1`. | SpecGraph tests |
| FR-006 | Compatibility diff MUST preserve breaking-change classification. | Breaking fixture remains incompatible and contains `change relation range examcalc:allows`. | Diff test |
| FR-007 | Validation predicates MUST be represented as named specifications. | Metadata, refs, security, relation, policy, and state machine predicates have dedicated specs. | Rules tests and code review |
| FR-008 | Classification branches MUST be represented as decision specs where they return domain outcomes. | Relation range, ref resolution, gap resolution, and compatibility classification use decision specs. | Decision tests and code review |
| FR-009 | New test and validation tooling MUST be Swift-native. | No new `.rb` files or Ruby commands are introduced. | `rg -n "ruby|\\.rb" <changed files>` |
| FR-010 | Ontology rules MUST use `SpecificationCore` primitives. | `OntologyRules` imports `SpecificationCore`; no local `Specification` or `DecisionSpec` clone is introduced. | Code review and `rg -n "protocol Specification|protocol DecisionSpec" Sources/OntologyRules` |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Behavior preservation | Refactor must not alter observable behavior. | Baseline commands, exit codes, counts, generated hashes, and no-diff checks pass |
| Maintainability | No production file should concentrate unrelated phases after refactor. | `main.swift` is CLI-only; compiler phases live in focused files |
| Testability | Rules and decisions must be independently testable. | `OntologyRulesTests` cover atomic specs and composite decisions |
| Security | YAML remains untrusted inert data. | No eval, shell execution, dynamic import, or generated code execution is added |
| Reproducibility | Output order remains deterministic. | Generated artifact tree hash remains stable |
| Dependency strategy | Use the shared 0AL specification stack. | `SpecificationCore` 1.0.0 is added and pinned through SwiftPM resolution |
| Language policy | Use Swift for compiler and test implementation. | No Ruby growth; Rust is not required for ONT-006 |
| License safety | New dependency must be permissively licensed. | `SpecificationCore` is MIT-licensed; validation report records license check |

## Specification Candidates

### Metadata and Package Shape

| Spec | Candidate | Existing Logic To Preserve |
|---|---|---|
| `HasExpectedApiVersionSpec` | package root | `apiVersion == ontology.specgraph.io/v1alpha1` |
| `HasExpectedKindSpec` | package root | `kind == DomainOntologyPackage` |
| `HasRequiredMetadataSpec` | package root | `metadata` object exists |
| `HasRequiredSpecObjectSpec` | package root | `spec` object exists |
| `MatchesOntologyIdPatternSpec` | string | current `idPattern` |
| `MatchesNamespacePatternSpec` | string | current `namespacePattern` |
| `MatchesSemVerPatternSpec` | string | current `versionPattern` |

### References

| Spec | Candidate | Existing Logic To Preserve |
|---|---|---|
| `MatchesConceptRefPatternSpec` | string | current `conceptPattern` |
| `IsImportedConceptRefSpec` | ref context | namespace exists in imports |
| `IsLocalConceptRefSpec` | ref context | local name exists in package namespace |
| `ResolvableConceptRefSpec` | ref context | imported OR local |
| `IsLocalTriggerRefSpec` | trigger context | command/event trigger resolves locally |

### Security

| Spec | Candidate | Existing Logic To Preserve |
|---|---|---|
| `HasUnsafeYamlTagSpec` | source line | current unsafe tag regex |
| `HasExecutableLookingValueSpec` | string | current unsafe value patterns |
| `HasUnsafeYamlKeySpec` | key | current unsafe key set |
| `SafeYamlSourceSpec` | source text | no unsafe tags or executable-looking line content |
| `SafeYamlNodeSpec` | parsed YAML node | no unsafe keys or executable-looking strings |

### Relation, Policy, and State Machine

| Spec | Candidate | Existing Logic To Preserve |
|---|---|---|
| `IsScalarRelationRangeSpec` | YAML value | string range |
| `IsOneOfRelationRangeSpec` | YAML object | `oneOf` list |
| `AllowedPolicyEnforceabilitySpec` | string | `design`, `runtime`, `manual`, `audit` |
| `MatchesStateNamePatternSpec` | string | current `statePattern` |
| `StateExistsInMachineSpec` | transition context | transition state is declared |
| `TransitionTriggerResolvesSpec` | transition context | command/event trigger resolves |

## Decision Spec Candidates

| Decision Spec | Context | Result |
|---|---|---|
| `RelationRangeShapeDecisionSpec` | raw relation `range` value | `.scalarRef`, `.oneOfRefs`, `.invalid` |
| `ConceptRefResolutionDecisionSpec` | ref plus local/import namespace context | `.local`, `.imported`, `.unresolved`, `.invalidSyntax` |
| `SpecGraphRefDecisionSpec` | semantic ref plus ontology index | `.resolved(ConceptRef)`, `.gap(OntologyGap)` |
| `CompatibilityChangeDecisionSpec` | before/after IR item pair | `.compatible`, `.breaking(reason)` |
| `CommandLineDecisionSpec` | CLI args | `.check`, `.compile`, `.validateSpecGraph`, `.diff`, `.usageError` |

## Implementation Roadmap

### Phase 1 - Baseline Regression Coverage

- Add Swift tests or Swift test helpers that exercise the current CLI behavior.
- Cover valid package check.
- Cover all invalid fixtures.
- Cover compile output presence and deterministic hash.
- Cover SpecGraph valid and missing-ref counts.
- Cover compatibility diff.

Validation:

```bash
swift build
swift test
```

Success metric: tests pass before any production refactor.

### Phase 2 - Mechanical Target Split

- Add `OntologyCompiler` target.
- Move compiler implementation from `Sources/OntologyC/main.swift` into focused files.
- Keep `OntologyC` executable as a thin command dispatcher.
- Preserve command outputs and exit code behavior.

Validation:

```bash
swift build
swift test
.build/debug/ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Success metric: generated files and command outputs match baseline.

### Phase 3 - SpecificationCore Rules Layer

- Add `OntologyRules` target.
- Add `SpecificationCore` dependency to `Package.swift`.
- Import `SpecificationCore` in `OntologyRules`.
- Use `SpecificationCore.Specification`, `AnySpecification`, `DecisionSpec`, `PredicateSpec`, and `FirstMatchSpec`.
- Add atomic specs for metadata, references, security, relations, policies, and state machines.
- Add tests for each atomic spec.

Validation:

```bash
swift test --filter OntologyRulesTests
```

Success metric: each extracted predicate has direct tests and the compiler still passes baseline checks.

### Phase 4 - Decision Spec Migration

- Migrate relation range parsing into `RelationRangeShapeDecisionSpec`.
- Migrate concept ref resolution into `ConceptRefResolutionDecisionSpec`.
- Migrate SpecGraph resolved/gap classification into `SpecGraphRefDecisionSpec`.
- Migrate compatibility breaking-change classification into `CompatibilityChangeDecisionSpec`.

Validation:

```bash
swift test
find SPECS/ontology/packages/examcalc/generated SPECS/specgraph/semantic-validation/out -type f | sort | xargs shasum -a 256 | shasum -a 256
```

Success metric: combined generated output hash remains `1ab28999c8d9e37ac7e447d1bf18d6e93145d32da0a5f3f12b0fda7408254f19`.

### Phase 5 - Documentation and Validation Report

- Update `SPECS/ontology/ontologyc.md` with module boundaries.
- Document the `SpecificationCore` dependency decision and accepted SwiftPM dependency surface.
- Add ONT-006 validation report.
- Confirm no new Ruby files or commands.

Validation:

```bash
rg -n "ruby|\\.rb" Package.swift Sources Tests SPECS/ARCHIVE/ONT-006_SpecificationCore_Baseline_and_Regression_Harness/ONT-006_Validation_Report.md
git status --short
```

Success metric: Ruby references are not introduced by ONT-006 changes.

## TODO Breakdown

The Workplan splits this PRD into five sequential implementation tasks so each Flow cycle can produce a focused PR.

| Workplan Task | Scope | PRD TODOs | Effort |
|---|---|---|---:|
| ONT-006 | SpecificationCore baseline and regression harness | T-001, T-002, T-005 | 11h |
| ONT-007 | `ontologyc` compiler module split | T-003, T-004 | 10h |
| ONT-008 | OntologyRules specification extraction | T-006, T-007 | 9h |
| ONT-009 | Ontology decision spec migration | T-008 | 5h |
| ONT-010 | Documentation, validation report, and audit | T-009, T-010 | 5h |

Total estimated effort remains **40h**.

| ID | Task | Priority | Effort | Dependencies | Verification |
|---|---|---:|---:|---|---|
| T-001 | Add baseline regression tests for CLI commands | High | 5h | None | `swift test` |
| T-002 | Add deterministic output hash helper in Swift tests | High | 3h | T-001 | Hash matches baseline |
| T-003 | Split `OntologyC` executable from compiler core | High | 5h | T-001 | CLI outputs unchanged |
| T-004 | Move IO, diagnostics, validation, normalization, emission, SpecGraph validation, and diff into focused files | High | 5h | T-003 | `swift test` |
| T-005 | Add `SpecificationCore` dependency and `OntologyRules` target | High | 3h | T-003 | `swift build`; `OntologyRules` imports `SpecificationCore` |
| T-006 | Extract metadata, package shape, and reference specs | High | 4h | T-005 | Rule tests |
| T-007 | Extract security, relation, policy, and state machine specs | High | 5h | T-005 | Rule tests |
| T-008 | Extract relation range, ref resolution, SpecGraph, and compatibility decisions | Medium | 5h | T-006, T-007 | Decision tests |
| T-009 | Update docs and validation report | Medium | 3h | T-008 | Report plus docs review |
| T-010 | Final no-diff, hash, and no-Ruby audit | High | 2h | T-009 | Baseline commands pass |

Total estimated effort: **40h**.

## Acceptance Mapping

| Acceptance Criterion | Covered By |
|---|---|
| Public CLI behavior remains unchanged. | FR-001, T-001, T-003 |
| Valid/invalid package validation remains unchanged. | FR-002, FR-003, T-001 |
| Generated IR and TypeScript artifacts remain deterministic. | FR-004, T-002, T-010 |
| SpecGraph validation preserves resolved/gap counts. | FR-005, T-001, T-008 |
| Compatibility diff preserves breaking-change classification. | FR-006, T-001, T-008 |
| Validation logic is expressed through named `SpecificationCore` specs and decisions. | FR-007, FR-008, FR-010, T-005 through T-008 |
| New implementation and tests are Swift-native. | FR-009, T-010 |

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Refactor accidentally changes output ordering | Generated files drift | Baseline hash and no-diff checks are mandatory gates |
| Exact diagnostics drift during extraction | Review noise and hidden behavior changes | Preserve diagnostic codes, messages, and paths; add snapshot assertions for core invalid fixtures |
| `SpecificationCore` dependency increases build surface | Slower builds and more package resolution complexity | Accept this tradeoff for 0AL stack consistency; pin version and record build timing |
| Splitting targets breaks CLI top-level behavior | User-facing regression | Keep `main.swift` thin but preserve command dispatch and exit handling |
| Tests become slow by shelling out to CLI | Developer friction | Use black-box tests for baseline and focused unit tests for rules |
| `SpecificationCore` API mismatch appears during migration | Refactor churn | Use only existing primitives already used by Hyperprompt; do not modify `SpecificationCore` in ONT-006 |

## Implementation Constraints

- Do not change ontology semantics.
- Do not change generated artifact schemas.
- Do not add Ruby.
- Do not introduce runtime network access.
- Do not execute YAML, generated TypeScript, or package content.
- Do not delete existing fixtures.
- Do not remove legacy Ruby validators in this task unless a separate cleanup PR is approved.
- Do not reimplement `SpecificationCore` locally.
- Do not change `SpecificationCore` source in this task.
- Keep changes reviewable by separating baseline tests, mechanical split, and spec migration commits where possible.

## Success Metrics

- `swift build` passes.
- `swift test` passes.
- `ontologyc check` passes canonical `examcalc`.
- All invalid fixtures still fail.
- Valid SpecGraph fixture remains `resolved=25 gaps=0`.
- Missing-ref fixture remains `resolved=2 gaps=1`.
- Compatibility diff remains incompatible for `examcalc-0.2.0-breaking.yaml`.
- Combined generated output hash remains unchanged.
- `Sources/OntologyC/main.swift` becomes a thin CLI entry point.
- Named specification and decision tests exist for every migrated rule cluster.
