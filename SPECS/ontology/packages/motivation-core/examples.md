# Motivation examples — conceptual expected cases

These examples describe the vocabulary and manual policies. They are not graphs
accepted by an implemented motivation validator, new Lean proofs or extracted
facts about real people. The original event profiles remain unchanged.

## Parking: reported action and a later consequence

Source: “I left the car because I was rushing to the hospital.”

- Motive content: urgency to reach the hospital.
- MotivationHypothesis: contributionKind action, anchored to that source's
  InterpretationCandidate; optional actor RoleBinding only when actually resolved.
- Positive support: the exact SourceAssertion with original source speaker.
- Actual physical states and Delta remain unavailable if the source supplied none.
  A mentioned fine is a reported later response, not an invented parking Delta
  or an inferred intention to be fined.

## Omission: phone outage as a prompting reason

Source: “I did not pay because my phone was unavailable.” A separate account says
“the phone worked; I wanted to avoid paying.” The first motive hypothesis may
retain positive and negative declared source support; the second reason can have
its own hypothesis. Do not automatically choose one or discard either source.

contributionKind omission records that interpretation. It proves neither an
applicable duty nor capacity, deadline, exception, deliberate choice or liability.
If payment was actually established elsewhere, motive text does not override that
selected circumstance or change the saved norm receipt.

## Pilot omission: owner did not secure the car, then the car moved

Use the existing [synthetic car graph](../../fixtures/instance-graphs/synthetic-car.json)
and [design example](design/omission-consequence-example.json). The motive
“attention was elsewhere” is an unsupported synthetic proposal, not a fact
extracted from that graph or a new operator assertion.

1. MotivationHypothesis has contributionKind omission and hypothesisView
   omission-view. Its selected owner-role is reached by interpretationBindsRole
   from omission-view; roleBoundEntity resolves to owner.
2. omission-view interprets the separate omission record. Both snapshots are
   unsecured: the own location-projection change is empty. The original fixture
   has no stored omission Delta; a smoke control adds the exact empty one.
3. causal-link has hypothesisCauseView omission-view and hypothesisEffectView
   movement-view. Keep its proposed state and identity; the motive does not
   establish, review or generate this causal link.
4. movement-view interprets movement. Its movement-delta removes road and adds
   parking. This is the separate effect record's change, hypothesized as a
   downstream consequence of the omission through causal-link.

```text
Motive proposal -> owner / omission-view -> omission (own change = empty)
                                ^
                                | hypothesisCauseView
                            causal-link (proposed)
                                | hypothesisEffectView
                                v
                           movement-view -> movement
                                            Delta: -road, +parking
```

The local empty change and downstream nonempty change coexist. Do not copy
movement-delta onto omission or replace omission-view with an owner reading of
movement: that changes the scoped contribution. The latter is a different event
description, not this pilot's canonical omission representation. If only the
source account exists, keep the candidate without creating either physical record.

An actor role can also be shared: another view referencing owner-role does not
invalidate this hypothesis. It is invalid for this hypothesis only when the edge
from the selected omission-view is absent or the selected role is not named actor.

## Nonhuman and abstract actors

| Actor Entity | Ascribed prompting reason | Interpretation boundary |
|---|---|---|
| AI agent | A received instruction prompted an action. | No consciousness/intention or human responsibility is inferred. |
| Car | External force on an unrestrained vehicle prompted movement. | The car may be actor in one view and instrument in another; motive is tied to its chosen actor view. |
| Community | A shared concern prompted a collective response. | The group is not replaced by an invented named individual. |
| Natural phenomenon | Declared environmental conditions prompted its development. | Broad prompting reason; no mental state or verified physical model is asserted. |

Use optional prompting Entity/Fact/view anchors only for declarations actually
supplied. They are not a requirement to manufacture a preceding recorded event
with empty states. A prior recorded influence is distinct from its target and
needs comparable clocks/scope review for an ordered causal claim.

## Unknown actor and missing motive

A letter reports a reason but gives no resolvable actor. Keep its view candidate,
Motive and MotivationHypothesis without hypothesisActorRole. Do not create a
placeholder Entity or substitute the letter recipient/narrator. If no reason is
reported, keep no motive hypothesis, or an explicitly unsupported proposed one
for a specific suggested reason; neither representation asserts “no motive”.

## Several motives and rejection

“Urgency” and “saving money” may both explain one actor's contribution. Separate
positive hypotheses are not a contradiction by themselves. Contradiction is
explicit opposition to a particular attribution. Rejection in MotivationReview
preserves all support and does not add negative evidence automatically.

## Declared-invalid bindings for a future consumer

A future admission implementation must reject or keep unresolved these cases:

1. The selected view has no interpretationBindsRole/candidateBindsRole edge to
   the selected actor RoleBinding, or that role is named target/instrument.
2. A hypothesis supplies replacement event/actor IDs or physical snapshots/Delta.
3. A source-only candidate is silently upgraded when motivation is reviewed.
4. Missing support is converted into denial, or review status becomes motive truth.
5. A prompting occurrence is the same registered event as the target, or an
   ordered causal claim uses inconsistent scope/clocks or reversed valid times.
6. Uncited operator/model text is relabeled as a source quote or given invented authorship.

These are manual motivation acceptance criteria, not successful motivation
rejection tests in this PR. The executable checks exercise package generation,
object shapes and the existing event validator's Delta/role-sharing controls.
