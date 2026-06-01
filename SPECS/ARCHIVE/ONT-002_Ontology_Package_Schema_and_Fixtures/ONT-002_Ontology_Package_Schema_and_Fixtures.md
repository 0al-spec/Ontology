# PRD: ONT-002 - Ontology Package Schema and Fixtures

**Status:** PRD Ready  
**Priority:** P1  
**Phase:** Implementation Candidates  
**Reasoning Effort:** medium  
**Dependencies:** ONT-001  
**Source Inputs:**
- `SPECS/Workplan.md`
- `SPECS/ARCHIVE/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import/ONT-001_Ontology_Layer_And_SpecGraph_Semantic_Import.md`
- `SPECS/ontology/domain-ontology-package.schema.yaml`
- `SPECS/ontology/examples/examcalc.ontology.yaml`

## TL;DR

Turn the ONT-001 `DomainOntologyPackage` contract into a validated schema-and-fixture package. The task must tighten the machine-readable JSON Schema, add valid and invalid YAML fixtures, and provide a dependency-free local validation harness that proves the schema expectations and semantic guardrails are testable before the future `ontologyc` prototype exists.

## Conceptual Checklist

- Keep ontology YAML inert data; never execute fixture content.
- Validate required top-level metadata and `spec` sections structurally.
- Reject multiple inheritance by enforcing scalar `extends`.
- Validate relation and policy references against known local classes and imported foundation aliases.
- Validate state machine transitions against declared states and command/event classes.
- Capture known-invalid fixtures for regression coverage.
- Keep implementation small enough to be replaced by `ontologyc` in ONT-004.

## Objective

Implement the machine-readable schema and fixture suite required to validate `DomainOntologyPackage` documents in the repository. ONT-002 is not the compiler implementation; it is the schema and test corpus that future compiler and SpecGraph validators can consume.

## Scope

### In Scope

- Tighten `SPECS/ontology/domain-ontology-package.schema.yaml` where ONT-001 left validation gaps.
- Add a valid minimal `DomainOntologyPackage` fixture.
- Add invalid fixtures for:
  - missing required metadata;
  - invalid multiple inheritance shape;
  - unknown relation references;
  - unsafe executable-looking YAML content.
- Add a lightweight validation harness that:
  - parses YAML as inert data;
  - validates the repository fixtures;
  - emits deterministic pass/fail diagnostics;
  - has no network or package-manager dependency.
- Document fixture intent and validation commands.
- Produce an ONT-002 validation report.

### Out of Scope

