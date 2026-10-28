# Intent Preservation Contract 0.1

Status: **bounded reference contract**, `intent-preservation/0.1`. This contract
supports review of an independently authored intent across successive
representations. A compact report identifies semantic changes, unknown mappings
and the source to correct. It does not establish that arbitrary code expresses
the entire meaning of a person's words.

The contract has three parts: a versioned receipt format, consistency rules and
a correction workflow. [receipt.schema.json](receipt.schema.json) defines the
wire shape. [The reference consumer](../../../Examples/intent_contract/core.py)
checks cross-reference, coverage and evidence-binding rules that JSON Schema
cannot express. The schema `$id` is an identifier, not a runtime network dependency.

## Objects and independent decisions

| Object | Required meaning |
| --- | --- |
| `baseline` | Intent ID/revision, bound source artifact, required obligations with stable IDs, origin, scope and criterion |
| `stages` | Ordered, named representations with exact artifact bindings; the first stage includes the baseline |
| `boundaries` | One entry for each adjacent stage pair, in order; one row for every required obligation |
| `evidence` | Versioned checker, explicit kind/scope, judgment and referenced artifact bytes |
| `bindings` | Complete selected inventory of influencing input, tool, adapter and output hashes |
| `decision` | Human review of this baseline revision and exact inventory, independently of verification |
| `outcomes` | Separately labeled, scoped actual operation/goal results, with bound evidence; may be empty |
| `gaps` | Unsupported or unaccounted content; never silently omitted from the assessment |

The baseline's `origin` distinguishes `user_direction`, `assumption` and
`agreed_refinement`. Source text records why the requirement exists. Labeling an
origin does not authenticate the statement or imply that the reviewer agreed.
All baseline obligations are required in 0.1; profiles must not silently omit one.
A motive can explain the intent but need not itself be an executable criterion.

Each mapping row has three independent axes:

- `change`: `preserved`, `refined`, `added`, `changed`, `removed`, `unmapped`.
- Verification: `adjacent` compares the two stages; `baseline` compares the new
  representation with the original criterion. Each is `satisfied`, `violated`
  or `unknown` within the cited evidence scope.
- Human `decision.status`: `pending`, `accepted` or `rejected`.

Human acceptance never turns a violation or unknown into verified success. A
rejected interpretation can still have successful structural tests. A conscious
change to a criterion creates a new baseline revision and receipt; it must not
erase the prior mismatch or rewrite the old expected value to match the code.

## Correspondence rules

1. IDs of obligations, stages, boundaries and evidence must be unique within
   the receipt. References must resolve to the declared inventory.
2. Boundaries cover every consecutive pair in the declared stage sequence.
   Every baseline obligation appears exactly once in every boundary. A row may
   describe a many-to-many implementation mapping in its inert values/reason;
   one class per ontology entity is not required.
3. `expected` retains the original obligation's `criterion`. Matching downstream
   interpretations do not erase disagreement with the baseline.
4. A preserved meaning can use a different representation. A `refined` mapping
   adds implementation detail justified by the profile; it is not strict value
   equality. Semantic equivalence and refinement rules belong to the pinned
   domain checker, not a general string comparison in the shared validator.
5. New assumptions are `added`, with baseline correspondence `unknown`. They
   remain visible until explicitly incorporated into a new baseline. Unsupported
   content belongs in `unmapped` or `gaps`. Removed obligations are violations;
   missing coverage, unresolved references and missing support are unknown.
6. Every non-unknown row judgment cites bound evidence. Each cited item includes
   the baseline artifact and both stages' artifact keys. Its verdict summarizes
   the worst of the two row judgments: a downstream adjacent match plus a
   baseline violation uses violated evidence. A green row cannot hide cited
   unknown or violated evidence.
7. `accepted` or `rejected` decisions name the complete artifact inventory and
   exact baseline revision. Their `reviewedReceiptSHA256` binds the entire receipt
   excluding its `decision` object: UTF-8 JSON with sorted object keys, no ASCII
   escaping, compact separators and finite numbers. `decision_digest(receipt)`
   implements this reference encoding. A decision cannot be copied unchanged to
   newer artifact bytes or mappings even when the baseline revision is unchanged.
   Pending decisions have a null digest and may have an empty binding list.
   The receipt records a decision; it is not a signed identity attestation.

