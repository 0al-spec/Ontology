# Current Task: ONT-050 — Action Model Template

**Status:** Selected; documentation/skill/template scope.
**Review subject:** ONT-050.
**Base:** ONT-049 branch at `a170fce`; dependent PR layer, no change to #73.

Capture transition-based goal evaluation and the image-encoding interpretation,
then validate reusable guidance and publish a separate PR. No app implementation,
compiler/profile change, integration, merge or release is included.

# Next Candidate: ONT-045 — NormLab Offline Event Graph Pilot

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-043 and ONT-044 merged; ONT-047 is available for explicit provenance admission
**Status:** Not selected; agree bounded export contract and canonical consumer Issue first

## Description

Agree a read-only export of one saved parking episode, preserving original
source/revision/speaker, selected findings, uncertainty and saved norm receipt.
Follow the [workplan](../Workplan.md#ont-045-normlab-offline-event-graph-pilot).

## Next Step

Inspect existing NormLab Issues, including deferred/closed ones, and create/link
its canonical consumer Issue before implementation. Agree the consumer wire
contract; this Ontology package work did not start cross-repo integration.

Keep operator review events distinct from physical fabula candidates. Missing
physical states remain source-only, without fabricated snapshots or Delta.
A consumer choosing events-core 0.2.0/eventcore-provenance-v1 must select and
protect its authority input and test its own export/admission boundary.
Source presence and admitted origin do not prove factual truth.

ONT-048 adds an independently reviewable motivation-core draft. Motive accounts
are optional, broad reasons for any Entity; conscious intention is not required.
If the pilot includes them, agree an explicit consumer contract: no existing
instance profile admits motivcore/respcore nodes or automatically validates their
manual policies. Review, evidence and truth stay distinct; motives do not alter
the saved norm result or imply physical observations. ONT-046 delivers Linux source portability separately; pin a version containing
that port when adopting it. No paid inference or deployment is needed for this pilot.

## Recently Archived

- ONT-049: generic agency vocabulary and bounded reference consumer; local package/Swift/TypeScript gates pass, PR review/CI separate. This does not start a normative profile or NormLab integration.

- ONT-046: Linux source portability, shared baseline gate and CI matrix; local macOS/Linux checks pass.

- ONT-048: merged PR #70; included in source release 0.1.0. Follow-up: GitHub Issue #71.
- ONT-044: responsibility draft, merged PR #68.
- ONT-047: snapshot provenance, merged PR #69.
- ONT-043: structural event profile, merged PR #67.
