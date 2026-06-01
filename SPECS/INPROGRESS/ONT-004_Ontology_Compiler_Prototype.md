# PRD: ONT-004 - Ontology Compiler Prototype

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Implementation Candidates  
**Reasoning Effort:** high  
**Dependencies:** ONT-001, ONT-002  
**Source Inputs:**
- `SPECS/Workplan.md`
- `SPECS/ontology/ontologyc.md`
- `SPECS/ontology/compiler-ir.md`
- `SPECS/ontology/domain-ontology-package.schema.yaml`
- `SPECS/ontology/fixtures/valid/minimal-domain-ontology-package.yaml`
- `SPECS/ontology/fixtures/invalid/*.yaml`
- `SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`
- `SPECS/ontology/packages/examcalc/validation-manifest.yaml`

## TL;DR

Implement a Swift-based `ontologyc` prototype that supports `check` and `compile` for `DomainOntologyPackage` YAML. The compiler must parse YAML as inert data, emit deterministic normalized IR, and generate TypeScript-oriented SDK artifacts for the canonical `examcalc` package.

## Conceptual Checklist

- Treat YAML as untrusted inert data.
- Reuse ONT-002 validation semantics: required metadata, class inheritance, relation refs, policies, state machines, and unsafe content detection.
- Normalize YAML into a deterministic IR before generating TypeScript files.
- Generate TypeScript artifacts only from normalized IR, never directly from raw YAML.
- Make generated output stable across repeated compiler runs.
- Keep the prototype small and replaceable by a future production compiler.

## Objective

Create the first working `ontologyc` prototype in this repository. It should be good enough to validate the ONT-003 golden package and generate deterministic TypeScript SDK artifacts that match the ONT-001 compiler contract.

Implementation language decision: ONT-004 uses Swift because the local environment has Swift 6.2 available and Rust is not installed. YAML parsing uses the MIT-licensed `Yams` Swift package, pinned by SwiftPM resolution.

## Scope

### In Scope

- Add Swift Package Manager executable target `ontologyc` with:
  - `check <package.yaml>`;
  - `compile <package.yaml> --target typescript --out <dir>`.
- Parse YAML with `Yams` as data and no execution/evaluation.
- Emit stable diagnostics and non-zero exit on error diagnostics.
- Emit normalized IR JSON at `ontology.normalized.json`.
- Emit TypeScript SDK files:
  - `refs.ts`
  - `types.ts`
  - `relations.ts`
  - `policies.ts`
  - `state-machines.ts`
  - `registry.ts`
  - `validators.ts`
- Generate the canonical `examcalc` SDK under `SPECS/ontology/packages/examcalc/generated/`.
- Add validation report.

### Out of Scope

