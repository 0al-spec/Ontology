# ONT-029: Agent Model Selection Guidance

**Status:** Archived
**Created:** 2026-06-04
**Priority:** P2
**Dependencies:** ONT-019, ONT-021, ONT-023

## Problem

Ontology authoring is described as a staged agent workflow, but the documentation does not
say how to choose models for each stage. Without guidance, operators may assume every
agent must use the strongest and most expensive model, even when downstream validation
shows that cheaper or faster models preserve the expected output quality.

## Goal

Document a validation-first model selection policy: choose the cheapest/fastest model that
satisfies the role contract, preserves golden-intent stability, passes the quality rubric,
and produces artifacts accepted by deterministic compiler/governance checks.

## Scope

- Add model selection guidance to the ontology authoring guide.
- Add a validation-boundary note to the induction protocol.
- Add a rubric note that model cost/latency is operational evidence, not semantic quality.
- Add a short README pointer for discoverability.

## Out of Scope

- Benchmark implementation.
- Provider-specific model recommendations.
- Compiler behavior changes.
- Governance schema changes.

## Acceptance Criteria

- Authoring guide gives role-level guidance for stronger vs cheaper models.
- Induction protocol states that model choice is operational and validation artifacts are
  normative.
- Quality rubric separates semantic quality from model cost/latency decisions.
- README links authors to role-specific model selection guidance.
- Documentation avoids universal claims about specific model families or providers.

## Validation

- Markdown links remain local and valid.
- `rg` confirms the guidance is discoverable from README and authoring docs.
- `bash tools/swift-quality.sh` remains green because no compiler logic changes are made.
