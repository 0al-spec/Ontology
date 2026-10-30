# Image Encoding Pilot — draft

`org.0al.image.encoding.pilot@0.1.0`, namespace `imagepilot`, approvalStatus draft.
Imports `sg@0.1.0`, `eventcore@0.2.0` and `agencycore@0.1.0`.

This package is the small descriptive layer of the caller-owned
`Examples/intent-preservation` experiment. It makes the selected action,
configuration, entity identity and goal criterion reviewable; it does not select
a universal application architecture or execute a codec.

| Class ref | Required fields |
|---|---|
| imagepilot:ImageDocument | entityKey:string |
| imagepilot:Encoder | quality:integer |
| imagepilot:Reencode | identityMode:string, dimensions:string, actionKind:string |
| imagepilot:ImageState | entityKey:string, byteLength:integer, width:integer, height:integer, contentSHA256:string |
| imagepilot:SizeGoal | basis:string, comparison:string, targetBytes:integer, missingInput:string |

ImageDocument and Encoder are Entity specializations. Reencode is a declared
Command, not an assertion that an operation occurred. ImageState is a finite
application observation projection, not an eventcore StateSnapshot or Delta.
SizeGoal is an application criterion, not an attributed mental stance or action.

| Relation ref | Domain → range | Cardinality |
|---|---|---|
| imagepilot:reencodeTarget | Reencode → ImageDocument | 1..1 |
| imagepilot:reencodeEncoder | Reencode → Encoder | 1..1 |
| imagepilot:reencodeGoal | Reencode → SizeGoal | 1..1 |
| imagepilot:reencodeContext | Reencode → agencycore:AgencyContext | 0..1 |
| imagepilot:stateOfDocument | ImageState → ImageDocument | 1..1 |

The optional context anchors the selected actor/view; a subject is derived through
the existing context actor role rather than duplicated on the action. Encoder's
instrument/actor role depends on that interpretation. An absent context does not
invent an operator identity, source speaker, motive or awareness claim.

Descriptive values for this draft are `in_place | copy`, `preserve | resize`,
`jpeg_reencode`, `reduction | final_size`, `at_least | exactly | at_most`, and
`missingInput = unknown`. The separate runtime profile chooses supported
combinations; the package's generated string schemas do not check these enums.
Reduction means `before.byteLength - after.byteLength`; final size uses
`after.byteLength`. targetBytes is a nonnegative byte quantity, with explicit
conversion from any human unit. An exact quantity differs from a minimum bound.

Unknown observations stay unavailable. Criterion evaluation is unknown when the
available data cannot decide it; a known-false conjunct can establish
not_satisfied without resolving other operands. No missing measurement becomes
zero, a fabricated state or an empty Delta. Completion, criterion satisfaction,
image content fidelity and visual acceptance are separate claims.

The five policies are manual. Package/compiler validation checks declarations and
refs; generated SDK checks required primitive object shapes. These checks do not
validate relation cardinality instances, entity agreement, dimensions, measured
digests, codec behavior, goal arithmetic, source truth or implementation fidelity.
No new InstanceGraph profile or semantic equivalence theorem is supplied.

The compiler used for this saved pilot required a nonempty state machine.
The current package format allows omitted or empty policies/stateMachines;
the saved intent, draft and generated artifacts retain their original declarations.
`ReencodeRequest` declares `ready -> requested` on the existing Reencode command.
It records request vocabulary only; it is not bound to physical image states and
does not assert execution, completion, criterion satisfaction or runtime history.

[Intent](authoring/intent.md), [competency questions](authoring/competency-questions.md)
and the staged authoring artifacts explain the boundary. The domain package and
`authoring/domain-ontology-package-draft.yaml` are identical JSON-compatible YAML.
The generated IR/SDK are derived artifacts, not additional sources of intent.

Verification of this draft: `ontologyc check` and staged `validate-draft` passed.
Two independent TypeScript compilations produced identical bytes for all ten
generated files; the package's generated baseline matches those outputs. These
are package/generation checks; caller runtime and implementation checks are separate.