- Production JSON Schema engine.
- Package registry resolution beyond declared import normalization.
- Lockfile generation and digest pinning.
- TypeScript compilation in CI.
- Compatibility diff command.
- ABox/instance validators beyond ontology-shaped reference validators.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | `ontologyc` prototype CLI | `Package.swift`, `Sources/OntologyC/main.swift` | Supports `check` and `compile`; exits non-zero on invalid input |
| D2 | Normalized IR output | `SPECS/ontology/packages/examcalc/generated/ontology.normalized.json` | Stable JSON derived from YAML through normalized model |
| D3 | TypeScript refs | `SPECS/ontology/packages/examcalc/generated/refs.ts` | Exports typed refs for classes, relations, policies, and state machines |
| D4 | TypeScript types | `SPECS/ontology/packages/examcalc/generated/types.ts` | Exports generated interfaces for ontology classes |
| D5 | TypeScript relations | `SPECS/ontology/packages/examcalc/generated/relations.ts` | Exports relation metadata |
| D6 | TypeScript policies | `SPECS/ontology/packages/examcalc/generated/policies.ts` | Exports policy metadata |
| D7 | TypeScript state machines | `SPECS/ontology/packages/examcalc/generated/state-machines.ts` | Exports state and transition metadata |
| D8 | TypeScript registry | `SPECS/ontology/packages/examcalc/generated/registry.ts` | Exports single registry object |
| D9 | TypeScript validators | `SPECS/ontology/packages/examcalc/generated/validators.ts` | Exports runtime ref validation helpers |
| D10 | Validation report | `SPECS/INPROGRESS/ONT-004_Validation_Report.md` | Records commands, outputs, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | `ontologyc check` MUST parse YAML as inert data. | Unsafe executable-looking fixture returns error diagnostics without execution. | `swift run ontologyc check SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml` |
| FR-002 | `ontologyc check` MUST reject invalid package metadata, inheritance, relation refs, policy refs, and state transitions. | Invalid ONT-002 fixtures fail. | Check command against invalid fixtures |
| FR-003 | `ontologyc check` MUST pass the canonical `examcalc` package. | Exit code `0`. | Check command against package |
| FR-004 | `ontologyc compile` MUST run check before emission. | Invalid package compile exits non-zero and emits no SDK. | Compile invalid fixture |
| FR-005 | Normalized IR MUST be deterministic. | Repeated compile produces byte-stable `ontology.normalized.json`. | Re-run compile and compare git diff |
| FR-006 | Generated artifacts MUST include `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and `validators.ts`. | All files exist after compile. | File existence checks |
| FR-007 | Generated artifacts MUST derive from IR only. | Generator code accepts normalized IR as input for TypeScript emission. | Code review and validator command |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Security | No eval, shell execution, dynamic require from YAML, or generated code execution. | `Yams` parsing plus static unsafe-content scanning only |
| Reproducibility | Output order must be stable. | Classes, relations, policies, and state machines sorted lexically in IR |
| Portability | Use Swift Package Manager only. | `swift build` resolves and builds the executable |
| License safety | Third-party parser dependency must be permissively licensed. | `Yams` is MIT-licensed and pinned through SwiftPM |
| Maintainability | Prototype must be readable and easy to replace. | Single CLI with small compiler phases: load, check, normalize, emit |

## CLI Contract

```bash
swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

Expected successful check output:

```text
ontologyc check: PASS SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Expected compile output:

```text
ontologyc compile: PASS SPECS/ontology/packages/examcalc/generated
```

## Implementation Roadmap

### Phase 1 - CLI and Checker

- Add SwiftPM executable target `ontologyc`.
- Implement safe YAML parsing and unsafe content scanning.
- Implement deterministic diagnostics for metadata, classes, relations, policies, and state machines.

### Phase 2 - Normalized IR

- Convert package YAML into `NormalizedOntologyIR`.
- Add `sourceDigest`.
- Normalize local refs to `${namespace}:${symbol}` and canonical URIs.
- Sort IR arrays lexically.

### Phase 3 - TypeScript Emitters

- Emit `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and `validators.ts`.
- Use the normalized IR object as the sole generator input.

### Phase 4 - Golden Compile and Validation

- Compile the ONT-003 `examcalc` package into `SPECS/ontology/packages/examcalc/generated/`.
- Run checks against valid and invalid fixtures.
- Save ONT-004 validation report.

## Success Metrics

- `ontologyc check` passes the canonical `examcalc` package.
- `ontologyc check` fails all ONT-002 invalid fixtures.
- `ontologyc compile` emits all required IR and TypeScript files.
- Generated files remain stable after repeated compile.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Prototype checker duplicates ONT-002 harness logic | Later maintenance overhead | Keep implementation simple and retire/merge into production compiler in follow-up |
| TypeScript files are generated but not typechecked | Syntax regression risk | Keep generated TS conservative and deterministic; document no TS toolchain configured |
| JSON Schema validation is partial | Some schema-only edge cases may pass | Use fixture-driven semantic checks now; full schema engine remains future work |
| Compiler grows into registry/diff work | Scope creep | Keep lockfile/diff/registry resolution out of ONT-004 |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Compiler parses YAML as inert data. | D1, FR-001, security validation |
| Compiler emits deterministic normalized IR. | D2, FR-005 |
| Compiler emits `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and validators. | D3 through D9, FR-006 |
