# Responsibility core — draft 0.1.0

`org.0al.responsibility.core@0.1.0` (`respcore`) declares conditional duties,
scoped grounds and candidate responses. It imports the unchanged
[event-core 0.1.0](../events-core/README.md) vocabulary and remains draft.

## Roles and conditional relations

The governing ResponsibleRelation has an explicit duty bearer, counterpart and
DutySpecification. Actor/target/instrument derive through AttributionContext →
event-core Interpretation → registered record. The optional contextHumanAnchor
selects an entity candidate; a Lean Human still requires a proof of IsHuman.
No role is inferred from another role, ownership, or who launched an agent.

DutySpecification has one typed ActionRequirement or StateRequirement, explicit
applicability Condition and optional Deadline. Conditions carry identity/meaning
references, not executable code. Deadline metadata does not establish elapsed
time. Relation origin, continuation and termination have separate conditions;
no current action by the originator is required merely to describe persistence.

## Grounds, review and proposed results

A GroundAssessment derives scope/profile from one owning ResponsibilityAssessment
and names one condition. Support is represented once, through independent links:

| Positive supports | Negative supports | Reading |
|---|---|---|
| None | None | Unknown. |
| Present | None | Positive support. |
| None | Present | Negative support. |
| Present | Present | Conflict; retain both. |

There is no duplicate truthState field. CitedSupport links to exact SourceAssertion
provenance/speaker; OperatorSupport is an explicit uncited claim with author and
rationale. Neither citation identity nor workflow review proves semantic relevance,
polarity, human status or factual truth. Unknown participants stay unresolved.

AssessmentReview records unreviewed → reviewed/rejected only. A
ProfileConsequenceCandidate is a proposed profile marker. A ResponseCandidate
has a separate ResponseRule/assessment; its responder/recipient can be unresolved.
ResponseRule has separate trigger and authority conditions; the authority of a
selected responder is not inferred from the triggering event or counterpart.
Neither a reviewed assessment nor breachRecorded is an imposed sanction.

CertificateReference describes an external artifact and selected grounds/supports;
it is not a verified proof. Source support IDs differ from Lean literal/rule
values. Removing a source may leave an alternate support for the same literal;
remapping and profile rechecking remain necessary. Adding an opposite ground or
negative effect can reject Profile.check even while Tree.verify remains valid.

## NormLab mapping and explicit gaps

The [mapping contract](profiles/normlab-r3-v1.json) and
[mapping notes](NORM_LAB_MAPPING.md) pin NormLab main to
`e8041c937f28d3644d4df3680db5d81f0cff8ace`. It was verified against actual source;
NormLab files, runtime and ledger were not changed and its tests were not run.

The omission profile needs attributed+, required+, deadlineElapsed+, capable+,
exception- and performed- in exactly the same context. Missing performance
support is not nonperformance. Opposite support blocks a clear premise.

Current R3 has no independent dutyBearer, duty ID, response-rule ID or clockKey
argument. Generic duty metadata and time-normalization assumptions are not
certified by that profile. actionGrounded/omissionGrounded and
relationActive/breachRecorded are bounded profile symbols, not proof of generic
duty applicability or legal liability. The mapping describes these limits rather
than silently aliasing duty bearer to actor/anchor.

## What is validated

The [staged intent](authoring/intent.md),
[classification](authoring/intent-classification.yaml),
[candidate model](authoring/product-ontology-draft.yaml),
[critique](authoring/draft-critique.yaml) and
[competency questions](authoring/competency-questions.md) precede package assembly.
They were curated by the same author without additional model calls or delegated
authoring. Confidence/rubric values are subjective estimates, not accuracy metrics.

The [authoring YAML](authoring/domain-ontology-package-draft.yaml) and
[assembled package](domain-ontology-package.yaml) are byte-identical. Actual
ontologyc draft/check validates package structure; compilation emits ten
deterministic [IR/TypeScript files](generated/). Object schemas check primitive
fields/discriminators and required fields. Imported concept existence is checked
against the actual event-core IR during delivery, rather than assumed from a
namespace string.

All eight policies are manual. This package does not implement responsibility
instance validation, support relevance/polarity validation, clock normalization,
rule execution, a Lean adapter or a new proof backend. The existing eventcore-v1
InstanceGraph validator accepts only its pinned event-core vocabulary; adding this
package does not expand that runtime profile. Enum-like string fields, relation
cardinality, scope/owner matching and semantic mapping require a consumer check.
Generated string schemas require field presence/type, but do not enforce
nonempty rationale text or the mode/polarity enums described by the mapping.

[Examples](examples.md) are conceptual outlines with outcomes explained from the
pinned source, not executed backend cases. No laws, parking amounts or sanctions
are encoded. ONT-045 owns the later offline consumer pilot; ONT-047 owns snapshot
provenance. Source-only parking data must not become invented physical snapshots.

## Reproduction

With ontologyc built using your configured build/cache location:

```sh
ontologyc validate-draft SPECS/ontology/packages/responsibility-core/authoring --out /path/to/draft-report.yaml
ontologyc check SPECS/ontology/packages/responsibility-core/domain-ontology-package.yaml
ontologyc compile SPECS/ontology/packages/responsibility-core/domain-ontology-package.yaml --target typescript --out /path/to/generated
```

Compare two fresh compilation directories and the committed baseline. Runtime
TypeScript smoke exercises object schemas; it does not verify a responsibility
graph or execute the mapping contract. None of these commands publishes the
package or updates NormLab.
