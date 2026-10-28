# ONT-050 — Action Model Template

Date: 2026-10-28. Priority: P1. Review subject: ONT-050.

## Result

Deliver a reusable `ontology-action-model` skill and template for modeling a bounded
application behavior. The worked example treats one image as the same entity before
and after destructive encoding, with operator/encoder roles chosen by interpretation.
The goal evaluator accepts the transition, not just its final state: reducing a file
by 200 kB differs from making it at most 200 kB. The goal specifies a criterion;
an actor or evaluator performs the comparison.

## Deliverables

- Repository-owned skill with local discoverable installation, short entrypoint and
  self-contained modeling reference, reusable worksheet and image-encoding example.
- Explicit goal input/units/constraints, `satisfied`, `not_satisfied` and `unknown`
  evaluation outcomes. Missing states never become zero values or empty Delta.
- Two role interpretations of one transition and optional decomposition into events.
- BDD/Gherkin mapping with concrete examples, plus meaningful PBT properties,
  preconditions, counterexamples and an honest automation boundary.
- README/authoring navigation; existing ontology packages and profile bytes unchanged.

## Scope and validation

This is a documentation and skill deliverable, not a new DomainOntologyPackage,
InstanceGraph schema, goal DSL/interpreter, codec or executable app test suite.
The existing agency content supports descriptive transition conditions, but its
reference consumer does not execute goal predicates.

Validate skill frontmatter/resources, Markdown local links, Gherkin syntax with an
official parser, example arithmetic and a bounded independent forward exercise.
Run repository Markdown-scope gates (`test -f README.md`, `test -f SPECS/Workplan.md`)
and whitespace checks. No Swift/runtime implementation changes require rebuilding
the unchanged compiler locally; hosted CI is reported separately for the new head.
Temporary dependencies/output use verified TB5 paths, never the source tree.

## Workflow and ownership

This layer starts from ONT-049 (`a170fce`) because its vocabulary is a dependency;
the PR targets that feature branch, preserving its reviewable diff and commit history.
This is the task-specific stacked variation of FLOW's normal main-based BRANCH step.
Parent owns guide/example, navigation, FLOW, verification, installation and publication.
A delegated author owns only SKILL.md, UI metadata and the empty worksheet template.
Independent review is read-only. No merge, release, paid inference or NormLab change.

Complete SELECT/PLAN/EXECUTE/ARCHIVE/REVIEW/ARCHIVE-REVIEW checkpoints. Skip FOLLOW-UP
only if review has no remaining actionable findings. Restore ONT-045 as next candidate.
