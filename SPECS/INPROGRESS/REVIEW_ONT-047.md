# REVIEW REPORT — ONT-047 Snapshot Provenance And Enrichment Profile

**Date:** 2026-10-27
**Scope:** origin/main..464ec36
**Reviewer:** Codex /root self-review; independent PR review pending

## Summary verdict

Approve for independent review. No remaining blocking or newly actionable finding
in this self-review. FOLLOW-UP is skipped: the offline consumer selection/export
boundary remains ONT-045; cryptographic identity/truth claims are explicit non-goals.

## Correctness and architecture

- Explicit selection precedes exact IR validation. Old eventcore-v1 remains the
  default; new graph/authority pins are checked without automatic migration. The
  old IR/SDK, consumer baseline and limitation fixture are unchanged.
- Shape, reference and core event checks run before provenance admission. The
  package-internal context cannot be used as a public unpinned library interface.
  Existing checks retain registry/episode identity, observation alternatives,
  independent fact polarity, exact Delta and temporal/hypothesis scope.
- Every new snapshot has one typed origin and one matching confirmation. Origins
  have one owner; repeated/ambiguous/orphan origins and wrong confirmation targets
  fail. Source presence alone, a reviewed proposal, or an in-graph field grants
  no capability. Operator identity/rationale and direct time/clock are explicit.
- The separately supplied authority document binds exact graph bytes and the
  profile definition. Capability, scope and projection gates apply to confirmation
  and independently to each enrichment. Known snapshot identity and partial facts
  survive enrichment; interpretation resolution cannot bypass the admitted edge.
- Unavailable candidates need no states/record/Delta. Empty complete states can
  pass only with explicit origins/confirmation. No synthesis or approval generation
  occurs in validation. Failed reports have no positive confirmation status.

## Security, state and performance boundaries

The authority input is trusted caller configuration, not an authenticated message.
Its protection/selection must happen outside the graph. A caller controlling both
inputs can lie. Sources/artifacts are not fetched or semantically compared;
completeness and origin are admitted declarations, not factual truth. Reports keep
sourceTruthVerified, causationVerified, responsibilityVerified and authority
identity authentication false. Byte hashes do not authenticate people or a binary.

The same bounded UTF-8/no-BOM/duplicate-key/depth checks cover both JSON inputs.
All arrays are finite and unknown fields/capabilities fail. Validation is offline
and synchronous; this review makes no throughput/latency guarantee at input maxima.
There are no shared mutable caches, network calls or historical receipt rewrites.
Any byte change requires reconfirmation; this conservative profile does not claim
minimal support-sensitive reuse of authority decisions across graph revisions.

## Evidence

Full quality passes 158 Swift tests (143 existing + 15 new), lint/format/import
checks; configured TOTAL line coverage 89.87%, region 79.32%. New rule files have
mutation controls, including source/operator/capture/authority alternatives.
18 static cases have four expected passes and fourteen expected failures. The
legacy smoke retains the original expected-pass limitation and baseline bytes.
TypeScript object/runtime/type checks pass. Fresh package and three consumer
artifacts match generated baselines; reports are deterministic. No NormLab code,
Lean proof, paid inference, deployment or Linux support claim is included.

## Corrections during self-inspection

Preserved the old hypothesis diagnostic and CLI success wording explicitly,
added a regression assertion, and exposed the new selector in CLI help. The old
profile exposes no provenance definition pin. No new actionable issue remains.

## Next steps

Archive this review and publish an independent PR based on main. Obtain hosted
CI and independent review on its actual head before merge. Reconcile shared
Workplan/next.md bookkeeping with ONT-044 PR #68 when those independent changes
are merged; do not infer a dependency on its responsibility package.
