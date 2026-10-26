# ONT-042 Validation Report

**Date:** 2026-10-27
**Verdict:** PASS — draft vocabulary and structural compiler evidence
**Input:** `SPECS/ARCHIVE/ONT-042_Draft_Event_Core_Package/ONT-042_Draft_Event_Core_Package.md`
**Package:** `org.0al.events.core@0.1.0` (`eventcore`), approval status draft
**Source digest:** `sha256:7e914e9bc22142ce888d8d92ed48713c3e3a2b31dea635daf9c5417dc4bf8181`

## Results

| Check | Result | Evidence and limit |
|---|---|---|
| Prior proposal | PASS | PR #65 merged as `839019d5b8aa6074b4f150f7dd63463f93a2eb15`; local main fast-forwarded before ONT-042. |
| Staged authoring | PASS | Intent/framing, classification, draft model, critique and competency questions precede assembly; single-agent curated authoring, no paid calls. |
| Draft validation | PASS | Actual `ontologyc validate-draft` accepted all four required artifacts with candidate-only authority. |
| Package check | PASS | Actual `ontologyc check` accepted the draft package using the unchanged compiler/schema. |
| Package structure | PASS | 17 classes, 28 relations, 5 manual policies, 1 candidate-review lifecycle; no duty/sanction package. |
| Assembly consistency | PASS | Authoring draft/package bytes match exactly. |
| Determinism | PASS | Two independent final compilations emitted byte-identical sets of all 10 IR/SDK files; committed baseline matches them. |
| TypeScript | PASS | Existing `npm run typecheck` now includes event-core generated TS. Existing `npm run smoke` passed its examcalc runtime fixture; it is not a new event-graph semantic test. |
| Swift quality | PASS | `tools/swift-quality.sh`, with coverage, passed Node24 action checks, SwiftFormat, SwiftLint, build/import checking and all 116 existing tests. |
| Coverage | Reported | Existing llvm-cov TOTAL line coverage 89.00%; region coverage 76.39%. This configured report includes dependency/vendor code and is not package semantics coverage. |
| Docs | PASS | 35 relative file/heading links resolved at execution, whitespace checks pass. Archive-relative links must be rechecked after moving the task files. |
| CI integration | Added | Workflow now checks draft/package consistency, validates/compiles the package and compares its generated baseline. Hosted execution remains pending publication. |

## Executed commands and routing

Paths below shorten the verified TB5 build/cache directories; no machine-specific
path is required by the tracked project. The preflight helper verified the
configured TB5 volume identity before artifact production.

```sh
ontologyc validate-draft SPECS/ontology/packages/events-core/authoring --out <TB5-evidence>/draft-validation-final.yaml
ontologyc check SPECS/ontology/packages/events-core/domain-ontology-package.yaml
ontologyc compile SPECS/ontology/packages/events-core/domain-ontology-package.yaml --target typescript --out <TB5-evidence>/compile-final-a
ontologyc compile SPECS/ontology/packages/events-core/domain-ontology-package.yaml --target typescript --out <TB5-evidence>/compile-final-b
RUN_COVERAGE=1 ONTOLOGY_SWIFT_SCRATCH_PATH=<TB5-swiftpm> bash tools/swift-quality.sh
npm run typecheck
npm run smoke
git diff --check
```

The compiler binary, Swift scratch/cache, temporary test files, module
cache and evidence logs were on TB5. A coverage-instrumented CLI subsequently
wrote one 143,480-byte `default.profraw` into the checkout during final compilation.
It was copied byte-for-byte to TB5 and removed from the checkout; subsequent CLI
calls route LLVM profiles explicitly. The ordinary CLI was rebuilt without
coverage and rechecked. The CI package check also routes its LLVM profile into
runner temporary storage. A local ignored `.build` symlink points to
the same per-checkout scratch directory because existing CLI tests look there.
A process-local Swift shim adds the verified cache path and the native build
system needed by this coverage gate; the installed toolchain reports native
build-system deprecation. No tracked build defaults or global settings changed.
The existing Node dependencies were reused; npm cache and supported transient
outputs were directed to TB5 without installing/migrating dependencies.

## Scope and review corrections

The authoring critique keeps instance/enum/graph validation unresolved. During
self-inspection, explicit candidate-to-new-record and candidate-to-checked-
interpretation provenance relations were added. Final draft/check/compile and
TypeScript typecheck were repeated after that vocabulary change; all 10 output
files match the two final compilations. SourceAssertion also uses the documented DomainEntity foundation instead of
assuming an undeclared Evidence foundation type. The unchanged compiler regression suite
did not require a second run for two additional declared relation definitions.

The examples describe a hurricane, abstract community, alternative car roles,
source-only unknown observations, a known-empty control and opposed support.
They are conceptual descriptions, not a newly standardized InstanceGraph format
or executed causal/diff checks. All policy text remains inert/manual.

## Remaining boundary

No Sources changes, new Lean proofs, instance semantic validator, paid inference,
registry publication, NormLab edits or deployment occurred. ONT-043 must implement
graph identity, references, availability/enum checks and the chosen wire contract;
ONT-044 owns responsibility profiles. Independent PR review and hosted CI must
be assessed on the published head, not inferred from these local results.
