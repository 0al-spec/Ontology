# ONT-048 — Validation Report

**Date:** 2026-10-28
**Verdict:** PASS — local draft/package/generation checks; independent review and hosted CI pending
**Package:** org.0al.motivation.core@0.1.0 (draft), namespace motivcore

## Delivered

Five classes, nine relations, six manual policies and one proposal-review lifecycle.
Motive is a broad prompting reason; any Entity may be actor and conscious intention
is not required, as explicitly confirmed by the user. MotivationHypothesis anchors
one motive to one existing interpretation/candidate, with optional actor role.
Support is independently positive/negative and cited/operator-authored. Contextual
reason anchors and actual consequence remain distinct; source-only data needs no
record, snapshot or Delta. Missing evidence is never an assertion of no motive.

Staged authoring artifacts, assembled YAML, all ten generated IR/SDK files,
conceptual examples/diagram and an inert dependency/design contract are present.
The package imports events-core 0.2.0; exact source/IR pins and six imported class
references are checked against the actual local event IR.

## Executed checks

| Check | Result |
|---|---|
| Actual ontologyc validate-draft and check | PASS |
| Two fresh compilations and all ten baseline files | Byte-identical |
| New tools/motivation-core-smoke.sh | PASS, dependency pin, declared critical relation shapes and non-executable authority checks |
| npm run typecheck and npm run smoke | PASS, including new motivation required-field/discriminator/primitive controls |
| Full RUN_COVERAGE=1 bash tools/swift-quality.sh | PASS, 159 existing regression tests, format/lint/import checks |
| Existing responsibility-core gate | PASS, unchanged package and mapping |
| Existing provenance gate | PASS, unchanged artifact baselines and 18 expected fixture outcomes |
| Existing eventcore-v1 gate | PASS, unchanged consumer baseline, limitation passes and missing interval fails as expected |
| Pre-archive relative links | 37/37 resolve |
| Whitespace / frozen package scope | PASS; compiler Sources/Tests, old event/responsibility/profile artifacts unchanged |

Configured llvm-cov TOTAL line coverage: 89.87%, region 79.32%; includes configured
dependency/vendor sources. These are existing compiler regression results, not
159 new motivation tests or proof that motive semantics are executed.

The first new smoke draft attempted to read approvalStatus from normalized IR.
The compiler does not retain that metadata in IR; inspection confirmed this and
the corrected gate now checks draft approval in source, without changing compiler
behavior or claiming IR-level approval. Final checks above pass.

## Reproduction and routing

Use the existing built CLI and tools/motivation-core-smoke.sh, then run the
TypeScript commands in SPECS/ontology and the full Swift quality gate. TB5 UUID
preflight passed; build/cache/temp/LLVM outputs were external. Tracked generated
IR/SDK files are intentional source deliverables. Full log:
/Volumes/TB5/Developer/Builds/GitHub/Ontology-881ba79a220bd2df/ont-048-quality.log.
The existing native build-system deprecation warning remains, with no code/lint
failure. No new dependency or build configuration was installed.

## Pins

- Motivation source digest: sha256:bef057acd636164f43c43f70eb5e6d4795ee4c8a112c23906134e1ffd86ff823
- Motivation IR SHA-256: 87a8918af5206b471ab896301959d0c0a9c39cd294f3b6a051feb3a73b05d0ff
- Event dependency: org.0al.events.core@0.2.0,
  IR SHA-256 e6c932ad8c492d168b63dbe112335c270d88ff758e016f3502031aefe9dea916

## Authority and limits

All policies are manual, and design/motivation-binding-v1.json is explicitly
non-executable. Generated Zod objects verify scalar shapes/discriminators; they
do not validate relation instances/cardinality, actor-role ownership, mode enums,
scope/clock/order, source relevance or truth. The smoke explicitly demonstrates
that the generic object schema accepts a string outside the intended contribution
kind set; this is not a supported runtime admission case.

Existing instance profiles admit no motivcore nodes/relations. Conceptual invalid
examples are manual acceptance criteria, not executed semantic rejection tests.
Review/rejection is workflow, not truth. Actual consequence needs admitted known
states and an optional exact Delta; a desired outcome or motivating reason does
not produce physical states, performance, omission grounds, fault or liability.

No motivation runtime adapter, instance validator, Lean proof, NormLab code/tests,
paid inference, deployment or automatic norm-result change is included.

## Next step

Publish the draft for independent review. ONT-045 remains the separate bounded
offline pilot and must agree its consumer contract before any motivation admission.
