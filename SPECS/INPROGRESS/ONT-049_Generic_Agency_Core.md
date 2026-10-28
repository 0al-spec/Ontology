# ONT-049 — Generic Agency Core

Date: 2026-10-28. Priority: P1. Review subject: ONT-049.

## Problem and result

Motive, awareness, desired conditions, commitment to act, anticipation and outcome
attitude are independent. A domain model must express them before a downstream
normative profile can classify an event. The generic vocabulary must not contain
criminal-law classes or infer motivation from observed outcomes.

Deliver `org.0al.agency.core@0.1.0` / `agencycore`, importing exact events-core
0.2.0 and motivation-core 0.1.0, without changing either existing package. This is
draft vocabulary plus a narrowly executable source-attribution reference envelope,
not an extension of the legacy InstanceGraph admission profiles.

## Model

- `PropositionContent`: opaque content/condition on a situation or history; it
  asserts neither occurrence nor truth, and is never a Snapshot, Fact or Delta.
- `AgencyContext`: exactly one existing Interpretation or source-only candidate,
  optional actor RoleBinding reached from that view, contribution kind and
  separately supplied perspective/report times. Unknown actors/times stay absent.
- Five independent hypotheses: Awareness, Goal, Intention, Anticipation and
  OutcomeAttitude. Each has its own proposed/reviewed/rejected lifecycle and
  independent positive/negative source or operator support. Empty support means
  no supplied grounds; it does not become unawareness or a negative conclusion.
- Awareness targets exact same-scope MotivationHypothesis or PropositionContent;
  values aware / partly_aware / unaware / not_applicable. Inapplicability is an
  explicit attribution, never inferred from entity kind or missing knowledge.
- Goal targets content with seek / avoid / maintain. Intention means attributed
  commitment to the selected action/omission and may optionally link goals.
- Anticipation targets content with possible / expected / certain / not_anticipated.
  These describe attributed expectation, not objective probability or world truth.
- Attitude targets content with desires / accepts / opposes / indifferent. Different
  attitudes and motives may coexist; no default entailment between claim kinds.

## Consumer boundary

The TypeScript `agency-source-attribution/v1` reference consumer receives a strict
bounded envelope and a caller-provided finite reference index. It checks IDs,
graph/revision identity, selected-view actor role, motivation scope, source/operator
references and optional intention-to-goal links. Each assertion remains a hypothesis.
The caller owns validation of the underlying event graph and authenticity of its
index. No trust, factual truth, chronological truth, psychological applicability,
source relevance or graph-byte authentication is inferred by this consumer.

Generic compiler schemas have scalar fields, not value enums or relational
validation. They check shapes; the explicit consumer supplies typed value sets
and bounded cross-reference checks. Existing InstanceGraph validators continue to
reject the new namespace; historical reports are never silently reinterpreted.

## Acceptance and checks

1. Compile/check and repeat-generation parity, including exact dependency IR pins.
2. Generated SDK/object smoke and executable reference checks: source-only and
   unknown actor; nonhuman actor without psychological assumptions; unawareness
   distinct from no claim; unrealized goal and intention without inferred action;
   anticipated undesirable outcome; independent contested support and review.
3. Negative controls for foreign roles, motives, wrong graph/revision, duplicate
   IDs, missing content/goal/source/operator refs, invalid enums, invented physical
   observations and forged authority fields. Report time never fills perspective time.
4. Existing full Swift quality/coverage and portable/TypeScript gates; compiler
   implementation remains unchanged. Build/cache artifacts use verified TB5 locally.
5. Documentation includes neutral parking/machine/AI/community examples and a
   downstream-extension contract. It does not implement or advertise legal inference.

## Execution and ownership

Parent owns package/authoring/generated IR, documentation, FLOW, validation and Git.
One delegated worker owns only the new reference-consumer and TypeScript smoke files.
No paid inference, deployment, release, merge or NormLab mutation is part of this task.

After successful checks, archive this PRD and evidence, complete structured review,
publish a PR and report hosted CI for its exact head separately from local evidence.
