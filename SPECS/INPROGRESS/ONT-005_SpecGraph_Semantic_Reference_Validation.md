# PRD: ONT-005 - SpecGraph Semantic Reference Validation

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** SpecGraph Integration  
**Reasoning Effort:** high  
**Dependencies:** ONT-001, ONT-003  
**Source Inputs:**
- `SPECS/Workplan.md`
- `SPECS/ontology/core-contracts.md`
- `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`
- `SPECS/ontology/packages/examcalc/generated/ontology.normalized.json`
- `SPECS/ontology/packages/examcalc/specgraph-requirement-binding.yaml`
- `Sources/OntologyC/main.swift`

## TL;DR

Extend the Swift `ontologyc` prototype so SpecGraph semantic references can be validated against a compiled ontology package. Known refs must resolve to canonical `ConceptRef` records, missing refs must materialize as `OntologyGap`, and ontology package diffs must emit compatibility reports that classify breaking changes.

## Conceptual Checklist

- Use compiled ontology IR as the source of truth for semantic refs.
- Resolve aliases such as `examcalc:ExamPolicyProfile` to canonical URI-bearing `ConceptRef` records.
- Generate `OntologyLockfile` data from declared imports and resolved ontology metadata.
- Generate `OntologyGap` instead of inventing local pseudo-concepts.
- Classify compatibility changes deterministically from package diffs.
- Keep implementation in Swift; no Ruby in ONT-005.

## Objective

Prototype the SpecGraph-side semantic validation loop that sits above the ontology package compiler:

1. Read a SpecGraph artifact containing `ontologyImports` and `semanticRefs`.
2. Resolve imported ontology refs against `ontology.normalized.json`.
3. Emit canonical `ConceptRef` records and lockfile data for known refs.
4. Emit `OntologyGap` artifacts for missing refs.
5. Emit `OntologyCompatibilityReport` for package changes.

## Scope

### In Scope

- Add `ontologyc validate-specgraph <binding.yaml> --ontology-ir <ir.json> --out <dir>`.
- Add `ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>`.
- Add valid and missing-ref SpecGraph validation fixtures.
- Add a breaking `examcalc@0.2.0` compatibility fixture.
- Generate validation outputs:
  - resolved concept refs;
  - ontology lockfile;
  - ontology gaps;
  - compatibility report.
- Add ONT-005 validation report.

### Out of Scope

- Production registry service.
- Network registry resolution.
- Full SpecGraph project schema validation.
- Human approval workflows for ontology gaps.
- Lockfile update policy enforcement beyond deterministic output generation.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | `validate-specgraph` command | `Sources/OntologyC/main.swift` | Resolves known refs and emits gaps for missing refs |
| D2 | `diff` command | `Sources/OntologyC/main.swift` | Emits compatibility report with breaking change classification |
| D3 | Valid binding fixture | `SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml` | All refs resolve to canonical URIs |
| D4 | Missing-ref fixture | `SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml` | Missing `examcalc:CASFunction` emits `OntologyGap` |
| D5 | Breaking compatibility fixture | `SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml` | Diff classifies range change as breaking |
| D6 | Generated validation outputs | `SPECS/specgraph/semantic-validation/out/` | Contains concept refs, lockfile, gap, and compatibility report outputs |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-005_Validation_Report.md` | Records commands, outcomes, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Known `examcalc:*` refs MUST resolve to canonical URI-bearing `ConceptRef` records. | Valid binding output has zero gaps and non-empty concept refs. | `ontologyc validate-specgraph valid-semantic-binding.yaml` |
| FR-002 | Missing refs MUST emit `OntologyGap`. | Missing fixture emits `examcalc:CASFunction` gap. | `ontologyc validate-specgraph missing-ref-semantic-binding.yaml` |
| FR-003 | SpecGraph imports MUST be reflected in an `OntologyLockfile`. | Lockfile output pins ontology id, namespace, version, digest, and aliases. | Lockfile output check |
| FR-004 | Compatibility reports MUST classify removed classes/relations and relation domain/range changes as breaking. | Breaking fixture report contains `change relation range` and `compatible: false`. | `ontologyc diff` |
| FR-005 | Outputs MUST be deterministic. | Re-running validation produces no git diff. | Repeat commands and compare status |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Security | Validation must parse YAML/JSON as data only. | Swift `Yams` + Foundation parsing; no generated code execution |
| Reproducibility | Outputs must be stable. | Sorted refs, aliases, gaps, and compatibility changes |
| Scope control | Prototype must not become registry service. | Uses local IR/package paths only |
| License safety | Preserve ONT-004 dependency model. | Uses existing pinned `Yams` dependency |

## CLI Contract

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out SPECS/specgraph/semantic-validation/out/valid

swift run ontologyc diff \
  --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml \
  --out SPECS/specgraph/semantic-validation/out/compatibility-report.yaml
```

## Implementation Roadmap

### Phase 1 - SpecGraph Ref Validation

- Add multi-document YAML loading for SpecGraph fixtures.
- Build alias index from normalized ontology IR.
- Emit `ConceptRefSet`, `OntologyLockfile`, and `OntologyGapSet`.

### Phase 2 - Compatibility Diff

- Reuse package loader and normalizer from `ontologyc`.
- Compare class, relation, and policy symbols.
- Classify relation domain/range changes as breaking.
- Emit `OntologyCompatibilityReport`.

### Phase 3 - Fixtures and Outputs

- Add valid and missing-ref SpecGraph fixtures.
- Add breaking compatibility package fixture.
- Generate deterministic outputs under `SPECS/specgraph/semantic-validation/out/`.

### Phase 4 - Verification and Report

- Run Flow configured gates.
- Run Swift build.
- Run `validate-specgraph` for valid and missing fixtures.
- Run `diff` for compatibility report.
- Save ONT-005 validation report.

## Success Metrics

- Valid binding resolves all known refs with zero gaps.
- Missing binding emits exactly one gap for `examcalc:CASFunction`.
- Lockfile output includes digest and aliases for resolved refs.
- Compatibility report marks the breaking fixture incompatible.
- Re-running outputs is stable.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Multi-document SpecGraph parsing is partial | Some future artifact shapes may be missed | Recursively collect namespace-qualified refs in this prototype |
| Gap output is not a full governance workflow | Missing concept handling stops at artifact generation | Keep approval/delta workflow out of ONT-005 |
| Diff is narrow | Complex semantic changes may not classify yet | Cover Workplan-required breaking relation changes now |
| Lockfile is local-only | No registry integration | Use local IR digest and document registry as future work |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Known ontology refs resolve to canonical URIs. | D1, D3, D6, FR-001 |
| Missing refs create `OntologyGap`. | D1, D4, D6, FR-002 |
| Compatibility reports classify breaking ontology changes. | D2, D5, D6, FR-004 |

