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
5. Emit `ontology.schema.json`.
6. Emit `ontology.lock.yaml`.

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
| `ontology.schema.json` | JSON Schema for package or generated instances. |
| `ontology.lock.yaml` | Resolved dependency lock data. |

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
  compatible: true
changes:
  addedClasses: []
  addedRelations: []
  breakingChanges: []
```

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
