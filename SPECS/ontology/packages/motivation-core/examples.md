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

1. An actor RoleBinding belongs to another view/episode, or is named target/instrument.
2. A hypothesis supplies replacement event/actor IDs or physical snapshots/Delta.
3. A source-only candidate is silently upgraded when motivation is reviewed.
4. Missing support is converted into denial, or review status becomes motive truth.
5. A prompting occurrence is the same registered event as the target, or an
   ordered causal claim uses inconsistent scope/clocks or reversed valid times.
6. Uncited operator/model text is relabeled as a source quote or given invented authorship.

These are manual acceptance criteria, not successful rejection tests in this PR.
The executable checks exercise package generation and object shapes only.
