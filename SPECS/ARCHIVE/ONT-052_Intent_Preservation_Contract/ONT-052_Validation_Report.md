# ONT-052 Validation Report

Date: 2026-10-29. Verdict: **PASS — bounded local reference contract and two consumer profiles**. Hosted CI and PR review are tracked separately.

## Delivered scope

- Contract `intent-preservation/0.1`: normative workflow, strict JSON Schema and cross-reference/coverage/evidence/decision validator.
- Independent change, adjacent/baseline verdict, observed outcome, freshness and human decision axes. Accepted decisions bind a canonical receipt digest; they cannot silently transfer to changed artifacts or claims.
- Image profile `image-encoding/1` emits a supplementary common receipt from fresh runs. The v1 pilot report and input meanings remain unchanged; archived reports are not auto-upgraded.
- Edit cancellation profile `edit-cancellation/1` runs an actual disposable document edit/cancel through a snapshotted fresh worker. Its smaller declaration chain deliberately does not claim ontologyc/Hypercode integration.
- Compact HTML/Markdown cards expose changes and unknowns; preserved mappings expand. No actual phone/browser visual audit was performed in this task.

## Local verification

All Python processes used the existing pinned Python 3.13 virtualenv and external scratch/cache paths under the verified TB5 Ontology build root. Real image integration used ontologyc from this checkout and Hypercode at its existing pinned source revision.

Commands, with that environment and tool paths set:

```sh
PYTHONPATH=Examples python -B -m unittest discover -s Examples/intent_contract -p "test_*.py"
python -B -m unittest discover -s Examples/intent-preservation -p "test_*.py"
python -B -m unittest discover -s Examples/edit-cancellation -p "test_*.py"
```

Results: **36 + 60 + 17 = 113 tests passed**, no skipped real-tool integration. Shared tests cover missing/duplicate coverage, reference binding, typed JSON criteria, nonfinite input, unsupported versions, unsubstantiated judgments, stale bytes/imported consumers, human decision transfer, outcomes and escaped renderer content. Image controls include the independent numerical goal not achieved while evaluator conformance remains satisfied. Cancellation controls mutate real isolated source copies for cached modules, decoy restoration and a skipped edit.

Fresh CLI evidence:

| Case | Contract status | Other evidence |
| --- | --- | --- |
| Image baseline | satisfied | Actual numeric goal satisfied; verify-contract freshness matched |
| Image resized in composition and code | violated | Runtime configured behavior and numeric goal satisfied; original dimensions violated |
| Cancel restores document | satisfied | Operation completed; known empty selected-document Delta |
| Cancel keeps edits in model and code | violated | Operation completed; original content restoration failed |
| Cancel lacks initial observation | unknown | Before and Delta remain null |

The final artifacts are local at `ont052-final/` in the external Ontology build root. No reports were published as a website. Generated reports are also configured as CI artifacts.

JSON Schema parsing, Python AST parsing for all three example areas, relative documentation links and `git diff --check` pass. Swift compiler sources, package IR and dependencies are unchanged; no redundant local Swift build was performed. The repository hosted quality/portability/DocC workflows will run on the new PR head.

## Independent review and corrections

An independent agent reproduced two defects in initial working changes: cached editor code could be paired with new source hashes, and the exact shared-test CI command missed its import root. Both were fixed and rechecked. The old cache reproduction now executes the changed code and returns violated; the exact CI test command passes. The reviewer also independently verified that accepted decisions cannot transfer to changed artifact bytes. No remaining blocker was reported.

## Limits

Core validates declared correspondence and evidence integrity, not arbitrary semantic truth. Domain adapters supply bounded judgments. Hashes are not signed attestations. Human approval is not inferred from pilot acceptance; outcomes are distinct from conformity. No new Lean proof, general code equivalence, UI application, merge, deployment or external consumer activation is claimed.

## PR review regression follow-up

The initial PR head 12ead7f passed all five hosted jobs. Two subsequent bot findings were addressed before completing delivery: loaded export bytes now have an import-time guard (including export loaded before pipeline import), and preserved-looking rows with missing/unknown/violated cited evidence stay expanded. The renderer has the same import-time source guard for its human projection. Isolated regressions pass; the updated total is 113 local tests. Hosted validation of the follow-up commit is tracked in PR #76. Earlier local receipts remain immutable and become stale against changed adapters as designed.
