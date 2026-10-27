# Bounded NormLab mapping — source contract, not an adapter

The [machine-readable draft](profiles/normlab-r3-v1.json) pins actual NormLab main
`e8041c937f28d3644d4df3680db5d81f0cff8ace`. The repository's remote main was checked
and the local Lean files were compared with that committed version. Source was
read only; no NormLab tests or new Lean proofs were run for ONT-044.

## Context first

The formal entry is
[HumanContext / bound check/propose](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/ActionAttribution.lean#L523),
or the typed
[parking entry](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/ParkingAttribution.lean#L10).
Both require a RegisteredEvent and an Interpretation of that exact record.
Profile.proposeUnbound is a research helper and is not a consumer admission path.

The generic package stores one contextInterpretation link; record, registry,
episode, action, interval and roles derive from it rather than duplicate fields.
The future adapter must resolve a single actor/target and optional instrument,
preserve graph/registry identity and construct the following literal argument
tuple in exactly the order used by Profile.signature/arguments:

| Argument | Proposed source / required binding |
|---|---|
| actor | Interpretation's actor RoleBinding → explicit u.Entity mapping. |
| humanAnchor | contextHumanAnchor → Human u with separate IsHuman proof. |
| target | Interpretation's target RoleBinding → explicit u.Entity mapping. |
| instrument | Zero/one instrument binding → Option u.Entity. |
| episode | Record's Episode → explicit u.Episode mapping. |
| action | Record's ActionKind → explicit u.Action mapping. |
| start, finish | Supplied normalized natural times from that record. |
| eventId | Injective registry-local record identity → Nat, backed by registration. |
| interpretationId | Injective scoped interpretation identity → Nat. |

Missing/plural roles and unresolved human status stay unsupported candidates.
Do not use lossy Number/parseInt conversion of arbitrary identity strings.
Clock units/normalization must be chosen explicitly: clockKey is not part of the
Lean literal tuple. The typed registry parameter carries registration outside
that tuple; a free serialized Profile.Scope does not supply it.

## Conditions, predicates and signs

GroundAssessment derives its context from groundAssessmentOwner and its condition
from groundCondition. Condition identities below are profile-specific descriptors;
meaningRef must resolve to this pinned mapping. Positive/negative support links
map to literal signs only after explicit relevance, scope and evidence selection.
Workflow reviewed does not prove that a quote means the requested condition.

| conditionKey suffix (prefix normlab-r3:) | Profile.Predicate | Action premise | Omission premise |
|---|---|---|---|
| attributed | attributed | positive | positive |
| performed | performed | positive | negative |
| required | required | — | positive |
| deadlineElapsed | deadlineElapsed | — | positive |
| capable | capable | — | positive |
| exception | exception | — | negative |

These lists exactly follow
[Profile.grounds](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/ActionAttribution.lean#L88).
Performed/nonperformance concerns the selected human anchor's contribution;
attributed explicitly connects that contribution to the actor. It does not
silently make the actor human or identify the generic duty bearer.

For the same owner/condition, reject duplicate GroundAssessment nodes unless a
reviewed aggregation contract explicitly combines all signs. Never choose only
a favorable duplicate. Keep accepted opposing supports; pending/rejected claims
need explicit mapping decisions and cannot silently become positive or negative
facts. Cited and uncited operator assertions remain separately labelled even
when both map to the same literal value.

## Admission, outputs and unmapped metadata

[Profile.check](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/ActionAttribution.lean#L124)
requires start <= finish; each requested literal present without its opposite;
the negative effect absent; and Tree.verify of the fixed certificate against an
authorized catalog containing the exact profileRule for that mode/context.
Having an eligibility fact alone or an unrelated rule/tree is insufficient.

| Mode | Eligibility symbol | Effect marker |
|---|---|---|
| action | actionGrounded+ | relationActive+ |
| omission | omissionGrounded+ | breachRecorded+ |

ProfileConsequenceCandidate can describe these markers, with the exact assessment
and external CertificateReference. It is still a proposal. Neither marker
certifies generic duty applicability or imposes the ResponseRule's action.

Current R3 Scope has **no independent duty bearer, duty ID, response-rule ID or
clockKey slot**. Deadline.dueAt does not compute deadlineElapsed. A generic duty
claim needs separately reviewed applicability and any duty-bearer/anchor alignment;
these are not extra guarantees hidden inside required+. In particular actor may
be a car/community while anchor is a person. Duty bearer is not defaulted to either.
ResponseCandidate requires its own rule, trigger, authority and recipient policy.

R3 also does not compare ActionRequirement.actionRequirementKind to the context's
action. For a generic duty claim, that matching decision is explicit and separate.
StateRequirement has no direct state-condition slot in this action/omission
profile; interpreting a required state as an action needs another reviewed mapping.
Performed alone does not prove that an arbitrary required StateRequirement holds.

The existing
[ParkingRuntime recordReviewedFindings](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/ParkingRuntime.lean)
records an operator's review event. Its actor/anchor is the operator; it does not
prove the driver's parking act. Source-only fabula candidates lack physical
before/after states and must not be coerced into a registered physical record.
The eventcore-v1 provenance limitation remains; ONT-047 and the ONT-045 exporter
requirements are not discharged by this mapping document.
When only a source-level InterpretationCandidate exists, retain it as a candidate
outside the bound assessment path. Do not invent an AttributionContext/event to
fit ResponsibilityAssessment's required interpretation link.

## Support updates and certificates

[Tree.usedFacts/usedRules and deletion theorems](https://github.com/SoundBlaster/NormLab/blob/e8041c937f28d3644d4df3680db5d81f0cff8ace/lean/DerivationTraces.lean)
refer to literal/rule values. CertificateReference's selected ground/source-support
IDs describe an external mapping layer, not those Lean lists themselves.

| Update | Required interpretation |
|---|---|
| Delete an unused mapped literal/rule | A selected Tree can survive under the pinned preservation theorem's assumptions. |
| Delete the only used support | Remap; the missing required literal invalidates that certificate/profile. An unrelated record cannot fill the gap. |
| Delete one of two sources for the same literal | The literal may remain via the second source; update provenance and recheck, without pretending the old source receipt is current. |
| Add an opposite requested literal | Tree.verify may remain valid, while Profile.clear/Profile.check rejects the conflicting premise. |
| Add the negative selected effect | Profile.check rejects, even if its fixed eligibility Tree still verifies. |
| Select an alternate certificate | Reverify its target, used facts and authorized rules; do not claim all conclusions are invalid merely because one support was deleted. |

This is a source-derived contract. Package/object-schema validation does not
perform these steps, validate citations, construct Human values or call Lean.
