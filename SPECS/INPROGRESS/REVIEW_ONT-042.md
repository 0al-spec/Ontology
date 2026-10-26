# REVIEW REPORT — ONT-042 Draft Event Core Package

**Date:** 2026-10-27
**Scope:** `origin/main..bb0f8ff`
**Reviewer:** Codex /root self-review; independent PR review pending

## Verdict

Approve the draft package for PR review. No remaining blocking issue was found
in this self-review. The verdict covers vocabulary/structural compilation and
its documented boundaries, not a checked physical event graph.

## Reviewed contracts

- Package remains draft with one RecordedEvent governing concept. General
  Entity actors and interpretation-owned role bindings introduce no human-only
  restriction or automatic attribution/responsibility.
- Event/interpretation candidates preserve source descriptions without requiring
  fabricated states. StateObservation availability and StateSnapshot contents are
  distinct; exact Delta remains a manual policy until ONT-043.
- Candidate review lifecycle has no promotion transition. Explicit provenance
  relations allow later enrichment into separate records/interpretations.
- SourceAssertion uses the documented DomainEntity foundation. Strings/instance
  cardinality, source relevance, interval ordering and graph invariants are
  explicitly outside the present compiler/object-schema guarantee.
- All five policies use manual enforceability. Responsibility/parking rules,
  whole-graph validation and Lean code generation were not added.

## Validation

Draft validation and package check pass. Two independent final compilations are
byte-identical for ten artifacts and match the committed baseline, source digest
`sha256:7e914e9bc22142ce888d8d92ed48713c3e3a2b31dea635daf9c5417dc4bf8181`.
The unchanged compiler quality/coverage gate passes 116 existing tests; generated
event-core TypeScript typechecks. Existing examcalc runtime smoke also passes.
These do not establish event-instance semantics.

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

## Follow-up

Existing ONT-043/044 tasks already own the unresolved wire format, enum/reference
validation and responsibility profiles. No duplicate task is needed; FOLLOW-UP
is skipped under FLOW. Archive this self-review, publish the PR, then assess CI
and independent review before starting the next task.
