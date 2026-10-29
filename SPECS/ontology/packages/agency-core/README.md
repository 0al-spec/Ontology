# Generic Agency Core 0.1.0

`org.0al.agency.core@0.1.0` / `agencycore` is a domain-neutral **draft** extension
of events-core 0.2.0 and motivation-core 0.1.0. Existing package bytes, profile
defaults and historical reports are unchanged. Motive remains in motivation-core;
this package does not redefine it or add criminal-law categories.

| Concept | Meaning |
|---|---|
| PropositionContent | Unasserted content of a condition on a situation/history; not a Fact, Snapshot or Delta |
| AgencyContext | One selected contribution view and optional actor role, with independently optional perspective/report times |
| AwarenessHypothesis | Claimed awareness of exact motive attribution or content |
| GoalHypothesis | Claimed orientation to seek, avoid or maintain content |
| IntentionHypothesis | Claimed commitment to the selected action/omission; goals are optional |
| AnticipationHypothesis | Claimed expectation of content; no objective probability or occurrence follows |
| OutcomeAttitudeHypothesis | Claimed desire, acceptance, opposition or indifference toward content |
| OperatorAgencySupport | Declared uncited support and author, distinct from a source assertion |
| ReviewAgency / RejectAgency | Workflow command for one hypothesis, not a finding of truth |

Each hypothesis has its own support and review. One shared context supplies scope,
not a shared verdict. Several motives, goals, expectations or attitudes may coexist.
Positive and negative support coexist independently. Absence of a claim or evidence
does not prove its negation, unconsciousness or psychological inapplicability.

An actor may not recognize a motive while committing to an action and anticipating
its outcome. Another description may use a machine or natural actor without any
psychological assertions. `not_applicable` is explicit and property/context-specific;
it is not automatically assigned to a nonhuman Entity.

## Content, perspectives and actual outcomes

The same PropositionContent may be targeted by a goal, anticipation and attitude;
none implies another. A maintenance goal may require no change. Intentions may
remain unrealized. An actual event's Delta does not reconstruct the actor's prior
preferences or forecasts. Missing physical states remain unknown, never invented
empty snapshots. Downstream consequences retain the separate causal-hypothesis
path and effect record from motivation-core.

Perspective time means when the attributed stance applies; report time means when
the account was made. Either may be unknown. Separate clocks require external
alignment before comparison; even supplied times are declarations, not chronology
proof. There is no blanket rule forcing an intention to precede the start of a
long-running action.

## Executable boundary

The compiler emits the [IR and SDK](generated/) with scalar object schemas. It
does not implement all eight manual graph policies or constrain string fields to
the profile value sets.

The separate [source-attribution reference consumer](consumer/source-attribution-v1.ts)
provides a strict `agency-source-attribution/v1` envelope, typed value sets and
bounded checks against a **caller-provided reference index**. Its full pin and
check/limit list is in [the profile](profiles/agency-source-attribution-v1.json).

It checks graph/revision identity, view/actor-role reachability, same-view/actor/contribution-kind motive
targets, local content/goal references, existing source/operator references and
independent support-presence reporting. Source speaker remains in the referenced
SourceAssertion; it is never substituted for the actor. Caller-supplied inventories
must already come from the caller's correctly validated graph/revision.

Success means schema/reference agreement. It does **not** independently validate
or authenticate that graph/index, source relevance, psychology, chronology, actual
outcome satisfaction or truth. All five authority flags remain false. The profile
is not `ontologyc validate-instances` admission of agencycore/motivcore nodes:
`eventcore-v1` and `eventcore-provenance-v1` remain unchanged.

## Neutral examples and extension

See [examples](examples.md) and the executable TypeScript smoke controls. A future
NormLab profile should pin these versions plus its own semantic mapping, supply
additional normative grounds and retain unknown/contested inputs. It must not
derive a normative label from motive, intention or actual outcome alone. This
package does not define or execute that downstream profile.

The constructed [source-only envelope](examples/source-only-attribution.json) and
[reference index](examples/reference-index.json) are machine-readable examples.
They are illustrative indexes, not a validated underlying event graph or evidence
that the proposed mental states are true. The TypeScript gate checks them through
the same public consumer API.

Envelope-to-vocabulary mapping: frame describes one AgencyContext; contents map to
PropositionContent, and each claim maps to the class in `profile.claimConcepts`.
`id` supplies contentKey/hypothesisKey, and reviewState is that claim's lifecycle.
Optional frame time objects map to the corresponding clock/instant field pairs.
Positive/negative source refs and uncited operator tuples map to the separate
support relations. This is a documented mapping, not an InstanceGraph exporter.

Validation commands from the repository root:

```sh
ontologyc validate-draft SPECS/ontology/packages/agency-core/authoring --out REPORT
ontologyc check SPECS/ontology/packages/agency-core/domain-ontology-package.yaml
ontologyc compile SPECS/ontology/packages/agency-core/domain-ontology-package.yaml \
  --target typescript --out GENERATED
bash tools/agency-core-smoke.sh
bash tools/typescript-smoke.sh
```

Set `ONTOLOGYC_AGENCY_BINARY_PATH` to the built compiler when using a different
scratch path. Local build/cache/TMPDIR/profiling artifacts use verified TB5;
generated SDK source is committed. No model calls, deployment or release needed.
