# Next Candidate: ONT-045 — NormLab Offline Event Graph Pilot

**Priority:** P1
**Dependencies:** ONT-043 and ONT-044; ONT-047 is available for explicit provenance admission
**Status:** Not selected; ONT-044 PR #68 and ONT-047 hosted review/CI remain pending

## Next Step

Review the independently based ONT-047 change and ONT-044 PR #68 before selecting
integration work. Agree the consumer wire contract and create/link the canonical
NormLab Issue before any cross-repo implementation.

A source-only pilot may preserve missing physical states without record/Delta.
If a consumer deliberately selects events-core 0.2.0/eventcore-provenance-v1, it
must supply a separately trusted graph-bound authority input and test its own
export/admission boundary. Source presence and admitted origin do not prove truth.
No automatic upgrade of eventcore-v1 exports or historical receipts is implied.
ONT-046 remains the separate Linux portability task.

## Recently Archived

- ONT-047: typed snapshot origins and scoped enrichment admission, 158 tests and 18 static cases locally pass; independent review pending, 2026-10-27.
- ONT-043: merged PR #67, frozen structural v1 contract and explicit limitation.
- ONT-042: merged PR #66, draft 0.1.0 event vocabulary.
