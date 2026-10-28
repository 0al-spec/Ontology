# ONT-048 — Validation Report

**Date:** 2026-10-28
**Verdict:** PASS — local package and PR review-correction checks; correction-head hosted CI and independent re-review pending
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

- Motivation source digest: sha256:3061eca33ddc2296c2c292695d98daf6697e92fb582da544bc1d5107721ae955
- Motivation IR SHA-256: 25da040f4bd0b014014b1ed996250cd4c17a64503355f6f558917bec9ddd1fe9
- Event dependency: org.0al.events.core@0.2.0,
  IR SHA-256 e6c932ad8c492d168b63dbe112335c270d88ff758e016f3502031aefe9dea916

## Authority and limits

All policies are manual, and design/motivation-binding-v1.json is explicitly
non-executable. Generated Zod objects verify scalar shapes/discriminators; they
do not validate relation instances/cardinality, selected-view actor-role edges, mode enums,
scope/clock/order, source relevance or truth. The smoke explicitly demonstrates
that the generic object schema accepts a string outside the intended contribution
kind set; this is not a supported runtime admission case.

Existing instance profiles admit no motivcore nodes/relations. Conceptual invalid
examples are manual acceptance criteria, not executed semantic rejection tests.
Review/rejection is workflow, not truth. Own change uses the selected record
states/Delta. Hypothesized downstream consequence retains the explicit causal
hypothesis and separate effect record/Delta. Empty own change does not deny
downstream effects; a desired outcome or motivating reason does not produce
physical states, performance, omission grounds, fault or liability.

No motivation runtime adapter, instance validator, Lean proof, NormLab code/tests,
paid inference, deployment or automatic norm-result change is included.

## Next step

Publish the draft for independent review. ONT-045 remains the separate bounded
offline pilot and must agree its consumer contract before any motivation admission.


## PR review correction checks — 2026-10-28

The initial 6c02230 head received green hosted quality/DocC and independent
review. That review identified two semantic ambiguities; the corrections above
supersede the original own-record-only consequence wording.

- Inert design version 0.1.1 records separate own and hypothesized downstream
  navigation and selected-view role edges; existing instance-profile versions
  and old reports remain unchanged. The draft package remains 0.1.0, unreleased.
- validate-draft/check and two fresh compilations: PASS, matching all ten tracked
  generated files. The six imported classes and exact event IR pins still match.
- The design's role/record/causal navigation resolves against the actual event IR;
  the smoke follows the referenced real synthetic car fixture and checks the
  expected owner, omission, causal-link, movement and distinct local/effect changes.
- Actual frozen-v1 CLI controls: an exact empty omission Delta PASSES; shared actor
  RoleBinding referenced by an Interpretation and InterpretationCandidate PASSES;
  moving the nonempty movement Delta onto omission FAILS with
  instanceGraph.delta.exact as expected. Passing reports keep sourceTruthVerified
  and causationVerified false. No motivcore nodes are submitted to this validator.
- npm run typecheck and npm run smoke: PASS. Compiler Sources/Tests and frozen
  event/responsibility/profile/fixture artifacts have no diff from 6c02230.
- Shell syntax, whitespace and all 80 relative Markdown links: PASS.
- Full 159-test quality/coverage evidence above is from the initial implementation;
  it was not rerun locally for this documentation/design/smoke correction. Hosted
  CI must verify the published correction head separately.

During development the report assertion initially addressed sourceTruthVerified
at the wrong nesting level; it now checks report.authority. An unsupported
DraftCritique key was rejected by validate-draft and the review references were
moved to its existing provenance list. Final correction checks pass without any
compiler/schema changes. The fixture controls are structural event regressions,
not motivation-truth, causal or legal proofs.
