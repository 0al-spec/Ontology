# Edit cancellation: a second intent-preservation profile

This example applies the shared [contract 0.1](../../SPECS/intent-preservation/0.1/)
to a different action. A user edits a document and cancels the edit. The chosen
goal is to restore its previous contents while keeping the same document identity.
The application writes a real disposable UTF-8 file; the observer reads its bytes
and domain identity independently of the cancellation implementation's outcome.
The fixed worker and editor source are snapshotted and executed in a fresh Python
process; an editor module cached by a calling process cannot supply old behavior
under a new source hash. The observer checks the original selected path as well
as the returned document, so returning a restored decoy cannot hide an unrestored
selected document.
If the edit never changes the selected bytes, the probe is reported as incomplete
(`unknown`), even if cancellation returns the original contents.

Three independently authored inputs remain separate:

```text
intent.json → model.json → implementation.json + editor.py → observations.json
```

The model and implementation configuration are small inert declarations. This
profile does **not** compile a new ontology package or run Hypercode. Its four
stages and three obligations demonstrate that the shared contract does not require
image fields, nine criteria, or a fixed number of stages. It does not claim the
same tool integration as the image example.

## Run and inspect

Use the image pilot's pinned Python requirements and an external scratch directory
for local runs. From the repository root:

```sh
python -B -m unittest discover -s Examples/edit-cancellation -p 'test_*.py'
python -B Examples/edit-cancellation/run.py --out "$REVIEW_WORK/cancel-success"
python -B Examples/edit-cancellation/run.py --out "$REVIEW_WORK/cancel-drift" --mode keep-edits
python -B Examples/edit-cancellation/run.py --out "$REVIEW_WORK/cancel-unknown" --omit-before
```

The first run exits 0. The deliberate drift and missing-observation runs exit 1:
they produce complete reports with `violated` and `unknown`, respectively. Invalid
input/tool errors exit 2. Every output directory must be new or empty.

Each run writes `receipt.json` in the shared wire format, `assessment.json`,
`report.md`, `report.html`, the exact input snapshots and `observations.json`.
The common `outcomes` projection separately displays operation completion and the
selected-document change; neither is conflated with intent conformity.
The report stays compact while every required mapping and evidence scope can be
expanded. Decisions remain `pending`; example choices do not become human approval.
The first card keeps correspondence, freshness and human decision side by side.
Every evidence item explicitly identifies its boundary and obligation in `subjects`.
Substituting another requirement's evidence or reusing it across undeclared
boundaries yields `unknown`, even when all artifact hashes match.

The negative mode changes both model and implementation declarations to keep the
edited bytes, preserving the original intent. Those downstream layers agree and
the operation completes, but the baseline check fails. `--mode replace-identity`
instead restores the bytes under a new domain identity; the identity requirement
fails even though the content requirement succeeds.

`--omit-before` withholds the observer's initial measurement. The application still
has its private backup and executes cancellation, but the observer cannot establish
restoration. The receipt carries `before: null` and `delta: null`, never invented
empty states. A known unchanged transition may have `{}` as its exact difference
within the declared projection of identity, content hash and byte length.
That difference describes the original selected document; a different returned
identity is an independent violation and does not become a fictitious update of
the original entity's identity.

## Correct and recheck

Restore the changed source declaration and implementation behavior, then run into
a new directory. If the intended behavior itself changes, edit `intent.json`, raise
its revision and review the new baseline explicitly; no run does this automatically.
Use `--inputs` for a directory containing the three input files. The bounded profile
accepts only its documented criterion values and rejects unsupported requirements.

```sh
python -B Examples/edit-cancellation/run.py --out "$REVIEW_WORK/cancel-success" --verify
```

Verification checks the exact current input, adapter/schema, environment and
archived observation hashes. With custom source inputs, pass the same `--inputs`
directory to verification. A changed/missing artifact or unsupported profile yields
`unknown`; old receipt bytes are not rewritten or reinterpreted. These hashes are
not signatures and do not authenticate a producer who can rewrite the receipt.
Earlier draft receipts without evidence subjects are rejected without modification;
the consumer never infers those subjects from IDs or regenerates historical claims.

## Evidence boundary

Evidence covers one generated document, one replace/cancel sequence, domain
identity and content bytes, plus missing-operand evaluation probes. Declaration
checks are structural; execution checks are bounded observations. File metadata,
concurrent edits, crashes, persistent undo history and visual application UX are
outside this example. This is trusted bundled Python code, not a sandbox for
arbitrary programs, a code equivalence proof, or a Lean verification claim.
