# Intent preservation: image encoding pilot

A person reviews a small intent and the changes at each translation boundary,
then edits the source of a mismatch. This example executes a bounded chain:

```text
intent.json → ontology-model.json → image.hc + image.hcs
            → implementation.json + image_app.py → independent observations
```

`report.html` and `report.md` show nine criteria, four boundary summaries and
changed/unmapped rows. Unchanged mappings, measurements and hashes expand on
demand. Every value is compared with the preceding layer **and the original
intent**. Matching mistakes in later layers cannot erase an earlier mismatch.

## Review and edit

| Review subject | Editable source | Checked scope |
| --- | --- | --- |
| Human intent | `intent.json` | Typed criteria, stable IDs, source/assumption labels; human alignment stays pending |
| Domain interpretation | `ontology-model.json` | Concepts, fields and three relationships against pinned compiled ontology IR |
| Composition | `image.hc`, `image.hcs` | Real Hypercode validation, resolved values and selected topology |
| Implementation | `implementation.json`, `image_app.py` | Declaration correspondence, named code anchors, separate behavioral probes |
| Consequence and goal | New execution receipt | Independent measurements and numerical evaluator checks |

The baseline selects one synthetic image, JPEG reencoding in place, preserved
dimensions, quality parameter 65 and a reduction **of at least 200,000 bytes**.
JPEG, dimensions, quality, decimal units and minimum rather than exact reduction
are labeled example assumptions. They are not silently attributed to the user.

The operator supplies the command and criterion. In this interpretation,
`Reencode` maps to `Encoder.reencode(ImageDocument)`, with the encoder as an
instrument. File replacement preserves a selected domain identity, not inode
identity. `SizeGoal.evaluate` applies the criterion to observations; it does not
cause a result. The broad motive in `intent.json` concerns this development
experiment, not an inferred mental state of the application operator.

The [draft package](../../SPECS/ontology/packages/image-encoding-pilot/README.md)
supplies real compiled concepts. The local model format is not an admitted generic
InstanceGraph. `ImageState` is a finite application measurement projection, not a
complete physical StateSnapshot. The byte difference is one measured component
of consequence, not an invented eventcore Delta. Missing measurements stay missing.

## Run

Use Python 3.13, `ontologyc` from this checkout, and Hypercode source revision
`cb577e1bf68db79da34e465f63656c3cd79a7d53`. Versions and normalized IR digests are
pinned in `requirements.txt` and `profile.json`. The dedicated CI workflow builds
both tools. For local work, select external scratch/cache locations before builds.

From the Ontology root, set `PILOT_WORK` to an existing scratch directory and
`ONTOLOGYC_BINARY`, `HYPERCODE_BINARY` to absolute executable paths, then:

```sh
export TMPDIR="$PILOT_WORK/tmp"
export PIP_CACHE_DIR="$PILOT_WORK/pip-cache"
export HYPOTHESIS_STORAGE_DIRECTORY="$PILOT_WORK/hypothesis"
mkdir -p "$TMPDIR"
python3.13 -m venv "$PILOT_WORK/venv"
"$PILOT_WORK/venv/bin/python" -B -m pip install -r Examples/intent-preservation/requirements.txt
export ONTOLOGYC_BINARY HYPERCODE_BINARY

"$PILOT_WORK/venv/bin/python" -B -m unittest discover \
  -s Examples/intent-preservation -p 'test_*.py'
"$PILOT_WORK/venv/bin/python" -B Examples/intent-preservation/pipeline.py run \
  --ontologyc "$ONTOLOGYC_BINARY" --hypercode "$HYPERCODE_BINARY" \
  --out "$PILOT_WORK/review-1"
```

The output directory must be new or empty. Only generated disposable images are
encoded. Fixed bundled adapter bytes are snapshotted and executed in a fresh
Python process, so cached modules cannot masquerade as a new source version.
This separation is not a sandbox for arbitrary programs; input declarations have
no executable-module or shell-command fields.

Exit 0 means the named checks are satisfied. A completed report with a mismatch
or unknown mapping exits 1; tool/input errors exit 2 and are never reported as
successful validation. Human approval and universal equivalence are not inferred.
Without both tool environment variables the suite explicitly skips integration
tests: that is an incomplete check. CI sets both and also requires the CLI run.

## Correct a mistranslation

1. Copy the five input files (`intent.json`, `ontology-model.json`, `image.hc`,
   `image.hcs`, `implementation.json`) to a working directory; use `--inputs`.
2. Change `dimensions: "preserve"` to `"resize"` in Hypercode and implementation
   configuration, keeping intent unchanged. Run into `review-2`.
3. The configured resize executes correctly, but the report detects its mismatch
   with the original intent and names the affected criterion and source files.
4. Restore `preserve`, or consciously change the intent if the requirement itself
   changed. Create `review-3`; retain the earlier receipts.

Editing happens in these source artifacts, not a browser form. The report does
not repair intent to fit implementation. New unmapped requirements remain unknown
until an explicit adapter exists. No mandatory class per ontology node is imposed.

Check an old receipt against current artifacts without upgrading its meaning:

```sh
"$PILOT_WORK/venv/bin/python" -B Examples/intent-preservation/pipeline.py verify \
  --ontologyc "$ONTOLOGYC_BINARY" --hypercode "$HYPERCODE_BINARY" \
  --out "$PILOT_WORK/review-1"
```

Supply the original `--inputs` location if used. `matched` checks unchanged input,
adapter, tool, environment and archived IR bindings, not correctness. Missing or
changed evidence yields unknown. Other profile versions are not reinterpreted.
Full files and IR are hashed: Hypercode node hashes alone omit some contract and
provenance information. Receipts are not signed attestations; a party able to
replace the receipt can forge its claims.

## Evidence boundaries

Independent execution checks the selected image and decoy, identity, dimensions,
JPEG decoding and bytes against a fixed-Pillow reference. The goal oracle checks
the real transition plus threshold boundaries, different initial sizes with the
same final size, growth, zero, missing inputs and different identities. Goal
achievement is separate from whether the evaluator implements the chosen rule.

Negative controls cover lost or changed obligations, wrong links/composition,
resize/copy, a decoy written back into the selected path, wrong quality/goal logic,
cached modules and stale/missing evidence. Hypothesis adds generated arithmetic
cases. The skill's Gherkin scenarios remain discussion examples; no executable
Gherkin step bindings are claimed here.

This profile covers nine obligations and one action. Names and shapes provide
structural evidence; finite executions provide bounded behavioral evidence. No
Lean proof, full source equivalence, visual-quality criterion, metadata preservation
or universal codec property is claimed. The next experiment should add one new
criterion and measure whether a person can identify and correct its intentional
mistranslation from the compact report alone.
