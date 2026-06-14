# ONT-037: SpecGraph Owner Decision Report Export PRD

**Status:** PRD Ready
**Priority:** P0
**Phase:** External Ontology Import Plane Follow-Ups
**Reasoning Effort:** high
**Dependencies:** ONT-036
**Branch:** `codex/ont-037-specgraph-owner-decisions`

## TL;DR

Add an Ontology-owned export path for SpecGraph ontology delta owner decisions.
The export reads a reviewable Ontology decision input, validates accepted,
rejected, and needs-clarification states, and writes a deterministic
`ontology_owner_decision_report` artifact compatible with the SpecGraph
0114/0115 read-only contract.

The report is evidence only. It must not write Ontology packages, update
ontology lockfiles, import decisions into SpecGraph, close semantic gates, or
mutate canonical SpecGraph specs.

## Problem

SpecGraph already has read-only surfaces for owner decisions:

- `ontology_owner_decision_report`
- `ontology_decision_import_preview`
- SpecSpace owner-decision review panels

Those surfaces currently rely on graph-side fixture decisions. The next
Ontology-side slice should make those decisions real owner-reviewed artifacts
that Ontology can emit for SpecGraph delta candidates.

## Goals

1. Define a compact Ontology-owned decision input for SpecGraph delta
   candidates.
2. Add a deterministic exporter that writes the SpecGraph-compatible
   `ontology_owner_decision_report` shape.
3. Support `accepted`, `rejected`, and `needs_clarification` owner decisions.
4. Validate required identity fields: decision id, candidate id, intake id,
   decision state, decision ref, actor, timestamp, and accepted-delta flag.
5. Enforce the authority boundary: no SpecGraph import, no semantic gate close,
   no canonical spec mutation, no Ontology package write, and no lockfile
   update.
6. Add tests and docs that show the report is evidence, not automatic
   application.

## Non-Goals

- Applying decisions to SpecGraph.
- Closing SpecGraph semantic gates.
- Writing `DomainOntologyPackage` YAML.
- Updating an ontology package lockfile.
- Publishing to trusted registry.
- Prompt-agent execution.
- SpecSpace UI changes.

## Proposed CLI Contract

```bash
swift run ontologyc export-specgraph-owner-decisions \
  SPECS/ontology/examples/specgraph-owner-decisions/examcalc-owner-decisions.yaml \
  --out /tmp/ontology-owner-decision-report.json
```

The command validates the input as inert data and writes JSON:

```json
{
  "artifact_kind": "ontology_owner_decision_report",
  "schema_version": 1,
  "proposal_id": "0114",
  "canonical_mutations_allowed": false,
  "tracked_artifacts_written": false,
  "decisions": [],
  "ignored_decisions": []
}
```

## Input Shape

The first slice can use a small YAML decision set:

```yaml
artifact_kind: ontology_specgraph_owner_decision_set
schema_version: 1
source_artifacts:
  ontology_closed_loop_evidence: runs/ontology_closed_loop_evidence.json
decisions:
  - decision_id: ontology-owner-decision-accept-casfunction
    candidate_id: ontology-delta-candidate-examcalc-casfunction
    intake_id: ontology-delta-draft-intake-ontology-delta-candidate-examcalc-casfunction
    decision_state: accepted
    ontology_decision_ref: ontology-decision://edu.university.examcalc/0.1.0/casfunction/accepted
    decided_by: ontology-owner
    decided_at: "2026-06-14T00:00:00Z"
    reason: Accepted as an owner-reviewed package draft candidate.
    accepted_ontology_delta: true
```

Rejected and clarification decisions must set `accepted_ontology_delta: false`.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Decision export model and validator | `Sources/OntologyCompiler/SpecGraphOwnerDecisionExport.swift` | Validates input kind/schema, states, required ids, accepted flag consistency, and authority flags. |
| D2 | CLI command | `Sources/OntologyC/main.swift`, `Sources/OntologyC/CLIArguments.swift` | `export-specgraph-owner-decisions <decisions.yaml> --out <report.json>` writes deterministic JSON. |
| D3 | Example fixture | `SPECS/ontology/examples/specgraph-owner-decisions/` | Contains accepted, rejected, and needs-clarification examples. |
| D4 | Tests | `Tests/OntologyCompilerTests/SpecGraphOwnerDecisionExportTests.swift` | Tests report shape, state counts, false authority flags, invalid state, and accepted flag mismatch. |
| D5 | Docs | README, `SPECS/ontology/core-contracts.md`, DocC as needed | Docs explain that exported decisions are review evidence only. |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-037_Validation_Report.md` | Records local quality gates and residual risks. |

## Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-001 | Export MUST write `artifact_kind: ontology_owner_decision_report`. | Unit and CLI tests |
| FR-002 | Export MUST include `accepted`, `rejected`, and `needs_clarification` decisions. | Fixture and report assertions |
| FR-003 | `accepted_ontology_delta` MUST be true only for accepted decisions. | Invalid fixture test |
| FR-004 | All mutation/import/gate-close flags MUST be false. | Report assertions |
| FR-005 | Summary counts MUST match emitted decisions. | Report assertions |
| FR-006 | The command MUST fail before writing report for invalid input. | CLI failure test |

## Risks

| Risk | Mitigation |
|------|------------|
| SpecGraph treats accepted decisions as automatic imports. | Emit explicit false `imports_into_specgraph`, `closes_semantic_gate`, and `mutates_canonical_specs` flags and document review-only semantics. |
| Owner decision input becomes a second package governance format. | Keep this slice scoped to SpecGraph delta candidate decisions; package approval remains governed by `OntologyGovernanceDecision`. |
| Report drifts from SpecGraph 0114 shape. | Copy the field names from the existing SpecGraph contract and lock them in tests. |

## Notes

Later slices can connect the exporter to registry-backed decision records,
cryptographic signatures, or real owner-review workflow state. This PR only
needs a deterministic, testable Ontology-owned artifact boundary.
