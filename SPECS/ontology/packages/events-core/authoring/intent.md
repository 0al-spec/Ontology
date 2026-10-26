# Event core authoring intent

Source: [reviewed proposal](../../../event-responsibility-core-proposal.md),
merged in [PR #65](https://github.com/0al-spec/Ontology/pull/65), including the
explicit distinction between unavailable observations and known empty states.

Build a reusable draft vocabulary for scoped entities, episodes, recorded events,
candidate descriptions, role interpretations, source assertions, state
observations, finite snapshots and exact Delta descriptions. Any Entity can
occupy an actor role. Recording an event or accepting a role does not establish
human contribution, physical causation or normative responsibility.

Use the current ontology compiler unchanged. The package must preserve draft
authority and describe its limits. The first examples are a hurricane, an
abstract community, alternative actor/instrument readings of a moving car, and
a letter whose author says "I parked" without before/after state observations.
No parking rules, human duty profile, sanction or paid inference belongs here.

## Domain framing

The governing concept is **RecordedEvent**: it binds supplied snapshots to a
scoped occurrence. An EventCandidate can exist before this record is available.
An InterpretationCandidate preserves source/role proposals; a checked
Interpretation refers to an existing record. Neither candidate review nor a
new role changes that record's observations.

StateObservation describes availability. StateSnapshot contains supplied facts
under a declared projection. Two complete comparable equal snapshots can have
an empty Delta. Missing/partial snapshots leave exact Delta unavailable. These
are authored invariants for the future graph validator, not guarantees of the
current generated object schemas.

## Concept extraction

Entity and Episode provide identity/scope; ActionKind names an occurrence kind.
RecordedEvent and EventCandidate keep complete records apart from descriptions
with missing data. Interpretation, InterpretationCandidate, RoleBinding and
RelationInstance separate readings and contextual participation. StateObservation,
StateSnapshot, Fact and Delta separate availability from contents/change.
SourceAssertion keeps revision/digest/quote/speaker. CausalHypothesis retains a
proposed relation between records without establishing its truth.

## Behavior and policy extraction

ReviewInterpretation and RejectInterpretation record review of a candidate.
The lifecycle is proposed → reviewed or rejected. Reviewed does not mean
promotion to RecordedEvent or proof of factual truth. Event records and source
assertions remain immutable; enrichment is explicitly linked as a new record.

Manual policies require scoped identities, source speakers, unchanged event
observations across interpretations, known comparable snapshots for exact Delta,
and a bounded causal profile. Binary relation definitions connect role-binding
nodes, allowing contextual/n-ary descriptions without a new edge primitive.

## Critique and unresolved decisions

This is curated single-agent staged authoring by Codex /root, not a separate
hosted-model run or independent review. Required confidence/rubric numbers in
the validation artifacts are subjective authoring estimates, not measured model
accuracy. The authoring provenance remains the reviewed proposal.

The current compiler checks package structure and references. It does not enforce
instance relation cardinality, availability enums, cross-record provenance,
interval ordering, exact Delta or semantic support. ONT-043 owns the concrete
wire format and validator; ONT-044 owns responsibility profiles. Those limits
permit YAML assembly but prevent claims of a checked physical event graph.
