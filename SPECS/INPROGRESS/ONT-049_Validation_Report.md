# ONT-049 — Validation Report

Date: 2026-10-28. Verdict: **PASS — local package/reference-envelope scope**.
Hosted CI and external PR review are reported against the published head separately.

## Delivered

- Additive agency-core 0.1.0 draft: 10 classes, 24 relations, eight manual policies,
  staged authoring artifacts and deterministic ten-file TypeScript IR/SDK output.
- Exact event-core 0.2.0 and motivation-core 0.1.0 dependency IR/source pins, plus
  the new package IR pin in agency-source-attribution/v1.
- Domain-neutral unasserted proposition content, one actor/view context and five
  independent awareness/goal/intention/anticipation/attitude hypotheses. Motive
  remains upstream; no criminal-law taxonomy is introduced.
- Bounded strict TypeScript reference consumer and machine-readable constructed
  source-only envelope/index examples; generated object schemas remain distinct
  from the narrower consumer's enum/reference checks.

## Checks actually run

| Check | Result |
|---|---|
| `validate-draft` and `check` | PASS |
| Two fresh `compile --target typescript` runs vs committed generated baseline | All ten files byte-identical |
| Dependency/source/IR pins and imported endpoint navigation | PASS |
| `tools/swift-quality.sh`, `RUN_COVERAGE=1` | PASS: 159 tests, 0 failures; Swift line coverage 89.87% |
| Full `tools/portable-contract-smoke.sh` on native macOS | PASS: previous package/event/provenance controls plus new package |
| Fresh agency gate after contribution-kind correction | PASS |
| TypeScript strict typecheck and all SDK/runtime-object smoke scripts | PASS |
| Public agency consumer controls | PASS: 37 positive, 79 negative |

Build, cache, coverage, profiling and temporary artifacts used verified TB5
`Ontology-881ba79a220bd2df`. Node install/typecheck/smoke ran through the repository
gate in a source-copy build mirror on TB5; source checkouts stayed in place.
After final scoped changes the fresh source copy passed typecheck and smoke again.
Compiler implementation and Swift tests were unchanged. Existing event/profile
bytes were not modified. Expected negative event fixtures emit FAIL diagnostics
inside a successful smoke gate; those are rejection controls, not suite failures.

## Independent review and correction

A read-only independent review found one P2: the motivation reference index lost
`contributionKind`, allowing an action motive to be the awareness target of an
omission frame on the same view/actor. The index and comparison now require the
same action/omission kind; a negative control preserves view/actor and changes only
kind. Package policy/authoring and generated output were updated. The reviewer
confirmed this targeted correction by reading the implementation; the parent ran
the integrated gates. This is not a claim that the reviewer ran tests.

## Acceptance boundary

Success proves only declared object/reference/index agreement for this explicit
envelope. The caller supplies the reference index and owns underlying event-graph
validation. Index origin/authentication, semantic relevance, mental-state truth,
chronology, physical outcome satisfaction and normative classification are not
verified. All five authority flags remain false.

Unknown actor/time/mental properties are not defaulted; explicit unawareness and
inapplicability remain propositions with independent support. Physical snapshots,
Delta, causal hypotheses and authority fields are rejected by the envelope.
Existing InstanceGraph profiles still admit no agencycore/motivcore nodes; no
universal graph validator, new Lean proof, NormLab integration, live model run,
deployment or release was performed.

Next: review this generic vocabulary/consumer boundary, then define any NormLab
domain mapping as a separate pinned profile with additional grounds.
