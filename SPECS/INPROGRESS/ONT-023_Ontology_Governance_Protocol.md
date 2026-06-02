# ONT-023: Ontology Governance Protocol

**Status:** PRD Ready
**Created:** 2026-06-02
**Source:** `SPECS/Workplan.md`

## Summary

Define the governance protocol that turns generated ontology candidates and deltas into
accepted ontology package versions. ONT-019 documented the induction pipeline, ONT-021 added
semantic expectations, and ONT-022 added a repeatability harness. ONT-023 defines the
promotion protocol around those artifacts: approve, reject, merge, supersede, version, and
audit.

## Scope

### In Scope

- A documented governance protocol for candidate ontology packages and ontology deltas.
- Candidate lifecycle states and allowed transitions.
- Reviewer input requirements and decision record shape.
- Versioning and compatibility rules for accepted ontology deltas.
- Provenance and audit requirements.
- Feedback loop from governance outcomes into golden intent expectations.
- Links from authoring and induction docs.

### Out of Scope

- Compiler enforcement of governance states.
- Registry server implementation.
- Cryptographic signing or attestations.
- UI/workflow automation.
- Changing `DomainOntologyPackage` schema.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|---|---|---|---|
| D1 | Governance protocol | `SPECS/ontology/governance-protocol.md` | Defines lifecycle, decisions, versioning, audit, and expectation feedback |
| D2 | Authoring/induction links | `SPECS/ontology/authoring-guide.md`, `SPECS/ontology/induction-protocol.md` | Makes governance discoverable from authoring and promotion docs |
| D3 | Workplan/next updates | `SPECS/Workplan.md`, `SPECS/INPROGRESS/next.md` | ONT-023 status and next-task state are synchronized |
| D4 | Validation report | `SPECS/INPROGRESS/ONT-023_Validation_Report.md` | Records checks and residual risks |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|---|---|---|---|
| FR-001 | Protocol MUST define candidate lifecycle states. | Includes candidate, review, approved, rejected, merged, superseded, and withdrawn states. | `rg`/review |
| FR-002 | Protocol MUST define allowed transitions. | State transition table includes actor, required evidence, and output. | `rg`/review |
| FR-003 | Protocol MUST define reviewer inputs. | Includes source intent, candidate artifacts, `ontologyc` validation, repeatability report, critique, and compatibility evidence. | `rg`/review |
| FR-004 | Protocol MUST define decision record shape. | YAML example includes decision id, reviewer, verdict, rationale, evidence, and resulting version/delta metadata. | `rg`/review |
| FR-005 | Protocol MUST define versioning and compatibility handling. | Patch/minor/major guidance references compatibility diff evidence. | `rg`/review |
| FR-006 | Protocol MUST define provenance and audit requirements. | Decision records preserve source, candidate, validation, review, and timestamp metadata. | `rg`/review |
| FR-007 | Protocol MUST define feedback into golden expectations. | Accepted or rejected deltas can update expectations through explicit review, not automatically. | `rg`/review |
| FR-008 | Protocol MUST preserve trust boundary. | Generated agents cannot self-approve ontology truth. | `rg`/review |

## Non-Functional Requirements

| Category | Requirement | Acceptance Criteria |
|---|---|---|
| Clarity | Protocol should be usable by a human reviewer or agent supervisor. | State tables and YAML examples are concrete |
| Boundary control | Governance should not imply runtime enforcement. | Docs say this is a protocol, not compiler/registry implementation |
| Auditability | Decisions should be replayable from stored evidence. | Required evidence list is complete enough to reconstruct the decision |
| Stack alignment | Protocol should build on ONT-019/021/022 artifacts. | Links and terminology reuse existing docs |

## Acceptance Criteria

- `SPECS/ontology/governance-protocol.md` exists and covers lifecycle, transitions, reviewer
  inputs, decision records, versioning, audit, and golden expectation feedback.
- Authoring and induction docs link to the governance protocol.
- Workplan marks ONT-023 complete after archive.
- `git diff --check` passes.
- `bash tools/swift-quality.sh` passes.

## Risks

| Risk | Mitigation |
|---|---|
| Governance doc overpromises enforcement. | Explicitly state that compiler/registry enforcement is out of scope. |
| Decision process becomes too ceremonial for early use. | Keep required evidence focused on existing artifacts and allow lightweight single-reviewer approval for draft-stage packages. |
| Golden expectations mutate automatically from generated outputs. | Require explicit governance decision before expectation updates. |
