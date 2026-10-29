# ONT-051 validation

Date: 2026-10-29. Verdict: PASS for the bounded local pilot.
Base: ONT-050 `7ec4b0ce3c81e3012ce98958e9fa2f09398041e9`.
Hosted CI and human intent approval remain separate from this local verdict.

## Delivered

- Real draft `org.0al.image.encoding.pilot@0.1.0`, staged authoring, compiled IR and SDK.
- Typed intent, explicit ontology relationships, real Hypercode composition/contracts,
  minimal image implementation, independent observation and goal evaluation.
- Compact HTML/Markdown boundary reports, immutable original intent comparison,
  named correction sources, exact artifact bindings and freshness checks.
- Dedicated CI, executable negative controls and action-model skill guidance.

## Checks performed

| Check | Observed result |
| --- | --- |
| Draft validation and package check | PASS |
| Two package compilations and tracked baseline | Byte-identical, all ten outputs |
| `tools/swift-quality.sh` with coverage | PASS: 159 tests; line coverage 89.87% |
| `tools/portable-contract-smoke.sh` | PASS including the new package and existing profiles |
| TypeScript typecheck and complete runtime smoke | PASS; new package has 7 positive / 11 negative schema controls |
| Python unittest with both real CLI paths | PASS: 55 tests in 2.914 s; includes 6 Hypothesis properties |
| Hypercode validate then emit | PASS using a freshly built pinned source revision |
| Baseline CLI execution | `satisfied`; goal independently `satisfied`; human review pending |
| Consistent resize in Hypercode and code | Report `violated`, although runtime and actual goal succeed |
| Baseline receipt freshness | `matched`; saved result preserved without reinterpretation |
| Skill validation and installed copy | PASS; byte-identical SKILL.md |

The actual baseline fixture measured 923,732 → 360,572 bytes: reduction 563,160
bytes, dimensions unchanged. This result is for generated test pixels and pinned
Pillow, not a size guarantee for arbitrary inputs. No personal image was read.

Negative controls cover missing/changed obligations, wrong composition and links,
copy/resize, wrong input including decoy write-back, wrong JPEG quality, goal
basis/comparator/threshold errors, absent states and stale/missing bindings. A
fresh-process regression proves execution ignores a corrupted parent module cache
and detects changed snapshotted implementation behavior.

## Tool and evidence binding

- Python 3.13.15, Pillow 13.0.0, Hypothesis 6.170.13, jsonschema 4.26.0.
- Hypercode source `cb577e1bf68db79da34e465f63656c3cd79a7d53`, clean checkout;
  binary SHA-256 `f9631fa8c2dcfe6c1afd57c4919617e13e84838bfc289fb94440740231684e76`.
- ontologyc SHA-256 `907d434f7a492698fd233e3d229eb458d7d0bbd43ac487a9ba6dae1b6768b2dd`.
- Image package normalized IR SHA-256
  `5b8ce46254775710f07ea5fad3ce7f69c77ca51d50b6e85ef8955c4f8d586c0f`.
- Each generated `report.json` binds full inputs, adapter sources, tools, package
  files/IR, emitted Hypercode IR and runtime observations. Snapshot copies are
  retained alongside the receipt; source changes do not rewrite old results.

All local builds, dependencies, temporary images, Node mirror and report outputs
used verified TB5 roots. Hypercode was built in its own project scratch path.
The internal disk briefly rejected source writes; no unrelated data was removed.
Writing resumed after space became available. Source changes stayed in place.

## Independent review

Source review found and closed two false-attribution/binding issues before final
validation: selected-image evidence now checks the independently encoded reference
in both identity modes, and bundled code runs from a verified snapshot in a fresh
process. The reviewer reread both fixes and found no remaining critical false-green
issue in this bounded profile. This was source review, not an additional test run.

## Limits

This is a local nine-obligation consumer, not a universal semantic comparator.
Generated primitive schemas do not enforce application enums or behavior. Source
names are not behavioral proofs; tests do not imply arbitrary-code equivalence.
No Lean proof or authenticated source-truth claim is made. The human must still
judge whether the explicit criteria reflect their intent. Report editing uses the
source files, not a browser form; visual layout was not independently browser-audited.
