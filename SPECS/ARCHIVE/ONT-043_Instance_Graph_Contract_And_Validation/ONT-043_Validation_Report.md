# ONT-043 Validation Report

**Date:** 2026-10-27
**Verdict:** PASS — bounded structural validator, not factual/causal/legal proof
**Dependency:** PR #66 merged at `a2e1af3c4eb27ec060e8c88457c260d6ecedde82`
**Profile:** eventcore-v1, exact normalized IR SHA256
`2c596f08073653e8a47df8e46aa1b1b75284717d32148d162d497775ce5a31a0`

## Results

| Check | Result and evidence |
|---|---|
| Dependency | Live PR #66 head `2b1facd`, green quality/DocC, zero review threads, independent no-blocker review read before expected-head merge. Local main fast-forwarded safely. |
| Red/green | Initial implementation: 9 groups, 16 expected failures. Review regression run: 26 tests, 21 expected failures before fixes. Final focused suite: 27 tests pass. |
| Full quality | Actual `RUN_COVERAGE=1 bash tools/swift-quality.sh` passed Node24 workflow check, SwiftFormat, SwiftLint, explicit import build and 143 tests (116 existing + 27 new). |
| Coverage | Configured llvm-cov TOTAL line 89.58%, region 78.41%. Includes dependency/vendor code; not legal-model or semantic completeness evidence. |
| CLI | Real compiled binary accepts populated overlap-chain and source-only candidate fixtures, returns 1 and writes diagnostics for missing interval; exported consumer files match baseline. |
| Pinned IR | Tampered IR with unchanged metadata fails the raw artifact hash check. Low-level unchecked rule context is package-internal. |
| Wire | Tests cover unknown/legacy/null/duplicate JSON fields, UTF-8/BOM/UTF-16/32 boundaries, full scanner consumption/depth, identifiers, collection shape, duplicate node/edge identity, bad/wrong-revision/typed references and required cardinality. |
| Encoding CLI replay | 9 actual CLI cases verify UTF-8 whitespace acceptance, duplicate-key rejection across UTF-8/BOM/UTF-16/32 inputs, correct exit/report status and exact graphSHA256 for each. |
| Event profile | Positive/negative controls cover registry uniqueness, direct observation snapshots, candidate alternatives/scope, self/future/different-clock hypothesis endpoints, lifecycle membership, exact/empty/wrong-owner/duplicate Delta and opposed support. |
| Exact input binding | graphSHA256 binds the report to exact graph bytes; a test reusing the same claimed revision with changed data produces a different hash. |
| Source | UTF-16 quote length/offset structure checked; speaker retained. Source bytes, authenticity and citation relevance unverified. |
| Consumer contracts | Two fresh exported TypeScript/JSON Schema pairs are byte-identical and match committed generated baseline. TypeScript typecheck passes, including expected errors for missing intervalStart and wrong direct snapshot type. |
| Regression | Existing examcalc/events-core runtime smoke passes; existing package YAML/IR/SDK baseline is unchanged. |
| CI | Baseline `853a5fc` quality/DocC confirmed green directly. Review-fix head requires fresh hosted CI; fixture smoke now includes the explicit expected-pass limitation. |
| Documentation | 43 relative Markdown file/heading references resolved before archive; original package YAML/IR/SDK remains unchanged. Whitespace checks pass. |

## Executed checks

Local artifact production used verified TB5 per-checkout Swift scratch/cache,
temporary/module/LLVM profile outputs; existing Node dependencies were reused.
No cache migration, dependency install or source relocation was required.

```sh
swift test --scratch-path <external-swiftpm> --cache-path <external-cache> --build-system native --filter InstanceGraph
RUN_COVERAGE=1 ONTOLOGY_SWIFT_SCRATCH_PATH=<external-swiftpm> bash tools/swift-quality.sh
ONTOLOGYC_INSTANCE_BINARY_PATH=<external-binary> bash tools/instance-graph-smoke.sh
npm run typecheck
npm run smoke
```

Initial quality log is in the external build root as `ont-043-quality.log`;
review-fix evidence is `ont-043-review-red.log`, `ont-043-review-green.log` and
`ont-043-review-quality.log`. Existing
quality scripts require the process-local native-build/cache shim for this local
toolchain. Its native build-system deprecation warning remains; no source warning
or failed gate was suppressed. CI is not configured with this machine's paths.

## Limits

The exact reviewed profile validates one supplied finite graph revision. It does
not establish historical immutability or compare prior revisions. Completeness
and projection domain are exporter declarations; dishonest relabeling, fabricated
observations and semantic relevance are not detected. Lifecycle state membership
is checked, not command execution/history. General typed ontology relations are
checked against pinned IR; no arbitrary rule language is interpreted.

Specifically, an unknown source-only candidate can be linked through
candidateEnrichedByRecord to externally invented empty snapshots and an empty
Delta, and still pass structural validation. The new limitation fixture
`limitation-unproven-empty-enrichment.json` deliberately demonstrates this. The
v1 vocabulary has no snapshot provenance, so no factual origin check is claimed.
The ONT-043 acceptance wording was narrowed; ONT-047 owns a future provenance
profile and ONT-045 must verify its exporter does not manufacture missing states.

## Independent PR #67 review corrections — 2026-10-27

- Reject all unsupported encodings before Foundation parsing, including valid
  graphs encoded as BOM UTF-8 or UTF-16/32; allow ordinary UTF-8 whitespace.
- Require the scanner to enter a root object and consume the entire document.
  Duplicate-key attacks in unsupported encodings and direct scanner trailing
  input/depth regressions are covered.
- Reject duplicate Episode.scopeKey with episode.duplicate, aligning node and
  scope identity. Skip dependent hypothesis.order when intervals are invalid or
  clocks differ; retain the primary interval/clock error.
- Document and execute the expected-pass provenance limitation rather than
  claiming it was rejected. No package YAML, generated SDK or IR pin change.

No new Lean proof, responsibility profile, NormLab runtime export, paid inference,
deployment, registry publication or Linux portability change occurred. ONT-044
and ONT-045 remain next separate steps. Reports explicitly mark structuralOnly
and false sourceTruth/causation/responsibility verification flags.
