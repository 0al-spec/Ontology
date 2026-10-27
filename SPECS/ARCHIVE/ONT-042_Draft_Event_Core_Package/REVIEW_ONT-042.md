# REVIEW REPORT — ONT-042 Draft Event Core Package

**Date:** 2026-10-27
**Scope:** ONT-042 implementation and PR #66 review fixes
**Reviewer:** Codex /root self-review; independent review supplied in chat

## Verdict

Approve the draft package for PR review. No remaining blocking issue was found
in this self-review. The verdict covers vocabulary/structural compilation and
its documented boundaries, not a checked physical event graph.

## Reviewed contracts

- Package remains draft with one RecordedEvent governing concept. General
  Entity actors and interpretation-owned role bindings introduce no human-only
  restriction or automatic attribution/responsibility.
- Event/interpretation candidates preserve source descriptions without requiring
  fabricated states. Records link directly to complete supplied StateSnapshots;
  availability belongs only to candidates, without a redundant complete flag.
- EventRegistry gives recordKey an explicit local revision scope. Delta states
  derive through one owning record, while cause/effect records derive through
  their Interpretations. Instance integrity and exact Delta remain ONT-043 work.
- The shared proposal review lifecycle has no promotion transition or causal
  truth implication. Explicit provenance relations allow later enrichment into
  separate records/interpretations.
- SourceAssertion uses the documented DomainEntity foundation. Strings/instance
  cardinality, source relevance, interval ordering and graph invariants are
  explicitly outside the present compiler/object-schema guarantee.
- All five policies use manual enforceability. Responsibility/parking rules,
  whole-graph validation and Lean code generation were not added.

## Validation

Draft validation and package check pass. Two independent final compilations are
byte-identical for ten artifacts and match the committed baseline, source digest
`sha256:be771a8caa40e1ac23cb11fdb2f12a6ef7f8e166b12ef46f9d7d022a23944424`.
The unchanged compiler's baseline quality/coverage run passed 116 existing tests;
it was not repeated for these vocabulary/TS smoke changes. Generated event-core
TypeScript typecheck and both examcalc/events-core runtime smoke now pass on the
revised package. These do not establish event-instance semantics.

CI explicitly validates the new authoring/package bytes and generated baseline;
TypeScript's existing check now includes the generated event-core files. LLVM
profiles from the CI package CLI are directed to runner temporary storage.
Hosted execution must be read on the published head.

## Corrections made during review

Added explicit candidate enrichment provenance and replaced an assumed Evidence
foundation with DomainEntity. Final draft/check/compile and TypeScript checks
were repeated after the data changes. A local coverage CLI profile initially
written in the checkout was moved byte-identically to TB5; profile routing and
the ordinary non-coverage CLI were restored and checked.

Independent review in chat identified record/state availability, unbound Delta,
missing registry scope, missing causal endpoint roles, free-form hypothesis
review and missing runtime schema execution. The package/SDK now declare direct
snapshots, EventRegistry, record-owned Delta, endpoint Interpretations and shared
ProposalReview. Fresh compiler/determinism/type/runtime checks pass. Personal
storage-routing prose was removed from the package README.

## Follow-up

ONT-043 acceptance now explicitly covers registry membership/uniqueness, direct
states, exact Delta, endpoint interpretation resolution, lifecycle and strict
wire handling. ONT-044 remains the responsibility-profile task. ONT-046 separately
tracks the Linux portability gap reported by the reviewer; no Linux support is
claimed from that reviewer's patched copy. Assess hosted CI and independent
re-review on the revised PR head before starting the next task.
