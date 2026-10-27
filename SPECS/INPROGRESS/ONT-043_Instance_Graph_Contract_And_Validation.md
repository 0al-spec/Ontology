# ONT-043: Instance Graph Contract And Validation

**Date:** 2026-10-27
**Status:** Complete — local implementation and validation; hosted PR review pending
**Priority:** P1
**Reasoning Effort:** high
**Dependencies:** ONT-042, merged PR #66 (`a2e1af3`)
**Branch:** `codex/ont-043-instance-graph-validation`

## Objective and boundary

Implement the smallest versioned InstanceGraph contract for the reviewed
event-core vocabulary. The bounded `eventcore-v1` profile pins the exact compiled
IR, not arbitrary executable policy text. Structural consistency is not source
truth, physical causation, immutable storage or legal responsibility. ONT-044/045
and Linux portability remain separate tasks. No hosted inference or NormLab edit.

## Wire decisions

- JSON envelope: apiVersion/kind/profile, graphKey/revisionKey, ontology pin,
  projection declarations, finite nodes and edges. Reject unknown keys/nulls,
  malformed fields, unsafe numeric integers and unsupported profile/version.
- Nodes have local id, exact type, scalar fields and optional lifecycle state.
  Edges have a relation and typed from/to refs carrying graph/revision/node/type.
  Resolve all refs inside the same immutable input revision; reject duplicates.
- Projections declare schemaKey/projectionKey and observation/review/normative
  domain. RecordedEvent snapshots must use observation projections and agree
  on schema/scope/projection and Episode.scopeKey. Unknown states stay candidates.
- Each record has one registry revision with locally unique recordKey. Delta
  has one owner; each record has at most one Delta, even for identical duplicates.
  Recompute exact Added/Removed using propositionKey plus independent polarity.
- Candidate observations: known has one snapshot and no direct facts; unknown
  has neither; partial has facts but no snapshot. Review never promotes data.
- Hypothesis endpoints are Interpretations of distinct same-registry records,
  in one episode/clock with valid intervals and cause start no later than effect.
  Intervals may overlap. These checks do not prove causation or transfer duties.
- Scalar/source and lifecycle checks preserve unknown/opposed support and source
  speaker. Citation relevance and source authenticity are not inferred.

## Deliverables and implementation

1. Public compiler validate/export surfaces and CLI commands `validate-instances`
   and `export-instance-contract`; deterministic JSON diagnostic report.
2. Named specifications in OntologyRules; compiler handles IO, IR pin integrity,
   report mapping and generation. Keep new files below existing quality limits.
3. Contract documentation, synthetic fixtures and generated TypeScript/JSON Schema
   consumer contract. Export must not change existing package compile artifacts.
4. Tests before implementation: valid populated/empty/partial/source-only examples,
   negative mutations for required fields, identity/ranges/cardinality, duplicate
   and mismatched Delta, review/physical state confusion, source/lifecycle/clock
   errors; role reinterpretation and opposed-support controls. Test actual CLI.
5. Full Swift quality/coverage, existing TypeScript gates, deterministic export,
   fixture replay, docs/whitespace checks; archive and publish a reviewable PR.

## Verification and success criteria

Use verified TB5 scratch/cache/temp/profile routing for all local artifacts.
Run the test-first red/green loop, then the existing quality gate with coverage.
The new command returns 0 only for a valid graph and 1 with sorted diagnostics
for invalid data. Missing/unknown states cannot yield invented empty Delta;
supplied equal complete snapshots can. Mutating roles cannot replace a record's
states or create a second record with the same registry-local identity.

Generated contracts pin the same profile/IR as the validator. TypeScript checks
are consumer-shape evidence, not an independent semantic verifier. Reports must
label structural validation and list unverified truth/causality/responsibility.

## Workflow

BRANCH and SELECT checkpoints precede this PLAN. EXECUTE records actual results,
then ARCHIVE, self-REVIEW, FOLLOW-UP only if needed, and ARCHIVE-REVIEW. Hosted CI
and independent review are assessed on the published head before any later merge.
