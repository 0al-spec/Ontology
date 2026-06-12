# `ontologyc` Compiler Contract

## Purpose

`ontologyc` is the static compiler for `DomainOntologyPackage` YAML. It validates untrusted ontology data, normalizes it into IR, and emits TypeScript-oriented semantic SDK artifacts.

## Security Rule

`ontologyc` MUST NOT execute ontology YAML. It MUST NOT evaluate hooks, expressions, factories, imports as code, or generated files during validation. YAML is untrusted data.

## Commands

### `ontologyc check`

```bash
swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Behavior:

1. Parse YAML as inert data.
2. Validate against `domain-ontology-package.schema.yaml`.
3. Resolve imports.
4. Validate class inheritance and protocol references.
5. Validate relation domain/range and cardinality.
6. Validate policy applicability.
7. Validate state machine transitions.
8. Emit diagnostics.
9. Exit non-zero on any `error` diagnostic.

### `ontologyc compile`

```bash
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

Behavior:

1. Run `ontologyc check`.
2. Emit `ontology.normalized.json` from normalized IR.
3. Emit generated TypeScript files from IR.
4. Emit runtime validators.
5. Preserve deterministic output order for all generated files.

## Required Generated Files

| File | Purpose |
|---|---|
| `refs.ts` | Typed `ConceptRef` constants. |
| `types.ts` | Generated instance interfaces projected from semantic declarations. |
| `relations.ts` | Typed relation definitions. |
| `policies.ts` | Policy definitions and applicability metadata. |
| `state-machines.ts` | State machine definitions and transition metadata. |
| `registry.ts` | Single generated registry export. |
| `validators.ts` | Runtime validators for ontology-shaped documents. |
| `ontology.normalized.json` | Serialized normalized IR. |

SpecGraph validation emits separate semantic reference artifacts:

| File | Purpose |
|---|---|
| `concept-refs.yaml` | Resolved ontology concepts referenced by SpecGraph artifacts. |
| `ontology.lock.yaml` | Resolved ontology import lock data. |
| `ontology-gaps.yaml` | Missing semantic references requiring ontology follow-up. |
| `ontologyc-adapter-report.yaml` | Review-only adapter report binding validation outputs to package source/version/digest and explicit no-canonical-mutation authority flags. |

### `ontologyc validate-specgraph`

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/examcalc-semantic-validation \
  --source-uri git+https://github.com/0al-spec/Ontology.git \
  --source-ref main
```

Behavior:

1. Parse SpecGraph semantic binding YAML as inert data.
2. Resolve refs against the supplied normalized ontology IR.
3. Emit `concept-refs.yaml`, `ontology.lock.yaml`, and `ontology-gaps.yaml`.
4. Emit `ontologyc-adapter-report.yaml` with package id, namespace, version,
   source URI/ref, and digest from normalized IR `sourceDigest`.
5. Set report authority flags so the report remains evidence only:
   `report_is_authority: false`, `ontology_lock_is_canonical: false`,
   `automatic_import_lock_update: false`, and
   `automatic_canonical_node_update: false`.
6. Preserve existing PASS/FAIL stdout and non-zero failure behavior.

`--source-uri` and `--source-ref` are optional metadata fields for downstream
review surfaces. When omitted, the report leaves those fields empty. The digest
authority remains the normalized IR `sourceDigest`.

### `ontologyc import-hypercode`

```bash
swift run ontologyc import-hypercode <hypercode-ir.json> \
  --out /tmp/domain-ontology-package.yaml \
  --id org.0al.example \
  --namespace example \
  --version 0.1.0
```

Behavior:

1. Parse Hypercode resolved IR as inert JSON data. No `.hc`/`.hcs` parsing or cascade
   resolution happens inside Ontology.
2. Accept `hypercode.ir/v1` and `hypercode.ir/v2`.
3. For generic graphs, emit a reviewable `DomainOntologyPackage` draft from unique node
   types, preserving the original ONT-020 spike behavior.
4. For `hypercode.ir/v2` graphs shaped as an Ontology package
   (`Package > Metadata/Imports/Classes/Relations/Policies/StateMachines/Compatibility`),
   map resolved properties into real package sections.
5. Require the imported package status to remain `metadata.approvalStatus: draft`.
   Hypercode context may describe lifecycle state, but trusted ontology approval remains a
   governance decision boundary, not an import side effect.
6. Emit YAML that must pass `ontologyc check`.

## Validation Details

| Area | Required Checks |
|---|---|
| Metadata | `metadata.id`, `metadata.namespace`, and `metadata.version` exist and are valid. |
| Imports | Import ids and versions resolve or produce an error diagnostic. |
| Classes | Every class extends exactly one valid base class. |
| Protocols | Implemented protocols resolve and declare obligations. |
| Relations | Domain and range resolve; relation ids are unique. |
| State Machines | States are unique; transition endpoints exist; command/event refs resolve when declared. |
| Policies | Policy targets resolve; enforceability is one of the allowed values. |
| Security | Executable-looking hooks or expressions are rejected or treated as inert scalars. |
| Compatibility | Diffs classify patch, minor, and major changes deterministically. |

## Compatibility Command

```bash
swift run ontologyc diff \
  --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml \
  --out SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

