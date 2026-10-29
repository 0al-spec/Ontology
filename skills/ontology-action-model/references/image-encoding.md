# Worked example: destructive image encoding

Scope: the application's image transformation only. This is a synthetic design
example, not a measured codec run, accepted InstanceGraph fixture or implemented
app. See [the modeling guide](modeling.md) and the
[Gherkin scenarios](../assets/image-encoding.feature).

## Identity and participants

The domain entity is image document `image-1`, with one current encoded representation.
Its application identity survives an overwrite. A temporary output file does not
become a new domain image solely because the storage implementation uses one.
Exporting a copy would instead create a second identity, outside this example.

The selected relation is “transformation of image-1.” In interpretation A, the
operator is its actor/subject, image-1 its object and the encoder its instrument.
Interpretation B gives the encoder the actor role and treats the operator as the
initiator. Both descriptions reference the same transformation and observations.
Neither establishes ownership, legal responsibility or an encoder's psychological motive.

## Motive and goal

An explicitly supplied operator account is: “Compactness matters to me; make this
image at least 200 kB smaller without changing its dimensions.” It supplies a
prompting reason and a declared target. Without such an account, a slider change
alone would not supply either claim.

For this example **kB is decimal**. “At least” is a chosen requirement, not an
interpretation silently imposed on every request saying “200 kB smaller.”

```text
G-size:    before.byte_length - after.byte_length >= 200_000 bytes
G-shape:   before.width = after.width AND before.height = after.height
G-total:   G-size AND G-shape
```

The domain evaluator checks these criteria using observations of the same image
and transition. A selected `quality` is an input parameter to the encoding action;
it is not an objective percentage of remaining visual quality or a size guarantee.
Visual acceptability requires a separately defined criterion/observation and is
not silently included in this numerical goal.

## Synthetic state transition and consequence

| Observed property | Before | After |
|---|---|---|
| Domain identity | image-1 | image-1 |
| Encoded byte length | 900,000 | 700,000 |
| Width | 1,200 | 1,200 |
| Height | 800 | 800 |
| Content revision | r1 | r2 |

These are supplied measurements of a bounded projection; revision labels alone
do not prove pixel changes or quantify visual degradation. A real implementation
must obtain the observations from its actual output. The consequence in this
projection includes `byte_length: 900000 -> 700000` and `content_revision: r1 -> r2`.
It records no dimension change. The size change is -200,000 bytes and reduction
is +200,000 bytes. `G-total` is satisfied.

| Before bytes | After bytes | Reduction | At least 200 kB | Exactly 200 kB |
|---|---|---|---|---|
| 900,000 | 700,000 | 200,000 | satisfied | satisfied |
| 800,000 | 700,000 | 100,000 | not_satisfied | not_satisfied |
| 900,000 | 699,999 | 200,001 | satisfied | not_satisfied |
| 900,000 | 700,001 | 199,999 | not_satisfied | not_satisfied |
| unknown | 700,000 | unknown | unknown | unknown |

The first two rows have identical final sizes and different relative outcomes.
This is why evaluating only the new state loses essential information. For a
different goal “final size <= 700,000 bytes,” even the last row supplies enough
information for that numerical check. It still does not establish a known full
physical transition or authorize fabricating a before-state/Delta.

## Architecture choices exposed by the model

If the encoder receives only `quality = 60`, it promises whatever its encoding
contract says. Completion need not achieve `G-size`; the operator or application
evaluator can assess the result and decide whether to try again.

If the encoder receives `G-total` as an optimization target, the contract must
separately define search limits, feasibility, failure and how a result is measured.
This guide implements neither optimization nor that expanded contract.

Changing the quality selection and actually encoding are distinct actions when
the application does not encode immediately. A cancelled request does not create
an image transformation merely because the UI previously changed a parameter.
An asynchronous design may additionally record request, processing and commit
events. That is explicit decomposition, not a change to the observations of the
single event used here.

## Acceptance examples and properties

The `.feature` file exercises the **goal-evaluation component contract** with
supplied observations. Its Gherkin syntax can be parsed, but no step definitions,
codec, UI runner or production evaluator are supplied. It must not be reported as
passing application acceptance tests. A later app should bind the same criteria
to independently measured before/after bytes and actual observable output.

For future PBT, generate byte lengths and targets as bounded nonnegative integers,
preserve or deliberately vary dimensions, and generate missing observations as
absence rather than zeros. Keep entity/event identity fixed except in separate
scope-rejection cases. Include these discriminating controls:

| Fault injected into future evaluator | Example that must expose it |
|---|---|
| Uses only final size | 900,000 -> 700,000 versus 800,000 -> 700,000 |
| Reverses reduction sign | 900,000 -> 700,000 with target 200,000 |
| Uses strict greater-than | 900,000 -> 700,000 at the exact boundary |
| Uses at-least for an exact target | 900,000 -> 699,999 with exact 200,000 |
| Treats missing observation as a fabricated size | Unknown baseline with known output |
| Ignores preservation constraint | Sufficient reduction but different width |
| Reads operation completion as goal success | Completed encoding with reduction only 100,000 |

Once real bindings exist, a stateful PBT model could explore parameter changes,
encoding, cancellation and replacement. That is a later extension; the minimal
pattern needs neither a general causal-chain engine nor a state-machine framework.
