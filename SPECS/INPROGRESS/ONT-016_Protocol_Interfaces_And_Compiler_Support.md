# PRD: ONT-016 - Protocol Interfaces and Compiler Support

**Status:** Implemented; archive pending
**Priority:** P2  
**Phase:** Protocol Interfaces and Advanced Validation  
**Reasoning Effort:** high  
**Dependencies:** ONT-010  

## TL;DR

The YAML schema already declares a `protocols` section and an `implements` array on class
definitions, but the compiler ignores both. This task wires them up end-to-end: validate
protocol declarations and class conformance, propagate protocol metadata through the IR, and
emit TypeScript protocol interfaces so consumers can use structural contracts like `Signable`
and `Auditable` without hand-rolling them.

## Objective

Let ontology authors declare named protocols with required fields, required relations, and
optional semantic constraints in the YAML package. Classes that list a protocol in their
`implements` array are checked at compile time to satisfy those requirements. The TypeScript
emit layer produces a protocol interface per declaration and intersects it into each
conforming class type.

## Background

`domain-ontology-package.schema.yaml` already includes:

```yaml
protocolDefinition:
  required: [description]
  properties:
    description: string
    requiredFields: [nameReference]
    requiredRelations: [nameReference]
    semanticConstraints: [string]
```

`classDefinition.implements` already accepts an array of concept references. Neither field
is validated or emitted today. `PackageValidation.swift` skips `implements` entries silently,
and `TypeScriptEmitter.swift::emitTypes` never reads the `protocols` key from the IR.

## Scope

### In Scope

- **YAML validation** (`PackageValidation.swift`):
  - Each name listed in `spec.protocols` passes `OntologySymbolNameSpec`.
  - Each `implements` entry on a class resolves to a locally declared protocol or an
    imported protocol ref (same resolution rules as class `extends`).
  - Each class that `implements` a protocol satisfies the protocol's `requiredFields` and
    `requiredRelations` — emit `E_PROTO_FIELD_MISSING` / `E_PROTO_RELATION_MISSING`
    diagnostics for violations.
- **Normalization** (`Normalization.swift`):
  - Protocol entries are normalized with `fqid`, `uri`, `alias`, and `sourceDigest`
    contributions.
  - Each normalized class entry gains an `implementedProtocols` array of FQIDs.
- **TypeScript emit** (`TypeScriptEmitter.swift`):
  - New file `protocols.ts` — one exported `interface` per protocol, containing each
    `requiredField` as `readonly <field>: string` and a `$protocols` discriminant tuple.
  - `types.ts` — each class that implements protocols is typed as an intersection:
    `export type Exam = OntologyBase & Signable & Auditable & { readonly $type: "..." }`.
  - `validators.ts` — `isKnownOntologyRef` gains a sibling `isProtocolRef` guard.
  - `registry.ts` — `ontologyRegistry` gains a `protocols` entry.
- **Refs emit** (`emitRefs`): protocol refs are included in `allRefs` alongside class refs.
- **Schema** (`domain-ontology-package.schema.yaml`): no changes needed; the structure is
  already correct.
- **Tests**: unit tests for the new validation specs and decision paths; regression baseline
  updated for the new `protocols.ts` output file and changed `types.ts`/`registry.ts`.

### Out of Scope

- Runtime protocol enforcement beyond type-level checks.
- Protocol inheritance (`extends` on a protocol definition).
- Cross-package protocol resolution beyond the existing import mechanism.
- Code-generation for `semanticConstraints` (stored in IR, not emitted as TypeScript).

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Protocol validation specs | `Sources/OntologyRules/ProtocolSpecs.swift` | Named specs for symbol name, resolution, and conformance checks |
| D2 | Validation integration | `Sources/OntologyCompiler/PackageValidation.swift` | Protocol declarations and `implements` references validated; missing required fields/relations produce diagnostics |
| D3 | Normalization support | `Sources/OntologyCompiler/Normalization.swift` | `protocols` array present in normalized IR; classes carry `implementedProtocols` |
| D4 | TypeScript emit | `Sources/OntologyCompiler/TypeScriptEmitter.swift` | `protocols.ts` generated; `types.ts` emits intersection types; `registry.ts` includes protocols |
| D5 | Regression tests | `Tests/OntologyCompilerTests/` | Baseline hashes updated; new fixtures cover valid and invalid protocol usage |
| D6 | Rule tests | `Tests/OntologyRulesTests/` | Unit coverage for each new spec |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|----|-------------|---------------------|--------------|
| FR-001 | Protocol names MUST satisfy `OntologySymbolNameSpec`. | Invalid names produce `E_META_SYMBOL` diagnostics. | Unit test |
| FR-002 | `implements` refs MUST resolve to a declared or imported protocol. | Unresolved refs produce `E_REF_UNRESOLVED` diagnostics. | Unit test |
| FR-003 | Required fields declared in a protocol MUST exist as relation domains or explicit fields on the implementing class. | Missing required fields produce `E_PROTO_FIELD_MISSING`. | Unit test |
| FR-004 | Required relations MUST name relations whose domain includes the implementing class. | Missing required relations produce `E_PROTO_RELATION_MISSING`. | Unit test |
| FR-005 | Normalized IR MUST include a top-level `protocols` array. | IR JSON contains `protocols` key with FQID, uri, alias per protocol. | Regression hash |
| FR-006 | `protocols.ts` MUST export one TypeScript interface per protocol. | Generated file compiles without errors under `tsc --noEmit`. | Manual check |
| FR-007 | Class interfaces in `types.ts` MUST be intersection types when `implementedProtocols` is non-empty. | `Exam` becomes `OntologyBase & Signable & { … }`. | Regression hash |
| FR-008 | Existing behavior for packages without protocols MUST be unchanged. | All pre-existing regression hashes pass. | Regression suite |

## Implementation Roadmap

### Phase 1 — Validation

1. Add `ProtocolSpecs.swift` to `OntologyRules` with specs for symbol name and conformance.
2. Extend `PackageValidation.swift` to validate `spec.protocols` entries and `implements` refs.
3. Add `E_PROTO_FIELD_MISSING` and `E_PROTO_RELATION_MISSING` diagnostic codes.
4. Write `OntologyRulesTests` cases for each new spec.

### Phase 2 — Normalization

5. Extend `Normalization.swift` to normalize `protocols` into the IR.
6. Propagate `implementedProtocols` onto each normalized class entry.

### Phase 3 — TypeScript Emit

7. Add `emitProtocols()` function in `TypeScriptEmitter.swift` and wire it into `emit()`.
8. Update `emitTypes()` to produce intersection types.
9. Update `emitRegistry()` to include `protocols`.
10. Update `emitRefs()` to include protocol refs in `allRefs`.

### Phase 4 — Test and Baseline

11. Add valid fixture: package with `Signable` and `Auditable` protocols.
12. Add invalid fixtures: missing required field, unresolved `implements` ref.
13. Update regression baselines.