- Full `ontologyc check` or `ontologyc compile` implementation.
- TypeScript SDK generation.
- Registry, lockfile, compatibility diff engine, or package publishing.
- ABox/instance-level validation.
- Execution of hooks, expressions, plugins, or embedded commands in YAML.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Tightened package schema | `SPECS/ontology/domain-ontology-package.schema.yaml` | Requires metadata, classes, relations, policies, and state machine structures needed by fixtures |
| D2 | Valid fixture suite | `SPECS/ontology/fixtures/valid/*.yaml` | At least one valid package passes local validation |
| D3 | Invalid fixture suite | `SPECS/ontology/fixtures/invalid/*.yaml` | Fixtures cover missing metadata, invalid inheritance, unknown relation refs, and unsafe executable-looking YAML |
| D4 | Fixture validation harness | `SPECS/ontology/fixtures/validate-fixtures.rb` | Runs with system Ruby and exits non-zero on unexpected fixture result |
| D5 | Fixture README | `SPECS/ontology/fixtures/README.md` | Explains fixture categories, expected results, and validation command |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-002_Validation_Report.md` | Records commands, outcomes, and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | A `DomainOntologyPackage` MUST declare `apiVersion`, `kind`, `metadata.id`, `metadata.namespace`, `metadata.version`, and `spec`. | Missing metadata fixture fails. | `invalid/missing-metadata.yaml` |
| FR-002 | `spec.classes`, `spec.relations`, `spec.policies`, and `spec.stateMachines` MUST be objects. | Wrong section shapes fail. | Schema and harness checks |
| FR-003 | Every class MUST extend exactly one foundation, imported, or local class reference. | Array-valued `extends` fails as multiple inheritance. | `invalid/invalid-inheritance.yaml` |
| FR-004 | Relation `domain` and `range` values MUST resolve to declared local classes or imported aliases. | Unknown relation ref fails. | `invalid/unknown-relation-ref.yaml` |
| FR-005 | Policy `appliesTo` values MUST resolve to declared local classes or imported aliases. | Unknown policy target fails. | Harness reference checks |
| FR-006 | State machine transitions MUST reference declared states and known command/event classes when `command` or `event` is present. | Unknown state or command/event fails. | Harness state machine checks |
| FR-007 | YAML content MUST be treated as inert data and rejected when executable-looking hooks or expressions appear. | Unsafe fixture fails without executing content. | `invalid/unsafe-executable-looking-yaml.yaml` |
| FR-008 | Existing `examcalc` example MUST remain valid under the local validation harness. | Example passes. | Harness includes `SPECS/ontology/examples/examcalc.ontology.yaml` |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Security | Fixture validation MUST NOT evaluate YAML tags, shell strings, hooks, or embedded expressions. | Harness uses safe YAML loading and static string/key scanning only |
| Reproducibility | Validation output MUST be deterministic. | Fixtures are sorted by path before validation |
| Portability | Validation MUST require only tools already present in the repo environment. | Ruby stdlib only |
| Maintainability | The harness MUST be small and explicitly temporary until `ontologyc` exists. | README documents replacement path |

## Validation Harness Behavior

The harness validates three groups:

1. `SPECS/ontology/examples/examcalc.ontology.yaml` - expected valid.
2. `SPECS/ontology/fixtures/valid/*.yaml` - expected valid.
3. `SPECS/ontology/fixtures/invalid/*.yaml` - expected invalid.

Expected diagnostics:

```text
PASS valid   SPECS/ontology/examples/examcalc.ontology.yaml
PASS valid   SPECS/ontology/fixtures/valid/minimal-domain-ontology-package.yaml
PASS invalid SPECS/ontology/fixtures/invalid/missing-metadata.yaml
PASS invalid SPECS/ontology/fixtures/invalid/invalid-inheritance.yaml
PASS invalid SPECS/ontology/fixtures/invalid/unknown-relation-ref.yaml
PASS invalid SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml
```

If any expected-valid fixture fails, or any expected-invalid fixture passes, the command exits non-zero.

## Implementation Roadmap

### Phase 1 - Schema Tightening

- Require `policies` and `stateMachines` in `spec`.
- Add section-level `minProperties` where empty sections would hide missing coverage.
- Tighten reference string patterns for class, protocol, relation, policy, command, event, and state names.
- Keep schema strictly structural; semantic cross-reference validation belongs in the harness until `ontologyc`.

### Phase 2 - Fixtures

- Add one minimal valid package that exercises metadata, imports, classes, relations, policies, state machines, and compatibility.
- Add four invalid fixtures mapped one-to-one to Workplan acceptance criteria.
- Keep invalid fixtures small so failure reason is unambiguous.

### Phase 3 - Validation Harness

- Implement safe YAML loading.
- Validate required structure and static unsafe keys/values.
- Resolve local and imported references for relations, policies, and state machines.
- Print deterministic diagnostics and fail on expectation mismatch.

### Phase 4 - Verification and Report

- Run Flow configured gates:
  - `test -f README.md`
  - `test -f SPECS/Workplan.md`
- Run fixture validation:
  - `ruby SPECS/ontology/fixtures/validate-fixtures.rb`
- Save results in `SPECS/INPROGRESS/ONT-002_Validation_Report.md`.

## Success Metrics

- `ruby SPECS/ontology/fixtures/validate-fixtures.rb` exits `0`.
- All required invalid fixture categories are present and fail for the intended reason.
- Existing `examcalc` ontology remains valid.
- No validation step executes YAML-provided behavior.

## Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| JSON Schema cannot express all cross-reference rules cleanly | Schema alone gives false confidence | Keep structural rules in schema and semantic rules in harness |
| Temporary Ruby harness diverges from future `ontologyc` | Duplicate validation logic | Document it as a pre-compiler guard and keep checks small |
| Unsafe YAML detection becomes overly broad | Valid prose could be rejected | Reject only executable-looking keys and high-risk command substitution markers in this task |
| Schema tightening breaks ONT-001 example | Regression in golden example | Include `examcalc.ontology.yaml` in validation harness |

## Acceptance Mapping

| Workplan Acceptance Criterion | Covered By |
|---|---|
| Schema validates required metadata, classes, relations, policies, and state machines. | D1, D2, FR-001 through FR-006 |
| Invalid fixtures cover missing metadata, invalid inheritance, unknown relation refs, and unsafe executable-looking YAML. | D3, FR-001, FR-003, FR-004, FR-007 |

