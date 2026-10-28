# Next Candidate: ONT-045 — NormLab Offline Event Graph Pilot

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-043 and ONT-044; ONT-047 is available for explicitly selected provenance admission
**Status:** Not selected; agree bounded export contract and canonical consumer Issue first

## Description

Agree a read-only export of one saved parking episode, preserving the original
source/revision/speaker, selected findings, uncertainty and saved norm receipt.
Follow the [workplan](../Workplan.md#ont-045-normlab-offline-event-graph-pilot).

## Next Step

Inspect existing NormLab Issues, including deferred/closed ones, and create/link
its canonical consumer Issue before implementation. Agree the consumer wire
contract; this Ontology package work did not start cross-repo integration.

The legacy eventcore-v1 profile admits only its pinned event vocabulary;
responsibility objects need an explicitly agreed consumer contract. They cannot
silently become a supported graph profile. Separate the operator review event
from physical fabula candidates and preserve missing physical states as source-only,
without fabricated snapshots or Delta. Test the exporter itself.

If a consumer deliberately selects events-core 0.2.0/eventcore-provenance-v1, it
must supply a separately trusted graph-bound authority input and test its own
admission boundary. Source presence and admitted origin do not prove truth.
There is no automatic upgrade of eventcore-v1 exports or historical receipts.
ONT-046 remains the separate Linux portability task. No paid inference,
historical receipt rewrite or deployment is required for the offline pilot.

## Recently Archived

- ONT-044: draft responsibility vocabulary and pinned source mapping, PR #68.
- ONT-047: typed snapshot origins and scoped enrichment admission, merged PR #69; 159 tests and 18 static cases passed.
- ONT-043: merged PR #67, frozen structural v1 contract and explicit limitation.
- ONT-042: merged PR #66, draft 0.1.0 event vocabulary.
