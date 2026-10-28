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
the saved norm result or imply physical observations. ONT-046 remains separate
Linux portability work. No paid inference or deployment is needed for this pilot.

## Recently Archived

- ONT-048: draft motivation vocabulary, IR/SDK and examples; local checks pass, PR review pending.
- ONT-044: responsibility draft, merged PR #68.
- ONT-047: snapshot provenance, merged PR #69.
- ONT-043: structural event profile, merged PR #67.
