# ONT-028: Node24 Cache Action Migration

**Status:** PRD Ready
**Created:** 2026-06-03
**Priority:** P2
**Dependencies:** ONT-027

## Problem

ONT-027 introduced GitHub Actions cache layers with `actions/cache@v4`. GitHub Actions
now annotates those steps because v4 targets the Node20 action runtime. The current
workflow-level `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` forces execution on Node24, but
the annotation remains because the action metadata still declares Node20.

`actions/cache@v5` is the Node24-native release and keeps the cache inputs used by the
Ontology workflows.

## Scope

- Replace `actions/cache@v4` with `actions/cache@v5` in Swift Quality.
- Replace `actions/cache@v4` with `actions/cache@v5` in DocC documentation workflow.
- Remove `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24` from workflows after the v5 migration.
- Update cache policy documentation to record the Node24 action boundary.

## Out of Scope

- Cache key redesign.
- Cache path changes.
- Custom zip-pack build cache.
- Swift package, compiler, or documentation behavior changes.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Swift Quality cache action migration | `.github/workflows/swift-quality.yml` |
| D2 | DocC cache action migration | `.github/workflows/documentation.yml` |
| D3 | Cache policy update | `SPECS/ontology/ci-cache-policy.md` |
| D4 | Validation report | `SPECS/INPROGRESS/ONT-028_Validation_Report.md` |

## Acceptance Criteria

- Swift Quality cache steps use `actions/cache@v5`.
- DocC cache steps use `actions/cache@v5`.
- Workflow-level Node24 force environment variables are removed.
- `tools/ci-cache-key.sh` still emits GitHub-output-safe `name=value` lines.
- Local validation confirms no whitespace diff issues.
- PR CI passes for Swift Quality and DocC.

## Risks

- `actions/cache@v5` requires a GitHub Actions runner version new enough for Node24.
  GitHub-hosted runners satisfy this requirement.
- If any self-hosted runner is added later, it must meet the `actions/cache@v5` minimum
  runner version.
