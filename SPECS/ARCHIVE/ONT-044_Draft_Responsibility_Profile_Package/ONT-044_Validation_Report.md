# ONT-044 Validation Report

**Date:** 2026-10-27
**Verdict:** PASS — draft vocabulary, deterministic SDK and source mapping
**Package:** org.0al.responsibility.core@0.1.0 / respcore / draft
**Source digest:** `sha256:f1540b9d7362677910ab02bc1844edc73bc956306059965ba168bf865a3a39c8`
**NormLab source:** main `e8041c937f28d3644d4df3680db5d81f0cff8ace`

## Evidence

| Check | Actual result and limit |
|---|---|
| Source baseline | NormLab remote main was read with ls-remote. Local attribution/trace/event/parking files match that committed baseline; NormLab worktree remains untouched. |
| Source consistency | Exact two action/six omission premise order/signs and ten scope arguments match the pinned ActionAttribution.lean definition. The separate negative-effect guard was checked. This is source inspection, not Lean execution. |
| Staged authoring | Intent, classification, model, critique, questions and assembled draft supplied; single-author curated work, no hosted inference or independent authoring agents. |
| Draft/check | Actual ontologyc validate-draft and check both pass without compiler/schema changes. Authoring/assembled YAML is byte-identical. |
| Vocabulary | 18 classes, 37 relations, 8 manual policies, 1 workflow lifecycle. Actor/duty bearer/human anchor and trigger/authority are separate. |
| Determinism | Two fresh final compilations yield byte-identical sets of all ten IR/SDK files and match committed baseline. |
| External references | CI smoke checks four event-core class refs against actual local event-core IR and the mapping's exact event vocabulary pin. |
| TypeScript | npm run typecheck and runtime smoke pass. New smoke exercises object discriminators, missing required fields and wrong primitive types. It does not validate graph links, enum strings or nonempty text. |
| Compiler regression | Actual full RUN_COVERAGE=1 tools/swift-quality.sh passes Node24/format/lint/import checks and all 143 existing Swift tests. No new Swift tests or sources were added. |
| Coverage | Configured llvm-cov TOTAL line 89.58%, region 78.41%; includes dependency/vendor code. This is compiler coverage, not responsibility-model accuracy or completeness. |
| Existing graph | Existing InstanceGraph fixture/export smoke passes unchanged, including its documented expected-pass provenance limitation. |
| Documentation | 40 relative Markdown references resolved before archive; whitespace checks pass. |
| CI integration | Adds responsibility draft/check/compile/generated/import-pin smoke and includes new TS object schemas. Hosted checks must be read on the published head. |

## Commands and artifact routing

After verifying the external TB5 volume, compiler outputs, temporary/LLVM profile
files, Swift scratch/cache/module outputs and supported Node caches were routed
to the per-checkout external paths. Existing Node dependencies were reused; no
dependency installation, migration or source relocation occurred.

```sh
ontologyc validate-draft SPECS/ontology/packages/responsibility-core/authoring --out <external-evidence>/draft-final.yaml
ontologyc check SPECS/ontology/packages/responsibility-core/domain-ontology-package.yaml
ontologyc compile SPECS/ontology/packages/responsibility-core/domain-ontology-package.yaml --target typescript --out <external-evidence>/compile-final-a
ontologyc compile SPECS/ontology/packages/responsibility-core/domain-ontology-package.yaml --target typescript --out <external-evidence>/compile-final-b
RUN_COVERAGE=1 ONTOLOGY_SWIFT_SCRATCH_PATH=<external-swiftpm> bash tools/swift-quality.sh
ONTOLOGYC_RESPONSIBILITY_BINARY_PATH=<external-binary> bash tools/responsibility-core-smoke.sh
ONTOLOGYC_INSTANCE_BINARY_PATH=<external-binary> bash tools/instance-graph-smoke.sh
npm run typecheck
npm run smoke
```

Quality evidence is `ont-044-quality.log` in the external build root. The local
toolchain still reports native-build-system deprecation; the process-local
cache/native wrapper is unchanged. CI contains no machine-specific paths.

## Corrections during implementation

Added a separate responseRuleAuthorityCondition after source/model review; trigger
and authority are different conditions. Repeated final draft/check/compile and
TS/import-pin smoke after that change. The original event-core YAML/IR/SDK,
eventcore-v1 contract, compiler sources/tests and NormLab are unchanged.

## Mapping boundaries and remaining work

NormLab R3 Scope has no independent duty bearer, duty ID, response-rule ID or
clockKey argument. Explicit external identity/time/alignment/applicability
decisions are not certified merely by mapping required+ or another predicate.
Human status requires a typed IsHuman proof; the public bound API requires a
registered event/interpretation, not a free serialized Scope.
R3 does not compare the external ActionRequirement to context.action and has no
direct StateRequirement condition slot; both need explicit separate mappings.
Source-only InterpretationCandidates stay outside the bound assessment path.

Source support IDs and Lean literal values are different. Preserving a Tree
under deletion does not by itself preserve Profile.check after additions of
opposite premises/negative effect. The draft mapping states the whole gate and
does not implement it again. Examples are conceptual expected cases from pinned
source, not executed adapter results.

The new responsibility classes are not admitted by the existing eventcore-v1
InstanceGraph validator. Cross-node responsibility mapping/validation remains a
future consumer contract decision in ONT-045; this package adds no runtime graph
profile, Lean adapter, legal rules, sanction, deployment or inference calls.
ONT-045 must create/link its NormLab canonical Issue before consumer code changes;
it must keep missing physical states source-only. ONT-047 owns snapshot provenance.


## 2026-10-28 — Integration with merged ONT-047

Merged main at 61b1e9a (PR #69) into the ONT-044 branch. Resolved only shared
CI/package-smoke/archive/next-task bookkeeping conflicts. Both CI gates and all
four TypeScript smoke programs are retained. The responsibility package, its
source mapping, generated files and smoke implementation are byte-identical to
the previously reviewed e8bb93a tree. Compiler Sources/Tests match main exactly.

The full quality gate passes 159 tests, format/lint/import checks, with configured
TOTAL line coverage 89.87%. TypeScript typecheck/runtime smoke and responsibility,
provenance (18 static cases) and legacy instance-graph fixture/export gates pass.
Local outputs remain on TB5; full quality log is ont-044-merge-quality.log in the
checkout's external build root. Hosted CI of the integration head remains pending.
