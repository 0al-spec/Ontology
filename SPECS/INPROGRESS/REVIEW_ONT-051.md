# REVIEW REPORT — ONT-051

Date: 2026-10-29. Scope: ONT-050 base `7ec4b0c` through implementation `0cb8702`
and its archive. Verdict: approve for the explicitly bounded consumer experiment.
Human intent approval and hosted PR checks are separate.

## Correctness and evidence

The original intent remains independent. Adjacent-layer correspondence is checked
alongside direct comparison with intent; downstream agreement cannot conceal an
earlier mistranslation. Unknown obligations and missing observations remain visible.
Actual goal achievement and evaluator correctness have distinct outcomes.

Independent source review identified two P2 issues, both fixed before EXECUTE:

1. A decoy encoded back into the selected file could pass selected-entity attribution.
   Both identity modes now require the independent selected-image reference;
   a mutation regression rejects the wrong-source write-back.
2. Python's parent module cache could execute old classes under a new file hash.
   Adapter bytes are copied and hash-checked, then executed in a fresh `-I -B`
   worker. Tests prove a modified parent cache is ignored and a modified source
   snapshot changes the measured result.

The reviewer reread the corrected source and found no remaining critical
false-green path in the named profile. Parent ran the full final 55-test suite
with the freshly built pinned Hypercode binary. No separate reviewer test run
is represented as evidence.

## Architecture and safety

The compiler and existing generic admission profiles are unchanged. The example
owns its policy interpretation, implementation and observation adapters. Concepts
remain recognizable without forcing one class per ontology node. The operator's
psychological motive is not inferred from the chosen size criterion.

Inputs are bounded inert documents; only fixed bundled code executes. Temporary
images are generated, and output stays in caller-selected scratch. Fresh process
isolation is not an arbitrary-code security sandbox. Receipts bind bytes and
versions without claiming authentication or factual truth. HTML escapes input;
correction sources are plaintext rather than broken or executable links.

## Validation and resources

- 55 Python tests, including six property-based methods and real-tool/mutation controls.
- 159 Swift tests; 89.87% Swift line coverage; no Python coverage percentage claimed.
- Complete TypeScript and portable package gates pass; new SDK smoke is 7 positive / 11 negative.
- Actual baseline 923,732 → 360,572 bytes. Consistent resize example completes
  successfully but produces a violated intent-preservation report.
- Tool source revision, binary hashes and receipt bindings are in the validation report.
- This is an offline CLI, not a latency-bounded API. Builds and artifacts use TB5.

## Follow-up

No unresolved defect requires a new task; FOLLOW-UP is skipped. Future expansion
should first measure whether a person can identify and correct one newly added
criterion using only the compact report. General scanners, authenticated evidence,
formal implementation refinement and browser editing remain explicit non-goals.
