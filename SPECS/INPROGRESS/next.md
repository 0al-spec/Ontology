# Selected: ONT-047 — Snapshot Provenance And Enrichment Profile

**Priority:** P2 (explicit user selection)
**Dependencies:** ONT-043, merged PR #67 (`0b69253`)
**Status:** Selected; independent of ONT-044 PR #68

## Goal

Add a separately pinned event-core revision and provenance-aware instance profile.
Keep source presence, trusted origin confirmation and factual truth distinct.
Old eventcore-v1 reports and its expected-pass limitation fixture remain unchanged.

## Next Step

Plan ONT-047, implement typed snapshot origins and explicit authority-bound
candidate enrichment, then run compiler, runtime, negative and compatibility gates.
NormLab physical candidates may stay source-only without StateSnapshot or Delta.
No NormLab edits, deployment or historical migration are part of this task.

## Recently Archived

- ONT-043: merged PR #67, structural validation with an explicit provenance limitation.
- ONT-042: merged PR #66, draft event vocabulary.
- ONT-041: merged PR #65, proposal and unknown-observation clarification.
