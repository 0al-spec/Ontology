# ONT-042: Draft Event Core Package

**Date:** 2026-10-27
**Status:** PRD Ready
**Priority:** P1
**Phase:** Event and Responsibility Core
**Reasoning Effort:** high
**Dependencies:** ONT-041, merged PR #65
**Branch:** `codex/ont-042-draft-event-core`

## Objective

Materialize the reviewed event/state/interpretation vocabulary as a small draft
package using the existing compiler. Preserve arbitrary Entity actors, source
provenance and observation availability. This task describes contracts; it does
not implement whole-graph validation, exact diff execution or new Lean proofs.

## Deliverables and acceptance

| ID | Output | Acceptance |
|---|---|---|
| D1 | `SPECS/ontology/packages/events-core/authoring/` | Source intent, domain/behavior framing and the four `validate-draft` artifacts retain provenance and unresolved ONT-043 questions. |
| D2 | `SPECS/ontology/packages/events-core/domain-ontology-package.yaml` | `org.0al.events.core@0.1.0`, namespace `eventcore`, stays draft; current `ontologyc check` passes without compiler/schema changes. |
| D3 | `SPECS/ontology/packages/events-core/generated/` | Ten compiler-generated IR/SDK files; two independent compilations are byte-identical. |
| D4 | Package README and conceptual examples | Hurricane, abstract community, car actor/instrument readings and source-only unknown observations are shown with explicit structural/semantic limits. |
| D5 | Validation and self-review | Draft/check/compile results, generated TypeScript checks and existing compiler quality gates recorded with actual outcomes. |

CI will also validate this package through the existing CLI, compare freshly
generated output to the committed baseline, and include its generated TypeScript
in the existing typecheck. This is a narrow artifact-drift check, not a new test
framework or instance semantic validator.

## Design constraints

- Use ordinary classes/relations/policies/state machines. Do not expand existing
  foundation Actor kinds or introduce executable expressions.
- State observations with unavailable or partial content remain distinct from
  known empty snapshots. Candidate events/interpretations need not become
  checked records; exact Delta is unavailable without known comparable states.
- Roles belong to interpretations; general actors do not require human status.
  Duty, human attribution and sanctions remain outside this package.
- Policies describe expected invariants and are manual review data. Generated
  schemas do not enforce relation cardinality, source relevance or graph integrity.
- Examples are conceptual design data, not a prematurely standardized InstanceGraph
  wire format. Typed reference/enum/graph-validation decisions belong to ONT-043.

## Execution plan

| Phase | Inputs | Outputs | Verification |
|---|---|---|---|
| 1. Frame | Merged proposal, pinned NormLab definitions | Intent, governing concept, candidate vocabulary, behavior/policy analysis and critique | Review the stages before YAML assembly; no paid inference or delegated authoring. |
| 2. Assemble | Reviewed draft | Package with classes, typed relation definitions and manual invariant policies | `validate-draft`, `check`; package remains draft with explicit exclusions. |
| 3. Compile | Checked package | Deterministic IR/SDK and conceptual examples | Compile twice into distinct TB5 directories; compare all ten artifacts; typecheck generated TS. |
| 4. Verify/deliver | Package and existing regressions | Validation, archive, self-review and PR | Existing Swift quality/coverage gate and documentation/path checks; inspect scope. |

## Validation plan

Run existing checks rather than add tests that only mirror a vocabulary list.
Use real compiler CLI validation on the new artifacts and a second independent
compile to verify determinism. Run generated TypeScript checks and the existing
Swift quality/coverage gate. Record any unrelated regression failures rather
than silently weaken a gate. Future semantic tests described by CQ-01–14 stay
planned for ONT-043/044; no semantic checker is claimed here.

Before artifact-producing commands, verify TB5 with the supplied skill helper
and route Swift scratch/cache, temporary outputs and supported package caches
there. Do not migrate/delete existing caches. No registry publication, paid
models, production changes or NormLab edits are in scope.

## Documentation updates

Link the package from README, record completed ONT-042 acceptance in Workplan,
then archive this PRD/report and its self-review. Point next.md to the next
candidate without automatically implementing ONT-043/044.
