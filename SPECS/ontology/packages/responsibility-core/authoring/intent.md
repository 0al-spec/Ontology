# Responsibility core — authoring intent

**Intent ID:** ont-044-responsibility-profile
**Package:** org.0al.responsibility.core@0.1.0 / respcore / draft
**Source:** ONT-044 workplan, merged event-core and read-only NormLab main
`e8041c937f28d3644d4df3680db5d81f0cff8ace`.

## Domain and governing concept

ResponsibleRelation is a claimed conditional duty relation. Its duty bearer and
counterpart are explicit entities. Actor/target/instrument derive independently
from a recorded-event Interpretation; the selected human anchor is another role.
Do not infer these identities from ownership, launch/origin or a role label.

DutySpecification declares applicability, typed action/state requirement and an
optional deadline. Origin, continuation and termination conditions are separate,
so a relation can persist without its originator's current action. Conditions
are opaque semantic references, not authored executable expressions.

## Evidence and behavior

GroundAssessment has one owning assessment and one condition. Its independent
positive/negative support links represent unknown, positive, negative and conflict
without a cached status field. CitedSupport retains a SourceAssertion; explicitly
uncited OperatorSupport retains author/rationale. Both require separate semantic
relevance and polarity decisions before becoming mapped Lean literals.

AssessmentReview uses unreviewed → reviewed/rejected. This records workflow;
reviewed does not establish source truth, profile admission or responsibility.
ProfileConsequenceCandidate and ResponseCandidate remain proposals. ResponseRule
is a separate inert conditional template; breachRecorded is not an imposed fine.

## Existing profile mapping and gaps

The pinned NormLab profile requires two action premises or six omission premises.
It binds the whole actor/anchor/target/instrument/episode/action/time/event/view
tuple. Human status needs an IsHuman proof and the public API needs registration.
Duty bearer, duty/rule IDs and clockKey are not separate Lean scope arguments;
the mapping must name these gaps and the required external alignment/time policy.

Tree preservation is about used mapped literals/rules, not source support IDs.
Deleting a cited support may require remapping even if another source supplies
the same literal. Profile.check must run again after changes: opposite premises
or a negative effect can reject it while the generic Tree remains valid.

## Boundary

Keep compiler sources, existing packages, exact eventcore-v1 profile and NormLab
unchanged. This task authors a vocabulary, object contracts and a source-grounded
mapping; it creates no responsibility InstanceGraph validator, profile evaluator,
Lean adapter or legal rule corpus. Examples are conceptual, not evaluated cases.
All policies remain manual and approval remains draft. Snapshot provenance stays
ONT-047; ONT-045 must retain source-only parking candidates without invented states.
