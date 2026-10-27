# REVIEW REPORT — ONT-044 Draft Responsibility Profile Package

**Date:** 2026-10-27
**Scope:** `origin/main..11e07e8`
**Reviewer:** Codex /root self-review; independent PR review pending

## Verdict

Approve for independent review as a draft vocabulary/source mapping. No remaining
blocking or newly actionable finding in this self-review. This is not an executed
responsibility graph, adapter, proof backend or legal rules package. FOLLOW-UP is
skipped; ONT-045 and ONT-047 already own consumer/provenance decisions.

## Reviewed boundaries

- ResponsibleRelation names duty bearer/counterpart independently of actor and
  selected human anchor. AttributionContext derives event/role scope through one
  imported Interpretation; it cannot supply replacement event identifiers/states.
- Requirement alternatives are typed action/state references. Applicability and
  origin/continuation/termination remain distinct conditions. Deadline metadata
  does not create deadlineElapsed support.
- GroundAssessment has one owner and separate positive/negative support links,
  without duplicate truth-state storage. Source citations and explicit uncited
  operator assertions use different types. Workflow review is not support truth.
- ResponseRule has separate trigger and authority conditions. ResponseCandidate
  is independent of the R3 effect marker, with unresolved responder/recipient
  retained rather than defaulted from actor/counterpart.
- Mapping is pinned to actual NormLab main and exact action/omission premise
  order/polarity plus the ten-element context order. Bound HumanContext/propose
  is the consumer boundary; Profile.proposeUnbound is not an admission path.
- Duty-bearer/duty/response-rule IDs and clockKey are not independent R3 literal
  slots. Generic requirement-action matching and StateRequirement semantics are
  not certified by that profile. Source-only candidates are not forced into
  bound assessment contexts.
- CertificateReference describes external artifacts and mapping provenance.
  Tree preservation concerns literal/rule values; Profile.check remains sensitive
  to new opposing grounds or negative effect. No source/trace identity shortcut.

## Evidence

Actual staged draft/package validation succeeds. Two fresh final compilations
match all ten files and the generated baseline:
`sha256:f1540b9d7362677910ab02bc1844edc73bc956306059965ba168bf865a3a39c8`.
Four imported class references and the event vocabulary pin are checked against
actual event-core IR. Existing compiler Sources/Tests, event-core and graph
baselines remain unchanged.

The full quality gate passes 143 existing Swift tests, format/lint/import checks,
with configured line coverage 89.58% and region 78.41%. New TypeScript runtime
smoke verifies object fields/discriminators/missing-field controls; it does not
check relation cardinality, enum strings, semantic relevance, human proof or
nonempty rationale. Existing graph fixture/export smoke still passes.

NormLab source was read and compared, not executed or modified. The conceptual
examples and mapping constraints are source-derived expected cases, not new
experimental results or model accuracy measurements.

## Corrections during self-inspection

Added explicit response authority, repeated generation/structural checks, and
documented the unmapped duty-action/state requirement boundaries. All policies
remain manual and package approval draft. No additional backend/task is inferred
from a successful package check. Current eventcore-v1 admits no respcore nodes.

## Next step

Archive this review and publish the package PR. Inspect hosted CI and independent
review on its actual head before merge. ONT-045 must agree a consumer contract
and create/link its canonical NormLab Issue before cross-repo implementation.