Output kind:

```yaml
apiVersion: ontology.specgraph.io/v1alpha1
kind: OntologyCompatibilityReport
metadata:
  from: edu.university.examcalc@0.1.0
  to: edu.university.examcalc@0.2.0
result:
  compatible: false
  requiredSpecGraphActions:
    - reviewBreakingOntologyChange
changes:
  addedClasses: []
  addedRelations: []
  breakingChanges:
    - change relation range examcalc:allows
  removedClasses: []
  removedRelations: []
```

## Governance Decision Artifact

Ontology governance decisions are represented as inert YAML data with:

```yaml
apiVersion: ontology-governance.specgraph.io/v1alpha1
kind: OntologyGovernanceDecision
```

The schema lives at [`governance-decision.schema.yaml`](governance-decision.schema.yaml).
It records the package identity, lifecycle decision state, human reviewer authority,
rationale, and evidence references used to approve, reject, merge, supersede, or withdraw
an ontology candidate.

Current boundary: this artifact is documentation-level contract only. `ontologyc` does
not validate governance decisions in ONT-024. Future tasks add deterministic CLI
validation and registry publish gating against this schema.

### `ontologyc validate-governance-decision`

```bash
swift run ontologyc validate-governance-decision \
  SPECS/ontology/examples/governance/approved-decision.yaml \
  --package SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --out /tmp/governance-decision-report.yaml
```

Behavior:

1. Parse the governance decision YAML as inert data.
2. Validate `apiVersion`, `kind`, package identity, decision state, actor authority,
   rationale, and mandatory evidence references.
3. When `--package` is supplied, ensure decision package id, namespace, and version match
   the supplied `DomainOntologyPackage`.
4. When `--golden-report` is supplied for an approved decision, require the golden intent
   validation report to pass.
5. Emit `OntologyGovernanceDecisionValidationReport` when `--out` is supplied.
6. Exit non-zero for invalid governance records.

Registry `publish` has an explicit trust boundary:

- `--channel candidate` is the default and preserves draft/integration publication.
- `--channel trusted` requires `--decision <decision.yaml>` and rejects publication unless
  the decision validates against the supplied package and has lifecycle state `approved`.
- `--golden-report` requires `--decision`, including candidate publication, so evidence
  flags cannot be silently ignored.

The trusted gate runs before any registry network call. `pull` and `compat-check` do not
consume governance decisions.

Registry transports:

- HTTP(S) registries keep the ONT-018 contract: `publish` PUTs normalized IR to
  `<registry>/ontologies/<id>/<version>`, and `pull`/`compat-check` GET the same ref.
- Local `file://` registries write deterministic files under
  `ontologies/<id>/<version>/ontology.normalized.json` with review metadata in
  `registry-entry.yaml` and `channels/<channel>/<id>/<version>.yaml`.
- A local registry becomes git-backed when its root directory lives in a git repository.
  `ontologyc` does not clone, commit, push, or contact a git remote.

### `ontologyc validate-draft`

```bash
swift run ontologyc validate-draft \
  SPECS/ontology/fixtures/induction-drafts/valid/voice-recorder \
  --out /tmp/induction-draft-validation.yaml
```

Behavior:

1. Parse the four staged induction artifacts as inert YAML data.
2. Validate `IntentClassification`, `ProductOntologyDraft`, and `DraftCritique` against
   the minimal induction artifact contract.
3. Validate `domain-ontology-package-draft.yaml` through the existing
   `DomainOntologyPackage` compiler rules.
4. Require the package draft to keep `metadata.approvalStatus: draft`.
5. Emit an `InductionDraftValidationReport` when `--out` is supplied.
6. Exit non-zero for structural, provenance, uncertainty, schema-version, or package
   validation errors.

