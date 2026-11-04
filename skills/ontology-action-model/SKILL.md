---
name: ontology-action-model
description: Explain how a desired product outcome could arise from typed actions and state changes. Use for bounded ontology modeling, executable subject/action/object relationships, and behavioral checks.
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

## Explain how the requested property could arise

1. Keep the person's words and give an observable criterion in their terms. Fix
   the scope of words such as “this”, “each” and “after”. For “the calculator
   allows different functions on different exams”, try the same function on two exams.
2. Work backwards from that observation. Which state must the observer use?
   Which actor can change it, by which action, on which entity? Follow the inputs
   to the preceding step until you reach a supplied fact or an unresolved choice.
   A structural fact such as membership can be a premise without an event.
3. Walk the proposed chain forwards for the requester. Show the same identifiable
   entities before and after each action, the reference passed to the next step
   and the behavior the person can see. Attribute the requested outcome, the
   agreed steps and any remaining design assumptions separately. Describe the
   choice in the person's vocabulary, especially when another plausible route
   would behave differently. Leave a missing actor or transition visible.
4. Challenge the explanation. Omit a step or substitute a valid entity from
   another context. Where execution exists, compare the actual observations with
   the independent criterion, including the intermediate state where the two
   explanations diverge. Mark predictions as such until observed.

Distinguish a state the test can inspect from a state the user can encounter.
If a student receives the tablet after the exam's function set is active, check
readiness at handoff. If sections with different sets are part of the requested
exam, the student's transition is a separate behavior to model.

## Model the action

1. Bound the action and select its Entity identity and state projection. State why
   an overwrite preserves identity in this model; the path alone is not an identity
   rule. Name the action or omission and record its parameters/configuration at
   that occurrence. Separate supplied observations from modeling assumptions.
2. Choose an Interpretation and bind participant roles. Any Entity can occupy the
   actor role. Separate action/command names from participating entities; when an
   actor is unspecified, keep it unresolved or explicitly label an assumed reading.
   An encoder may be the operator's instrument in one view and an actor
   in another view of the same observations. A separate request or delegation event
   is decomposition, not merely a role change. Name the domain relation and its
   subject and object. Include an instrument when the means of acting matters.
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

## When the user wants an executable relationship

With Ontology 0.7.0, import `ontology.foundation@0.2.0` as `ont`. Declare the
participants as entity classes and the reusable action as a class extending
`ont:Action`. Name the relationship for its domain meaning. For example,
given a `Person` class and an `Appoint` action:

```yaml
CastAppointment: {subject: Person, action: Appoint, object: Person}
```

The identified subject supplies `Actor<Appoint, Person & Entity>`. In an
appointment of Anna by Ivan, `trigger(appointment)` calls Ivan's
`run(action, object)` with Anna. The same Person can be the object in one
relationship and act in another. An ordinary membership or containment link
can use `domain` and `range` without declaring an action.

Ask what else the action carries. In the [letter transfer package](assets/letter-transfer.yaml),
the sender is the subject, the recipient is the object, and `PassLetter`
carries a required `letterId`. The SDK checks the string field. The application
resolves it to an existing `Letter`.
Both “who received it?” and “what did they pass?” refer to the same transfer.
If the story follows that letter from writing to burning, reuse its identity
across those scenarios. In `burnsLetter` the letter itself is the object.
For “add three to the balance”, the quantity alone is sufficient as the
action parameter. Reuse the selected package vocabulary and model only the
participants and state needed to answer the question.

Run `ontologyc check PACKAGE.yaml` and `ontologyc compile PACKAGE.yaml --target
typescript --out SDK_DIR`. Parse an incoming record with
`ActionRelationshipRecordSchema`. To test execution, supply a concrete subject
and explicitly trigger the relationship. Check the affected object's state
before reading, after reading, and after the trigger. Include a subject that
lacks the required action as a negative typecheck.
[Compilable package and tested SDK example](https://github.com/0al-spec/Ontology/tree/0.7.0/Examples/theatre-casting).

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

When preserving intent through implementation, give each criterion a stable ID
and origin. Keep expected intent independent from generated interpretations. At
each boundary (intent → domain ontology → composition → code → observations),
show a compact diff: preserved, added, removed, modified, unmapped. Compare with
the original intent as well as the preceding layer; matching downstream mistakes
must not become success. Name the editable source of a correction and keep earlier
receipts. Structural validity, matching names or successful tests do not establish
human approval. Separate structural checks, bounded executions and formal proofs.

The Ontology repository's `Examples/intent-preservation` demonstrates this loop
for nine image-encoding obligations. It is not a generic semantic comparator or
mandatory architecture. Do not force one code class per ontology node; document
the explicit implementation map.

Use BDD to discuss concrete behavior and observable examples. Gherkin is one syntax
for those examples; syntax validity alone supplies no executable step bindings.
For PBT, state each rule's domain, preconditions, generated inputs, oracle and
counterexample. Passing generated cases is evidence within those bounds, not a
universal proof. Do not invent codec properties or reported test executions.

The worksheet and Gherkin example are documentation templates. Their notation
is not an accepted InstanceGraph wire format, executable goal DSL, compiler schema extension, or
runtime admission profile. Propose a future schema only when requested, with the
minimum fields needed for the selected behavior; implementation remains separate.
