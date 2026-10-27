# REVIEW REPORT — ONT-043 Instance Graph Contract And Validation

**Date:** 2026-10-27
**Scope:** `origin/main..6682040`
**Reviewer:** Codex /root self-review; independent PR review pending

## Verdict

Approve for independent review as a bounded structural validator. No remaining
blocking or newly actionable finding in this self-review. This is not a source,
physical-causation or responsibility proof and does not replace the NormLab Lean
profile. FOLLOW-UP is skipped; ONT-044/045/046 already track the next boundaries.

## Correctness and architecture

- Graph shape validation precedes index construction, so duplicate ids or invalid
  collections cannot reach the unique-key map. Reference/cardinality checks stop
  malformed edges before profile traversal. Unavailable decisions fail closed.
- Package-internal rules receive only the compiler's exact hash-checked event-core
  IR. External consumers cannot use an unpinned public rule context. Policy prose
  is inert; only the named selected profile executes.
- Record identity is unique inside one explicit registry revision. States are
  direct references; interpretations do not own replacement states. Two readings
  share a record, while a duplicate record key is rejected.
- Candidate known/unknown/partial states are mutually exclusive. Mechanical
  records cannot use declared review/normative projections. Snapshot completeness
  and domain labels remain exporter declarations, not inferred factual truth.
- Delta compares finite propositionKey/polarity sets from its owning record;
  duplicate nodes/values, unrelated differences and nonempty changes for equal
  snapshots fail. The validator does not itself coerce unknown observations into
  empty snapshots; external unsupported enrichment remains a provenance gap.
- Hypotheses preserve both endpoint Interpretations, registry/episode/clock and
  bounded interval ordering. Overlap and opposed support are positive controls;
  review state never establishes causal truth or transfers responsibility.
- Sources preserve speaker and UTF-16 quote spans. Cross-source semantic relevance,
  authenticity and legal interpretation are explicitly unverified.

## Evidence and limits

Initial red run: nine groups, 16 expected missing-rule failures. Final full quality
gate passes 137 tests (21 new), with configured llvm-cov line 89.48%, region 78.18%.
Existing format/lint/import checks and examcalc/events-core runtime smoke pass.
Generated TypeScript checks both valid shapes and expected compilation errors.

Actual CLI tests cover reports, failure exit status, exact IR pin tampering and
deterministic export. The fixture smoke independently exercises the binary and
checks committed generated output. Same claimed input revision with altered data
produces a different graphSHA256. Existing package YAML/IR/SDK is unchanged.

The input has explicit byte/depth/collection bounds and references are indexed.
No maximum-size latency/RSS benchmark is claimed; this is an offline CLI, not a
network service. No hosted inference, runtime deployment, persistent registry,
new proof backend or Linux portability change was made. A hash binds the report
to bytes but does not enforce external history or storage immutability.

## Corrections before this review

Made the low-level context package-internal, made an unavailable decision an
error, and added exact input hashing with a regression test. Full quality was
rerun after these source changes. The test binary path is supplied by the quality
gate so the CLI integration uses that gate's checkout/scratch binary.

## Next step

Archive this review and publish the ONT-043 PR. Read hosted CI and independent
review on its actual head before merge; ONT-044 remains the next sequential task.

## Independent review correction — 2026-10-27

The original self-review missed the BOM/UTF-16 scanner bypass and overstated the
missing-state acceptance criterion. Independent review found both. Review fixes
restrict input to unmarked UTF-8, require complete scanning, enforce unique
Episode.scopeKey and gate temporal order on valid comparable intervals.

The acceptance claim is narrowed rather than changing the vocabulary/pin in
this PR. A limitation fixture intentionally passes unknown-candidate enrichment
with unsupported empty snapshots; snapshot provenance is unimplemented and
tracked in ONT-047. ONT-045 must test that its exporter preserves source-only
parking data and does not manufacture states. The selected structural slice is
complete; provenance and factual origin checks are not.