This command is not governance. A passing draft-validation report means staged candidate
artifacts are structurally ready for `ontologyc check`, golden-intent comparison where
applicable, and human/governance review.

## Non-Goals for ONT-001

- No production compiler implementation.
- No ABox instance validation implementation.
- No execution of generated code during checks.
- No registry service implementation.

## ONT-004 Prototype

The repository prototype is a Swift Package Manager executable target named `ontologyc`. It uses the MIT-licensed `Yams` parser and emits the initial TypeScript-oriented artifacts required by this contract:

```bash
swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

## ONT-005 Semantic Validation Prototype

The same Swift executable validates SpecGraph semantic references against compiled ontology IR and emits `ConceptRef`, `OntologyLockfile`, `OntologyGap`, and compatibility report artifacts:

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out SPECS/specgraph/semantic-validation/out/valid

swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out SPECS/specgraph/semantic-validation/out/missing
```

## Current Swift Implementation

The ONT-006..ONT-010 refactor keeps the public executable name and command behavior stable while splitting implementation ownership across SwiftPM targets:

| Target | Ownership |
|---|---|
| `OntologyC` | Thin executable entry point in `Sources/OntologyC/main.swift`; parses command shape, delegates to `OntologyCompiler`, prints public PASS/FAIL lines, and exits with the existing status codes. |
| `OntologyCompiler` | Importable compiler orchestration in `Sources/OntologyCompiler/`; owns diagnostics, YAML/JSON IO, package loading, validation call sites, normalization, TypeScript emission, SpecGraph validation, and compatibility report materialization. |
| `OntologyRules` | Specification and decision layer in `Sources/OntologyRules/`; owns reusable validation predicates and typed decisions backed by `SpecificationCore`. |

`OntologyCompiler` intentionally keeps output materialization concerns that depend on ordering or aggregate state. For example, SpecGraph gap ordinal assignment stays in compiler orchestration, while `SpecGraphRefDecisionSpec` only decides whether one semantic ref is resolved or missing.

## SpecificationCore Dependency

`OntologyRules` depends on `SpecificationCore` 1.0.0 from the shared 0AL Swift stack:

```swift
.package(url: "https://github.com/SoundBlaster/SpecificationCore", from: "1.0.0")
```

The dependency is used directly rather than cloning the pattern locally:

- boolean validation predicates conform to `Specification`;
- typed classification branches conform to `DecisionSpec`;
- no `SpecificationCore` macros are used in ontology rules;
- no local `Specification` or `DecisionSpec` protocol clone is introduced.

This keeps the compiler aligned with the same specification pattern used by Hyperprompt while preserving `ontologyc` behavior byte-for-byte.

## Rule and Decision Ownership

| Rule File | Responsibility |
|---|---|
| `PackageShapeSpecs.swift` | Expected `apiVersion` and `kind`. |
| `MetadataSpecs.swift` | Ontology id, namespace, version, symbol, state, and concept-ref syntax patterns. |
| `ReferenceSpecs.swift` | Local/imported concept refs and local trigger refs. |
| `SecuritySpecs.swift` | Unsafe YAML keys, tags, and executable-looking scalar values. |
| `RelationSpecs.swift` | Boolean relation range shape checks. |
| `PolicySpecs.swift` | Allowed policy enforceability values. |
| `StateMachineSpecs.swift` | Declared state membership checks. |
| `RelationDecisionSpecs.swift` | Scalar, `oneOf`, or invalid relation range classification. |
| `ReferenceDecisionSpecs.swift` | Local, imported, unresolved, or invalid concept-ref classification. |
| `SpecGraphDecisionSpecs.swift` | Resolved-vs-gap semantic ref classification. |
| `CompatibilityDecisionSpecs.swift` | Compatible-vs-breaking compatibility change classification. |

## Behavior-Preserving Refactor Policy

The refactor is constrained by the ONT-006 baseline:

- public commands remain `check`, `compile`, `validate-specgraph`, and `diff`;
- diagnostic codes, messages, and paths must remain stable unless a dedicated PRD changes them;
- generated `examcalc` IR and TypeScript artifacts must remain byte-identical;
- SpecGraph validation outputs and compatibility report outputs must remain byte-identical;
- YAML remains inert data and is never executed;
- new implementation and validation tooling stays Swift-native; no Ruby growth is allowed.
