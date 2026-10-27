# Conceptual responsibility examples

These outlines use the draft vocabulary. They are **not** accepted InstanceGraph
payloads, executed profile tests or legal cases. Expected outcomes below follow
the [pinned source mapping](NORM_LAB_MAPPING.md); no adapter was run for ONT-044.

## Car actor, owner anchor, explicit duty bearer

Interpretation motionView binds car as actor and a parking place as target.
AttributionContext selects that interpretation and owner as a candidate human
anchor. ResponsibleRelation separately names a duty bearer and counterpart.
No equality between these entities is inferred. A source claim of ownership
does not supply attributed+, required+ or capability.

For a separate omission event, an omission interpretation can bind owner as actor.
All six omission grounds must refer to its exact context. The record/interpretation
for movement cannot borrow a breach from the omission record. If physical states
are absent, keep a source-only candidate; neither this package nor the mapping
supplies missing before/after snapshots.

## Six omission grounds and uncertainty controls

Assume an actual bound context and an authorized exact omission profile rule.
Each condition has one GroundAssessment owned by that assessment. Positive and
negative support are independent; cited/operator support provenance is retained.

| Scenario | Ground change | Expected pinned-profile reading |
|---|---|---|
| All required grounds supplied clearly | attributed+, required+, deadlineElapsed+, capable+, exception-, performed- | Eligible for the omission profile; proposed breachRecorded+ marker, not a sanction. |
| Nothing states whether performance occurred | Remove performed- and keep no performed+ | Unknown performance; omission check cannot pass. |
| Competing performance evidence | Keep performed- and add performed+ | Conflict retained; clear negative premise fails. |
| Capability unresolved | No capable+ or capable- | Missing required premise, not proof of incapacity. |
| Exception supported | exception+ opposes the required exception- | Definite omission admission fails; no support is erased. |
| Deadline merely described | A Deadline node exists, but no deadlineElapsed+ | Metadata is not elapsed support; required premise remains missing. |
| Different context | A required literal belongs to another event/interpretation/anchor | It cannot satisfy this context's premise. |
| Different declared duty action | Duty requires pay, while context describes movement | R3 does not compare the external DutySpecification; a generic duty claim needs explicit action alignment. |
| Only operator support | Explicit OperatorSupport with author/rationale for performed- | May be selected as an uncited assertion under a reviewed mapping; never masquerades as a quoted source. |

The current R3 scope has no distinct generic duty-bearer field. If the proposed
ResponsibleRelation's bearer differs from the profile's human-contribution
subject, the generic duty claim needs a separate interpretation/profile; the
R3 marker does not certify that relationship merely because its check can pass.

## A persistent relation

A community's agreement is proposed as an origin context for a maintenance duty.
The community can be an abstract Entity. Origin, continuation and termination
have separate Condition identities and GroundAssessments. The relation may be
claimed to persist while the originator performs no current action; cessation
requires its own termination grounds. This example does not infer legal
personality or verify any of those conditions.

## Response is another conditional step

An omission profile's proposed breachRecorded+ marker does not select a sanction.
A ResponseRule describes separate trigger/authority Conditions and a response ActionKind. A
ResponseCandidate records that rule/assessment, with explicit or unresolved
responder/recipient. Authority, applicability and recipient selection need a
separate reviewed response profile; no amount or parking rule is supplied here.

## Used, unused and alternative supports

Two accepted support records A and B map to the same performed- literal; C maps
to an unrelated literal in another context. A CertificateReference records its
external artifact and selected mapping provenance.

1. Delete C: the selected Tree's used literal/rule values remain. Its generic
   preservation theorem may apply; recheck profile admission/provenance.
2. Delete A while B remains: the required literal may still be present. The old
   provenance artifact naming A is stale; update mapping/provenance and reverify.
3. Delete both A and B: the requested negative performance literal is absent.
   The fixed omission certificate cannot verify; no unknown-to-negative default.
4. Add performed+: the eligibility Tree may still cite all its old premises,
   but Profile.check rejects the newly opposed negative premise.
5. Add breachRecorded-: the fixed eligibility Tree may still verify; the separate
   effect-opposition check rejects admission. Tree validity is not the whole gate.

No certificate is generated or checked by these examples. The package encodes
the identities and boundaries needed by a later consumer, rather than claiming
these source-derived expectations are new experimental results.
