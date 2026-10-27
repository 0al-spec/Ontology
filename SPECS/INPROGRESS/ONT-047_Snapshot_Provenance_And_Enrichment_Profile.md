# ONT-047 — Snapshot Provenance And Enrichment Profile

**Date:** 2026-10-27
**Status:** PRD Ready
**Base:** main / merged ONT-043 PR #67; independent of ONT-044 PR #68

## Problem

The frozen eventcore-v1 profile accepts invented empty snapshots attached to an
unknown candidate. A source link is neither origin confirmation nor factual truth.
Add an explicitly selected reviewed revision, preserving the old contract verbatim.

## Deliverables

1. Preserve events-core 0.1.0 and eventcore-v1 artifacts and report semantics.
   Add events-core 0.2.0 under versions/0.2.0, generated IR/SDK and authoring evidence.
2. Three disjoint origin classes: SourceSnapshotOrigin (cited assertions),
   DirectObservationOrigin (observer, artifact, capture clock/time), and
   OperatorSnapshotOrigin (operator identity and explicit rationale). Every new
   StateSnapshot has exactly one origin, including empty and unreferenced snapshots.
3. Explicit eventcore-provenance-v1 selection, version/definition/IR pins and
   generated consumer contracts. Default remains eventcore-v1; no auto-upgrade.
4. A separately supplied SnapshotProvenanceAuthority input, bound to exact graph
   bytes by graphSHA256. Scoped capability grants and per-snapshot confirmations
   authorize declared provenance. Separate per-candidate/record enrichment grants
   are required for candidateEnrichedByRecord and interpretation resolution.
   Graph-local review or source presence grants no authority. A changed graph
   requires explicit reconfirmation; replay against stale authority input fails.
5. CLI/library admission, deterministic reports, fixtures and regression controls.
   Source presence, origin confirmation and factual truth remain separate.

## Trust and semantics

The authority input is an explicit privileged caller input, not discovered in the
graph. The caller is responsible for selecting it from trusted storage. This
version does not authenticate identities or signatures, retrieve evidence, check
citation relevance/completeness, or prove source truth. Hashes bind bytes, not truth.
A malicious caller controlling both inputs can make false declarations; report
flags must preserve this boundary. No historical report is revalidated/migrated.

Grant capabilities distinguish confirming source extraction, direct observation,
operator-supplied states and candidate enrichment. Scope/projection grants have
no wildcards. Operator origin identity must match its confirming authority.
Known empty states may pass only with explicit authorized confirmation; unknown
or partial data never become empty snapshots automatically. Candidate-only graphs
can use an empty authority input and contain no physical record or Delta.

## Acceptance and verification

- Missing/ambiguous origin, citation-only origin, unconfirmed origin, wrong
  authority/capability/scope/projection, stale graph binding and unauthorized
  enrichment are rejected, with negative fixtures and focused mutation tests.
- Source/direct/operator positive controls and explicitly confirmed empty states
  pass, with sourceTruthVerified, causationVerified and responsibilityVerified false.
- Source-only candidate passes without snapshots/Delta; old limitation fixture
  still passes under v1, and relabeling cannot silently select the new profile.
- Full existing quality gate, focused new tests, CLI/report tests, IR tamper
  controls, deterministic compile/export, TypeScript consumer checks and smoke.
- No NormLab code/tests, paid calls, deployment, responsibility execution or Linux
  portability work. Independent PR review remains required before merge.

## Roadmap

Plan and pin semantics; implement package/profile and admission; run negative and
compatibility gates; archive evidence/self-review and publish an independent PR.