The reference validator aggregates known violations before unknowns. An
unresolved requirement cannot produce all-satisfied status, although another
known violation can already establish that the whole set is violated. A report
must still show the unresolved requirements. A schema error is rejected with
`ValueError`; semantic incompleteness is returned with diagnostics.

## Evidence and freshness

Kinds are `structural`, `execution`, `property_test`, and `formal_proof`. These
are different claims, not interchangeable confidence scores. Each item names a
versioned checker and its scope. Structural validity does not demonstrate runtime
behavior; finite tests do not establish universal equivalence. A formal proof
must identify the proposition and assumptions in its scope and bind its artifacts.
The shared consumer does not run theorem provers or authenticate evidence authors.

The domain profile owns its independent expected values and behavioral oracle.
Expected values must not be generated from the same implementation result they
are intended to check. Observations retain actual identity, state and timing
boundaries. Missing observations stay unknown and never become zero, fabricated
states or an empty Delta.

`check(receipt, supported_profiles=..., current_bindings=...)` compares the full
saved inventory with hashes supplied by the caller. The adapter must independently
read the current influencing files to build that inventory; passing the receipt's
own bindings back is only an internal consistency check. Any mismatch or missing item yields current
`status: unknown`, with the internal old result retained as `saved_status`.
If current bindings are omitted, `freshness: not_checked` explicitly limits the
assessment to the saved receipt's internal consistency. No caller may advertise
that as evidence about the current checkout. `matched` means exact bindings,
not correctness, trusted provenance or factual truth.

The reference consumer captures its own source and schema bytes on import and
checks them before and after an assessment. A cached module cannot claim a newer
on-disk implementation: changed or unavailable bytes yield unknown and require a
fresh Python process. Standalone schema validation rejects that stale context.

Unsupported contract/profile versions return unknown without applying new rules
to old content. Existing `intent-preservation-pilot/v1` image receipts keep their
meaning and bytes. New image runs may also emit this separate 0.1 receipt; the
old saved reports are not silently migrated.

## Workflow

1. **Baseline.** Capture the bounded action, entity identity, intended criterion
   and constraints. Separate supplied intent from proposed assumptions; let the
   person review this short representation.
2. **Translate.** Produce the next representation and an explicit mapping for
   each obligation. Record added decisions and unsupported content.
3. **Compare.** Check adjacent correspondence and original intent independently.
   Preserve failures even if all later layers consistently repeat the mistake.
4. **Observe.** Obtain independently measured execution evidence, tests or scoped
   proofs. Pin all influencing artifacts and checker versions.
5. **Review and correct.** Present changed/unknown rows with correction sources.
   Correct the chosen source and rerun affected checks into a new receipt.
   Changing the intent itself requires an explicit new baseline revision.

A profile selects its stages. The image profile uses ontology and Hypercode;
the cancellation profile deliberately uses a smaller chain. Hypercode remains
responsible for composition and canonical IR; consumer adapters own application
semantics. This contract does not extend compiler IR or define a universal
programming architecture.

## Report contract and reference profiles

The default view includes baseline obligations and origins, coverage per boundary,
changes and unresolved questions, evidence scope/freshness and human decision.
Preserved mappings can be collapsed, but complete coverage must remain accessible.
Each correction is a displayed source reference, never an executable command.
Successful goal evaluation and operation completion stay separate from intent
preservation. A smaller file can still violate preserved dimensions; completed
cancellation can still leave edited content behind.

`outcomes` carries these actual results as domain-owned JSON values with labels,
scope and evidence references. Its IDs must be unique and references must resolve.
Its values are never aggregated into correspondence: a correctly implemented
goal evaluator can report `not_satisfied`, and a completed operation can violate
the intent. The profile defines outcome value semantics. This separation does
not excuse missing evidence for the observations themselves.

The reference profiles are `image-encoding/1` and `edit-cancellation/1`. Their
domain-owned adapters supply the judgments; the generic consumer has no image,
codec or editor-specific fields. Existing package IR and pins remain unchanged.
The mandatory negative controls cover lost obligations, a consistent downstream
mistake, missing or unknown evidence, stale/missing inventory, unsupported versions
and human acceptance that does not override a failed check.

Both receipts and reports are inspectable evidence records, not tamper-proof
certificates. A producer able to forge the complete inventory and claims can
forge a coherent receipt. The bounded example adapters and independent runtime
oracles, rather than the JSON shape alone, supply their demonstrated value.
