# ONT-041: Event And Responsibility Core Proposal

**Status:** PRD Ready
**Priority:** P1
**Phase:** Event and Responsibility Core
**Reasoning Effort:** high
**Dependencies:** ONT-040 (merged PR #61; archived)
**Branch:** `codex/ont-041-event-responsibility-proposal`

## Objective and scope

Document how the author's entity/action/relation/state model can become reusable
Ontology packages, with NormLab parking as the first consumer. Deliver a proposal
and staged acceptance criteria; do not implement a new package, compiler feature,
runtime, legal rule, or Lean backend in this task.

## Deliverables

| ID | Output | Acceptance |
|---|---|---|
| D1 | `SPECS/ontology/event-responsibility-core-proposal.md` | Explicit vocabulary, package ownership, invariants, uncertainty, diagrams, and a pinned NormLab mapping. |
| D2 | `SPECS/Workplan.md` | ONT-041 plus bounded follow-ups with dependencies and observable completion criteria. |
| D3 | `README.md` | Discoverable proposal link labelled as proposed work. |
| D4 | Validation and self-review records | Documentation checks, source inspection boundaries, and unchanged implementation paths recorded. |

## Functional requirements

- FR-001: Distinguish author intent, existing implementation, and proposed
  contracts. Actor is a role for any Entity; human attribution is separate.
- FR-002: Keep event observations separate from interpretations and operator
  review state. Consequence is the exact Added/Removed diff of comparable states.
- FR-003: Preserve explicit support, opposite support, unknown, and conflicts.
  Omission needs explicit grounds; a missing statement is not evidence of failure.
- FR-004: Separate generic event, responsibility-profile, and parking-package
  ownership. Preserve existing Ontology foundation kinds and inert YAML.
- FR-005: Map the actual NormLab R1–R4 contracts and UI source-role layer to
  commit-pinned code. Do not portray the runtime operator event as the parking act.
- FR-006: Specify competency questions and future positive/negative checks for
  duplicate IDs, wrong scope, source speakers, causal links, and conflicting facts.
- FR-007: Define the first useful offline parking acceptance and evidence boundary.

## Execution plan

| Phase | Inputs | Outputs | Verification |
|---|---|---|---|
| 1. Establish baseline | Existing compiler schema/IR and NormLab modules | Vocabulary, ownership and implementation-status tables | Inspect actual definitions at the cited commit; state missing capabilities. |
| 2. Design proposal | Author's principles and baseline | Package split, data-flow diagrams, graph-validation boundary and pilot | Each FR has an explicit section; examples preserve uncertainty and scope. |
| 3. Integrate roadmap | Proposal delivery stages | Small follow-up tasks, README link, validation report | Dependencies are acyclic, tasks have completion criteria, links resolve. |
| 4. Archive and review | Completed docs | Archived PRD/report and self-review; PR | Scoped diff check, configured documentation gates, inspect final PR contents. |

## Validation plan

For this documentation-only change, run the configured `.flow/params.yaml`
documentation gates (`test -f README.md`, `test -f SPECS/Workplan.md`), check
relative Markdown file/heading links in changed docs, review dependency ordering,
and run `git diff --check`. Verify no `Sources/`, `Tests/`, schema or generated
artifacts changed. Swift/TypeScript/Lean builds and tests are not necessary to
validate prose and must not be represented as newly passing.

Future implementation tasks must define focused positive/negative tests before
changing executable contracts, follow the repository's compiler quality gates,
and apply the user's TB5 build/cache policy for local artifact production.

## Boundaries and risks

The proposal does not establish factual truth, physical causation, legal
responsibility, or correctness of formalization. Existing `layer` and
`modelApplicability` metadata remain review data. The generic compiler must not
execute YAML expressions or infer applicability/roles from prose. No paid model
requests, publication, deployment, data migration, or cross-repo edits are needed.

## Documentation updates

Keep the proposal outside the archived task directory so it remains a stable
roadmap entry point. Archive this PRD and its validation/self-review artifacts
when the documentation deliverables are complete. Archive ONT-040 first while
retaining historical validation provenance; leave unrelated ONT-038/039 cleanup
unchanged.
