# Bounded action model — worksheet

Fill the fields needed for one behavior; omit unused sections. This is descriptive
documentation, not an accepted InstanceGraph wire format or executable goal DSL.
Replace bracketed prompts with the model's values. Keep unresolved data explicit.

## Boundary and assumptions

| Item | Model value |
|---|---|
| Application behavior | [one bounded action] |
| Modeling question | [what this model must explain or evaluate] |
| Action / omission | [kind and domain name of the selected contribution] |
| Action parameters / configuration | [values or configuration snapshot at this occurrence; unknown explicitly] |
| Event boundary | [what begins and ends the selected occurrence] |
| Operation outcome | [completed, failed, cancelled, pending, or the chosen contract; observation source] |
| Included observations | [available within-app evidence] |
| Excluded context | [only exclusions needed to preserve the requested scope] |

| Assumption | Reason it is needed | What changes if it is false |
|---|---|---|
| [explicit assumption, not an observation] | [unresolved choice] | [model consequence] |

For an ambiguous quantity, choose and label an example interpretation: exact
reduction, minimum reduction, or final-size bound. Define units; do not substitute
one comparator for another. For example, `kB = 1000 bytes` is an explicit unit choice.

## Entity identity and state

| Item | Model value |
|---|---|
| Entity | [the file, image, or other entity being modeled] |
| Identity rule | [what makes it the same Entity before and after] |
| State projection | [attributes included; what the projection leaves unobserved] |
| State_before source | [supplied observation or unknown] |
| State_after source | [supplied observation or unknown] |

| Attribute | Unit or domain | Before | After | Observation source / availability |
|---|---|---|---|---|
| [attribute] | [unit/domain] | [value or unknown] | [value or unknown] | [evidence] |

An overwrite preserves this Entity only under the chosen identity rule. A shared
path alone does not select that rule. Do not infer a complete state from a few
attributes or fill an unknown attribute with zero.

## Interpretation and participant roles

| View | Selected occurrence | Actor | Instrument, if relevant | Target Entity |
|---|---|---|---|---|
| [chosen Interpretation] | [occurrence] | [Entity in actor role] | [Entity or unresolved] | [Entity] |
| [optional alternative view] | [same occurrence] | [alternative actor role] | [instrument role] | [same Entity] |

| Relation | Model value |
|---|---|
| Domain relation name | [for example, transformation of an image] |
| Relation meaning | [how subject/actor, object/target and instrument relate through this action in the selected view] |

Actors need not be human. Alternative roles over the same occurrence preserve its
observations and actual change. If introducing a separate request or delegation:

| Additional event, if needed | Why it is distinct within scope | Its own observations |
|---|---|---|
| [event or omit this table] | [decomposition rationale] | [known values or unknown] |

## Actual change

| Change | Value | Derivation and availability |
|---|---|---|
| Added / removed state facts | [difference or unknown] | [comparable before/after observations] |
| Relevant measured difference | [value with unit or unknown] | [explicit calculation from observations] |

An exact Delta requires comparable, sufficiently specified states in the selected
projection. Use `unknown` for a difference whose required observations are missing.
Empty Delta means known absence of change in that projection, not absence of
observations or effects outside the projection. Keep desired changes out of the
actual difference.

## Goal criterion and evaluation

| Item | Model value |
|---|---|
| Goal content | [required state or change, independent of whether it occurs] |
| Criterion origin | [user requirement, actor statement, or labeled modeling assumption] |
| Selected actor / view, if attributed | [scope and support; unresolved remains unresolved] |
| Evaluator | [actor or other evaluator performing the comparison] |
| Required inputs | [State_after, Delta, or full transition; named attributes] |
| Comparator / tolerance | [exact equality, minimum, maximum, or explicit tolerance] |
| Units | [unit definitions and any declared conversion] |
| Constraints | [additional conditions; omit if none] |
| Criterion | [plain-language rule or mathematical predicate; no assumed runtime] |

| Case | Required inputs available? | Comparison | Goal evaluation | Reason / evidence |
|---|---|---|---|---|
| [concrete transition] | [yes/no; missing inputs] | [calculation or unknown] | [satisfied / not_satisfied / unknown] | [grounds] |

The evaluator applies the criterion; the goal does not act. Use `unknown` when
available information cannot decide it. For a conjunction, one known-false
condition suffices for `not_satisfied` even if other operands are unknown; otherwise
unresolved necessary conditions prevent `satisfied`. A final-state goal need not
require a before value; a reduction goal usually does. Operation outcome and goal
evaluation are separate: completion does not establish satisfaction. Meeting a size
condition does not establish visual acceptance. Record configuration, measured
bytes and acceptance separately.

## Optional motive attribution

Omit this section when explanation is unnecessary. A motive is a broad prompting
reason for this actor's contribution; it need not imply a goal or awareness.

| Actor / view | Attributed prompting reason | Positive support | Negative support | Review, if performed |
|---|---|---|---|---|
| [selected scope] | [reason or unknown] | [source/operator grounds or none] | [opposing grounds or none] | [workflow record or absent] |

Slider movement, parameter choice, or an observed result does not establish a
motive attribution. Support and review do not establish truth. Add awareness, intention,
anticipation or attitude only when needed, with their own scope and support.

## BDD examples

| Scenario | Given: known preconditions | When: selected action | Then: observable result and evaluation |
|---|---|---|---|
| [goal met] | [state/configuration/assumptions] | [action] | [operation outcome, observations; goal satisfied] |
| [goal not met] | [state/configuration/assumptions] | [action] | [operation outcome, observations; goal not_satisfied] |
| [evaluation unresolved] | [missing information needed to decide; no decisive violation known] | [action or evaluation] | [operation outcome, if known; goal unknown; no invented Delta] |

BDD is the behavior discussion. Gherkin may express these scenarios; a valid
`.feature` file needs step bindings and execution evidence to become an app test.

## PBT candidates

| Rule | Domain and preconditions | Generated inputs | Oracle | Counterexample or failure report |
|---|---|---|---|---|
| [general rule worth checking] | [when the rule applies] | [bounded values/transitions] | [independent expected relation] | [minimal failing case / unknown handling] |

Keep arithmetic/evaluator rules separate from codec claims. Do not assume size
monotonicity or visual acceptance from a quality parameter without a scoped basis.
Generated passing cases support the declared domain; they are not a universal proof.

## Verification record and open questions

| Layer | Implemented or performed? | Exact evidence / remaining boundary |
|---|---|---|
| Model and BDD discussion | [status] | [reviewed examples or open ambiguity] |
| Gherkin syntax | [parsed / not parsed / not used] | [parser result, if run] |
| Executable step bindings | [present / absent / not inspected] | [binding and run evidence, if any] |
| Property-based tests | [implemented / proposed / not needed] | [domain, run evidence, counterexamples] |
| Runtime goal evaluator | [implemented / descriptive only] | [implementation and execution evidence, if any] |

Open question: [the smallest unresolved decision that affects this model].
