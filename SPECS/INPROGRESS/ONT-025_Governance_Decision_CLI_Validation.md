# ONT-025: Governance Decision CLI Validation

**Status:** PRD Ready  
**Date:** 2026-06-03  
**Priority:** P1  
**Dependencies:** ONT-024

## Summary

Add deterministic `ontologyc validate-governance-decision` validation for
`OntologyGovernanceDecision` YAML artifacts. This task turns the ONT-024 schema contract
into compiler-owned validation while leaving registry publish enforcement for ONT-026.

## Problem

ONT-024 defines the decision artifact shape, but authors and SpecGraph integration still
need a native Swift validation path. Without a CLI command, governance records can drift
from the schema, point at the wrong package version, omit mandatory evidence, or approve
a package using a failing golden intent report.

## Goals

- Add an `OntologyCompiler` API for governance decision validation.
- Add `ontologyc validate-governance-decision <decision.yaml>` with optional evidence
  arguments.
- Emit deterministic PASS/FAIL behavior and diagnostics suitable for CI.
- Validate package identity/version against a supplied `DomainOntologyPackage` when present.
- Validate approval records against supplied golden intent validation reports when present.
- Add unit and CLI regression tests.

## Non-Goals

- No registry publish behavior changes.
- No signature or cryptographic verification.
- No live registry checks.
- No full JSON Schema engine dependency; validation should use existing YAML/Swift
  checks and the ONT-024 contract.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Compiler governance validation API | `Sources/OntologyCompiler/GovernanceDecisionValidation.swift` |
| D2 | CLI command and help text | `Sources/OntologyC/main.swift` |
| D3 | Unit tests | `Tests/OntologyCompilerTests/GovernanceDecisionValidationTests.swift` |
| D4 | CLI regression tests | `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift` |
| D5 | Validation fixtures if needed | `Tests/fixtures/governance/` |
| D6 | Documentation update | `SPECS/ontology/ontologyc.md`, `SPECS/ontology/governance-protocol.md` |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-025_Validation_Report.md` |

## CLI Shape

```bash
swift run ontologyc validate-governance-decision <decision.yaml> \
  [--package <domain-ontology-package.yaml>] \
  [--golden-report <golden-intent-validation-report.yaml>] \
  [--out <report.yaml>]
```

## Validation Requirements

The validator must reject:

- wrong `apiVersion` or `kind`;
- missing required top-level fields;
- unknown lifecycle state;
- missing decision actor, timestamp, or rationale;
- approval/rejection not performed by `kind: human`, `role: reviewer`;
- merge/supersession not performed by `kind: human`, `role: maintainer`;
- supersession without `supersedes`;
- missing mandatory evidence: source intent, candidate artifacts, candidate package,
  critique report, competency questions, compiler validation;
- empty evidence URIs;
- decision package id/namespace/version mismatch when `--package` is supplied;
- approved decisions paired with a supplied golden intent report whose result is failing.

## Report Shape

When `--out` is provided, emit deterministic YAML:

```yaml
apiVersion: ontology-governance.specgraph.io/v1alpha1
kind: OntologyGovernanceDecisionValidationReport
metadata:
  decision: path/to/decision.yaml
result:
  passed: true
checks:
  - id: governance.kind.valid
    status: pass
    message: kind is OntologyGovernanceDecision
```

## Acceptance Criteria

- [ ] Compiler API validates the ONT-024 decision contract without executing YAML.
- [ ] CLI command accepts decision path and optional package/golden-report/out flags.
- [ ] Invalid actor authority, missing evidence, malformed kind/version, and package mismatch
  produce deterministic diagnostics and non-zero exit.
- [ ] Approved decision plus failing golden report produces non-zero exit.
- [ ] Valid decision plus matching package and passing golden report exits zero.
- [ ] Tests cover unit and CLI behavior.
- [ ] Registry publish behavior remains unchanged.

## Validation Plan

- `git diff --check`
- Targeted unit tests for governance validation
- CLI regression tests for pass/fail command behavior
- `bash tools/swift-quality.sh`

## Follow-Up Task

- ONT-026: make trusted `ontologyc publish` require a valid approved governance decision.
