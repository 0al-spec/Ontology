# ONT-054 — Validation Report

Date: 2026-10-30. Verdict: **PASS for the bounded local change**.
Implementation: Sol 6.1 High. Independent source review and SpecGraph consumer
probe: root agent. Hosted CI/review and merge are separate, pending outcomes.

## Observed results

- Full Swift quality gate: **166 tests passed**, including 7 new test methods
  with omitted/empty/mixed/populated sections and malformed-input controls.
- SwiftFormat passed; SwiftLint reported zero violations in 95 files; Node24
  workflow check and explicit target-dependency import build passed.
- Coverage: **90.22% lines**, 79.96% regions, 76.21% functions. Changed
  `PackageValidation.swift`: 87.84% lines. These are different denominators.
- The existing examcalc regression retained all 10 generated output files
  byte-for-byte and its normalized IR digest. SDK output surfaces remain present
  for newly empty sections, with empty declarations/ref maps.
- Ruby fixture validator: **10/10**; additional malformed-section/field controls:
  **19/19**. The new invalid field fixture requires all nine expected diagnostic
  branches rather than accepting any unrelated error.
- `git diff --check` passed. Build products and compiler test scratch were on
  TB5; no worktree `.build` directory was created.

The original release compiler rejected the minimal package with missing-section
and empty-section diagnostics. The candidate accepts omission or `{}` but still
rejects explicit null/non-map values, missing lifecycle machines, malformed
policy/state-machine declarations and unresolved local relation endpoints.

## Consumer verification

The root agent copied the actual model from SpecGraph revision
`336d5d603df2323b0eccc69b5f0d271b3c25b494`, removing only `policies` and
`stateMachines` from the local package. The released compiler rejected it. The
candidate passed real SDK generation, TypeScript 6.0.3 compilation, instance
relation checks and the existing execution comparison, with no findings.

The observed project-context outcome stayed `invalid`, retaining both required
diagnostics. SpecGraph's canonical source, source map and implementation were
unchanged; partial source coverage stayed partial. This verifies removal of the
padding, not generic instance validation or natural-language completeness.
See [the curated observation](ONT-054_Consumer_Observation.json) for input,
binary, report and local-log digests. The consumer used a preserved candidate
binary; the later coverage-instrumented build has a different recorded digest.
These records do not attest a binary-to-source build or update a release pin.

## Reproduction

On this Mac the verified per-worktree build root was
`/Volumes/TB5/Developer/Builds/GitHub/Ontology-local-package-ergonomics-78c6754bf93b4bea`.
The unmodified quality entry point was run with `RUN_COVERAGE=1`,
`ONTOLOGY_SWIFT_SCRATCH_PATH=<build-root>/swiftpm` and an external `TMPDIR`.
A task-local PATH wrapper forwarded `swift` to the installed toolchain with
`--cache-path /Volumes/TB5/Developer/Caches/swiftpm --build-system native`, keeping
the repository's complete gate intact. `swift build --show-bin-path` confirmed
`<build-root>/swiftpm/arm64-apple-macosx/debug`.

```sh
RUN_COVERAGE=1 ONTOLOGY_SWIFT_SCRATCH_PATH=<scratch> bash tools/swift-quality.sh
ruby SPECS/ontology/fixtures/validate-fixtures.rb
git diff --check
```

The consumer command was run from the SpecGraph repository environment:

```sh
.venv/bin/python tools/local_ontology_pilot.py \
  --ontologyc <preserved-candidate-binary> \
  --tsc <typescript-6.0.3>/bin/tsc \
  --model-dir <copy-with-two-sections-removed> --work-dir <new-run-directory>
```

Local logs are under `<build-root>/logs/`; the paired consumer reports and
modified source copy are under `<build-root>/specgraph-consumer-probe/`.

## Corrections and limits

The first new SDK test assumed one-line empty literals; generated formatting is
multiline. The assertion was corrected to parse exported JSON declarations,
and the full quality/coverage gate then passed. No emitter change was needed.

The Ruby gate also reproduced an existing defect on the unchanged baseline:
examcalc's supported class fields were rejected as an unknown key. The narrow
repair validates the already-defined field contract and has negative controls.
It does not claim complete schema parity for every future compiler feature.

Historical image-pilot intent and generated artifacts were preserved. Imported
symbol resolution remains namespace-based, and instance validation remains
profile-specific. This slice creates no runtime profile, new domain meaning,
release, deployment or consumer pin update. Local macOS validation does not
stand in for hosted Linux CI.
