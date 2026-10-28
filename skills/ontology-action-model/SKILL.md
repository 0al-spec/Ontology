---
name: ontology-action-model
description: Model a bounded application action through entity identity, actor roles, state transitions, goal criteria, and BDD/PBT examples. Use for conceptual behavior modeling and review, without assuming implementation or a new ontology schema.
---

# Ontology Action Model

Produce the smallest model that answers the user's question about one application
behavior. Preserve the requested boundary and distinguish observed change,
desired change, actor-relative explanation, and verification evidence.

## Read and reuse

- Read [modeling.md](references/modeling.md) for the modeling rules and evaluation
  semantics before drafting or reviewing a model.
- For raster-image encoding, read [image-encoding.md](references/image-encoding.md)
  for the worked example. Its identity and role choices are examples, not defaults
  for other domains.
- Fill [action-model.md](assets/action-model.md) when a reusable worksheet helps;
  omit irrelevant sections instead of introducing unused concepts.
- Use [image-encoding.feature](assets/image-encoding.feature) as a concrete Gherkin
  example when discussing scenarios. Adapt its assumptions rather than copying
  its numbers or domain boundaries into unrelated models.

Return the model in the user's requested medium. A conceptual discussion does not
require creating files, implementing an application, or changing ontology packages.

## Model the action

1. Bound the action and select its Entity identity and state projection. State why
   an overwrite preserves identity in this model; the path alone is not an identity
   rule. Name the action or omission and record its parameters/configuration at
   that occurrence. Separate supplied observations from modeling assumptions.
2. Choose an Interpretation and bind participant roles. Any Entity can occupy the
   actor role. An encoder may be the operator's instrument in one view and an actor
   in another view of the same observations. A separate request or delegation event
   is decomposition, not merely a role change. Name the domain relation and explain
   how its subject, object and instrument participate through the selected action.
3. Describe `State_before`, `State_after`, and the actual Delta in that projection.
   Missing or incomparable required observations leave the relevant difference
   unknown. An empty Delta requires known comparable states with no difference.
4. State the goal as a criterion over `State_after`, Delta, or the full transition,
   choosing its required inputs explicitly. An actor or evaluator applies the
   criterion; the goal does not act. Distinguish satisfaction from performance.
5. Keep motive optional: a broad prompting reason attributed to this actor's
   contribution, without requiring awareness, intention, or a goal. A changed
   slider or a smaller result does not establish an operator's motive or desire.

Do not add request chains, application creation, distribution, stores, or hardware
setup to an explicitly within-app example. New events need a reason within the
requested boundary, not a desire to populate every available ontology concept.

## Make the criterion testable

- Record the criterion's origin, comparator, units, constraints and evaluator.
  Reducing *by* a quantity differs from limiting final size *to* a quantity.
  Exact reduction differs from minimum reduction. If “200 kB” is ambiguous,
  choose a labeled example assumption, define the unit, and retain the alternatives.
- Use `satisfied`, `not_satisfied`, or `unknown` for the documented evaluation.
  Use `unknown` when available information cannot decide the criterion. For a
  conjunction, one known-false condition suffices for `not_satisfied`; otherwise
  unresolved necessary conditions prevent `satisfied`. Never replace missing
  observations with zero bytes, a fabricated state or an empty Delta.
- Keep encoding quality configuration, measured output bytes, and the operator's
  visual acceptance separate. A desired or anticipated condition is not an actual
  observation; a result can exist without meeting the goal.
- Keep support, review, and truth separate for optional actor-relative claims.
  Multiple explanations or opposing support can coexist without automatic resolution.

## Check examples and verification claims

Use BDD to discuss concrete behavior and observable examples. Gherkin is one syntax
for those examples; syntax validity alone supplies no executable step bindings.
For PBT, state each rule's domain, preconditions, generated inputs, oracle and
counterexample. Passing generated cases is evidence within those bounds, not a
universal proof. Do not invent codec properties or reported test executions.

These resources are documentation templates. Their notation is not an accepted
InstanceGraph wire format, executable goal DSL, compiler schema extension, or
runtime admission profile. Propose a future schema only when requested, with the
minimum fields needed for the selected behavior; implementation remains separate.
