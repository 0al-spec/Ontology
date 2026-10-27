# Conceptual event core examples

These synthetic descriptions illustrate the draft vocabulary. They are **not**
InstanceGraph payloads or executed semantic tests. Package/object-schema
validation does not verify the relationships or conclusions below.

## Hurricane without a human actor

- Entity `storm`: a natural phenomenon; Entity `shed`: an affected object.
- Given known complete comparable snapshots for the declared roof projection:
  before contains `roofIntact+`, after contains `roofDamaged+`.
- The proposed exact Delta removes `roofIntact+` and adds `roofDamaged+`.
- An Interpretation of the RecordedEvent binds storm as actor and shed as target.

The record belongs to one EventRegistry revision and links directly to its two
StateSnapshots. A Delta links to this record through deltaOfRecord and obtains
the compared states from it, rather than declaring independent state endpoints.

This reading requires no humanAnchor. It does not identify a legally responsible
person. A CausalHypothesis remains an explicitly reviewed hypothesis; the two
snapshots or role labels do not prove that the storm caused the change.

## Abstract community as actor

Entity `community` is an abstract neighborhood community, not a forced Person or
Organization subclass. A reading of an agreement event binds community as actor
and a shared space as target. Any continuing RelationInstance keeps its own
participant roles and optional origin record after the event ends.

The example does not assert legal personality, enforceability of the agreement,
or automatic human attribution. Those are separate profile questions.

## A car as actor or instrument

Use one RecordedEvent for movement from a road to a parking place, with supplied
before/after location snapshots under one episode and projection:

| Reading | Actor | Instrument | Target | Supplied event snapshots |
|---|---|---|---|---|
| Movement reading | Car | absent | Parking place | Same record |
| Owner-contribution hypothesis | Owner | Car | Parking place | Same record |

Role reinterpretation must preserve the observation identities and any computed
Delta. The owner-contribution reading is a hypothesis; ownership alone does not
establish action or omission. A separate omission record would need its own
explicit scope, duty, capability, performance, exception and deadline grounds
under a responsibility profile. This package does not supply those grounds.

For a proposed omission → movement chain, the cause view interprets the separate
omission record and binds the owner; the effect view interprets the movement
record and may bind the car. CausalHypothesis references those two views through
hypothesisCauseView/hypothesisEffectView. Their records derive from interpretsRecord
and must share one EventRegistry revision. Reviewing this hypothesis does not
establish its physical truth or transfer breach/ownership between the records.

## A letter without physical state observations

Synthetic SourceAssertion: source `letter`, speakerKey `letter_1`, quote
"I parked the car by the house." The source does not supply physical state
snapshots before and after parking.

- EventCandidate `reportedParking` retains the source/episode description.
- InterpretationCandidate binds the letter's author as a proposed actor; it
  does not silently substitute the narrator.
- Before/after StateObservations have availability unknown. There are no
  invented StateSnapshots and no exact Delta.
- A reviewed candidate remains a candidate. It is not forced into RecordedEvent
  by adding two empty snapshots or copying an operator review-state transition.

## Known empty snapshots and partial observations

Two supplied complete known snapshots with zero facts under the same declared
schema/scope/projection permit an exact empty Delta. This is a positive control
for the contract, not proof that nothing happened outside that projection.

One partial candidate observation and one complete snapshot leave exact Delta
unavailable for the full declared projection. Partial observations can retain
individual facts; they are not declared as StateSnapshots with a false flag.
A narrower explicit projection could later
be compared if it is known complete on both sides; the exporter cannot silently
choose that projection or call missing facts false.

## Opposed support

Two Fact values can share a propositionKey while carrying positive and negative
polarity. Both are retained; neither is deleted to make a definite answer.
The package does not implement a connective calculus or a rule engine. Strings
such as polarity and availability need the future ONT-043 profile/enum checks.
