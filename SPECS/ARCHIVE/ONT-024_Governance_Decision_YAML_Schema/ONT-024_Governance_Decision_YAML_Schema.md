# ONT-024: Governance Decision YAML Schema

**Status:** PRD Ready  
**Date:** 2026-06-03  
**Priority:** P1  
**Dependencies:** ONT-023

## Summary

Define a machine-readable `OntologyGovernanceDecision` YAML artifact for ontology
approval, rejection, merge, supersession, and withdrawal decisions. This task turns the
ONT-023 governance protocol from prose-only guidance into a typed artifact contract that
future compiler and registry tasks can validate.

## Problem

ONT-023 defines governance states, reviewer authority, versioning, provenance, and audit
expectations. Today those requirements exist only in Markdown. That is sufficient for
repository PR review, but it is not enough for SpecGraph integration or registry
publication because tools cannot reliably answer:

- which package and version was approved;
- whether approval came from a human reviewer;
- which validation reports and digests supported the decision;
- whether a candidate was rejected, superseded, withdrawn, or merged;
- whether a publish operation has a trustworthy decision record.

## Goals

- Define a YAML schema for `OntologyGovernanceDecision`.
- Provide valid and invalid examples for authors, agents, and future tests.
- Link the schema from the governance protocol and authoring docs.
- Preserve the human trust boundary: generated agents may prepare evidence but must not
  approve trusted ontology truth.
- Create a stable contract for ONT-025 CLI validation and ONT-026 registry gating.

## Non-Goals

- No Swift compiler validation.
- No `ontologyc` CLI command changes.
- No registry publish enforcement.
- No cryptographic signature implementation.
- No live registry service changes.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Governance decision YAML schema | `SPECS/ontology/governance-decision.schema.yaml` |
| D2 | Valid approval decision example | `SPECS/ontology/examples/governance/approved-decision.yaml` |
| D3 | Invalid agent approval example | `SPECS/ontology/examples/governance/invalid-agent-approval.yaml` |
| D4 | Governance protocol schema linkage | `SPECS/ontology/governance-protocol.md` |
| D5 | Authoring guide / ontology docs linkage | `SPECS/ontology/authoring-guide.md`, `SPECS/ontology/ontologyc.md` |
| D6 | Validation report | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/ONT-024_Validation_Report.md` |

## Schema Requirements

The schema must define:

- `apiVersion: ontology-governance.specgraph.io/v1alpha1`;
- `kind: OntologyGovernanceDecision`;
- `metadata.id`;
- target package identity: package id, namespace, version, source path or URI;
- lifecycle decision state from the ONT-023 protocol;
- human reviewer identity for approval and rejection decisions;
- decision timestamp and rationale;
- evidence references for compiler validation, golden intent validation, compatibility
  reports, source package digest, candidate artifact digest, and optional PR/review URL;
- optional supersession metadata for `superseded`;
- explicit prohibition against private keys or secrets in the artifact.

## Acceptance Criteria

- [ ] Schema defines required top-level fields and rejects unknown lifecycle states.
- [ ] Schema distinguishes human reviewer authority from generated-agent evidence
  production.
- [ ] Valid approval example conforms to the intended schema shape.
- [ ] Invalid agent approval example documents the trust-boundary failure ONT-025 should
  reject.
- [ ] Governance protocol links to the schema and examples.
- [ ] Authoring docs identify decision records as the artifact future publish gates will
  consume.
- [ ] No compiler, CLI, registry, or generated TypeScript behavior changes in this task.

## Validation Plan

- `git diff --check`
- `test -f SPECS/ontology/governance-decision.schema.yaml`
- `test -f SPECS/ontology/examples/governance/approved-decision.yaml`
- `test -f SPECS/ontology/examples/governance/invalid-agent-approval.yaml`
- `bash tools/swift-quality.sh`

## Follow-Up Tasks

- ONT-025: implement deterministic `ontologyc validate-governance-decision`.
- ONT-026: integrate governance decision validation into registry publish flow.
