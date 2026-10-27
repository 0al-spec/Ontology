# Event core — draft 0.1.0

`org.0al.events.core@0.1.0`, namespace `eventcore`, is the first vocabulary
package from the [event/responsibility proposal](../../event-responsibility-core-proposal.md).
It describes events, candidate descriptions, interpretations, source provenance
and state changes. It remains `approvalStatus: draft`.

## What is in the package

The governing concept is RecordedEvent. Entity is independent of human status;
actor, target and instrument are contextual RoleBindings. Checked Interpretations
refer to a record; EventCandidate and InterpretationCandidate retain incomplete
source-level descriptions. RecordedEvent links directly to its before/after
StateSnapshots. StateObservation describes availability only for candidates.
StateSnapshot itself declares a supplied complete finite state; there is no
additional `complete` flag.

The package also defines Episode, ActionKind, Fact, SourceAssertion,
RelationInstance, EventRegistry and CausalHypothesis. Interpretation candidates
and causal hypotheses share the declared ProposalReview lifecycle with
proposed → reviewed/rejected commands. Reviewed never promotes a candidate into
a checked event or establishes factual truth or physical causation.

## Record, Delta and hypothesis identity

- `recordInRegistry` binds each record to one EventRegistry revision. Its
  `(registryKey, revisionKey)` identifies the local registry snapshot;
  `recordKey` is unique within that snapshot, not globally. InstanceGraph in
  ONT-043 will validate this membership and uniqueness; the class is not a
  running registry service.
- `recordBeforeSnapshot` and `recordAfterSnapshot` point directly to supplied
  StateSnapshots. Missing/partial observations stay on EventCandidate; they
  cannot be an alternative type of a record's states.
- `deltaOfRecord` gives Delta one owning record. Both compared states and their
  projection derive from that record; Delta has no separate state endpoints or
  projection key. ONT-043 must recompute/validate its Added/Removed sets from
  those states.
- `hypothesisCauseView` and `hypothesisEffectView` reference Interpretations.
  Their endpoint records derive through `interpretsRecord`, preserving the
  participants/roles at both ends. Both records must be in the same registry
  revision under the chosen profile. CausalHypothesis uses lifecycle metadata,
  not a separate free-form `reviewStatus` field.

## Authoring and provenance

The staged [intent and domain/behavior framing](authoring/intent.md),
[classification](authoring/intent-classification.yaml),
[candidate model](authoring/product-ontology-draft.yaml),
[critique](authoring/draft-critique.yaml) and
[competency questions](authoring/competency-questions.md) precede YAML assembly.
They were curated by the same Codex author from the reviewed proposal, without
additional hosted model calls or independent authoring agents. Confidence/rubric
numbers are subjective estimates required by the current draft artifact schema.

The assembled [authoring draft](authoring/domain-ontology-package-draft.yaml)
and [package](domain-ontology-package.yaml) are byte-identical copies. Keep them
in sync and validate both authoring and package artifacts when changing them.
Generated IR/SDK files live under [generated/](generated/).

## Observation availability

| Supplied observations | Exact Delta under the proposed contract |
|---|---|
| Both known, complete, comparable and equal | Available; Added and Removed are empty. |
| Both known, complete, comparable and different | Available; Added/Removed describe exact set differences. |
| Either missing, unknown or partial | Unavailable; do not insert an empty Delta. |
| Schema, scope or projection differs | Comparison needs an explicit mapping first. |

Known means supplied and complete for the declared projection; it does not prove
the narrative true. Candidate observations use availability known/unknown/partial:
known references a StateSnapshot, unknown has no snapshot, and partial may retain
individual facts through `observationSuppliesFact` without declaring a complete
state. A proposition with unknown/conflicting support inside a supplied snapshot
is different from the snapshot itself being unavailable.

## Structural versus semantic validation

`ontologyc` validates package vocabulary, declared references, scalar field shapes
and lifecycle definitions, then emits deterministic IR/TypeScript artifacts.
Generated object schemas validate fields. They do **not** enforce graph-wide
instance links, conditional cardinality, enum values stored as strings, source
quote relevance, interval order, immutable observations, or exact Delta.

All five policies use `enforceability: manual`; their text is inert review data.
No checked physical-event graph, causal claim, human attribution, duty or sanction
is produced by this package. ONT-043 owns InstanceGraph and executable integrity
checks; ONT-044 owns responsibility profiles. Existing foundation Actor kinds
and existing packages remain unchanged.

## Examples and reproduction

[Conceptual examples](examples.md) cover a hurricane, an abstract community, car
actor/instrument readings, source-only observations and the known-empty control.
They deliberately do not introduce an InstanceGraph wire format before ONT-043.

With `ontologyc` built using your platform's configured build/cache location:

```sh
ontologyc validate-draft SPECS/ontology/packages/events-core/authoring --out /path/to/draft-report.yaml
ontologyc check SPECS/ontology/packages/events-core/domain-ontology-package.yaml
ontologyc compile SPECS/ontology/packages/events-core/domain-ontology-package.yaml --target typescript --out /path/to/new-output
```

Compilation outputs are checked against a second independent output directory
before committing the generated baseline. The runtime TypeScript smoke gate
invokes event-core object schemas with valid examples and invalid field shapes;
it does not validate whole-graph invariants. These commands do not authorize
publishing the package to a trusted registry or changing NormLab runtime data.
