# ONT-037 Validation Report

**Task:** SpecGraph Owner Decision Report Export
**Branch:** `codex/ont-037-specgraph-owner-decisions`
**Date:** 2026-06-14
**Verdict:** PASS

## Summary

ONT-037 adds an Ontology-owned export path for SpecGraph owner decisions. The
new `ontologyc export-specgraph-owner-decisions` command reads an inert owner
decision set, validates accepted, rejected, and needs-clarification decisions,
and writes a deterministic `ontology_owner_decision_report` for SpecGraph and
SpecSpace review surfaces.

The report is evidence only. It does not import decisions into SpecGraph, close
semantic gates, mutate canonical specs, write Ontology packages, or update
lockfiles.

## Changed Areas

- `Sources/OntologyCompiler/SpecGraphOwnerDecisionExport.swift`
  - Adds the owner decision set parser, validator, deterministic JSON report
    builder, source artifact checks, state checks, accepted-flag consistency,
    and false authority-boundary enforcement.
- `Sources/OntologyC/main.swift`
  - Adds the `export-specgraph-owner-decisions <decisions.yaml> --out
    <report.json>` CLI command.
- `Sources/OntologyC/CLIArguments.swift`
  - Documents the new command in root help and command-specific usage.
- `SPECS/ontology/examples/specgraph-owner-decisions/`
  - Adds an example decision set with accepted, rejected, and
    needs-clarification owner decisions.
- `Tests/OntologyCompilerTests/SpecGraphOwnerDecisionExportTests.swift`
  - Covers deterministic report shape, summary counts, false authority flags,
    CLI output, accepted-flag mismatch rejection, invalid-state rejection, and
    no-report-on-invalid-input behavior.
- Documentation
  - README, `SPECS/ontology/core-contracts.md`,
    `SPECS/ontology/ontologyc.md`, and DocC describe the review-only boundary.

## Validation Commands

```bash
swiftformat Sources Tests --lint
```

Result:

- PASS
- SwiftFormat lint mode reports 0/63 files require formatting, 2 skipped.

```bash
swiftlint lint --config .swiftlint.yml
```

Result:

- PASS
- SwiftLint reports 0 violations, 0 serious in 63 files.

```bash
bash tools/check-github-actions-node24.sh
```

Result:

- PASS

```bash
bash tools/typescript-smoke.sh
```

Result:

- PASS
- `tsc --project typescript-smoke/tsconfig.json --noEmit`
- `tsx typescript-smoke/examcalc-schemas.ts`

```bash
git diff --check
```

Result:

- PASS

Remote PR validation:

- PR #55 `Build DocC` — PASS.
- PR #55 `Lint, format, test, coverage` — PASS.
- PR #55 review thread about private diagnostic sorting was fixed in
  `c40e035` and resolved.

Local Swift test commands:

```bash
swift test --filter SpecGraphOwnerDecisionExportTests
```

```bash
bash tools/swift-quality.sh
```

Result:

- BLOCKED locally before Ontology targets compile.
- Apple Swift version:
  `Apple Swift version 6.3.2 (swiftlang-6.3.2.1.108 clang-2100.1.1.101)`.
- Failure is in remote dependency `SpecificationCore` 1.0.0:

```text
SpecificationCore/Sources/SpecificationCore/Specs/FirstMatchSpec.swift:206:13:
error: ambiguous use of 'init(_:includeMetadata:)'
```

## Dependency Check

```bash
git ls-remote --tags https://github.com/SoundBlaster/SpecificationCore.git
```

Result:

- Only tag `1.0.0` is published.
- `Package.resolved` is already pinned to `SpecificationCore` revision
  `af5b0642282541ae36baffd1328a5dd7c5e61146`, version `1.0.0`.
- No safe patch-version dependency bump is available for this ONT-037 slice.

## Acceptance Criteria

- [x] Defines an Ontology-side owner decision input fixture for SpecGraph delta
      candidates.
- [x] Emits deterministic `ontology_owner_decision_report` JSON compatible with
      the SpecGraph read-only decision report contract.
- [x] Supports `accepted`, `rejected`, and `needs_clarification`.
- [x] Preserves explicit false authority flags for SpecGraph import, semantic
      gate closure, canonical spec mutation, Ontology package writes, and
      lockfile updates.
- [x] Adds tests and docs showing the report is owner-decision evidence, not an
      automatic package or SpecGraph mutation.
- [x] Full Swift quality execution is proven by GitHub PR #55.

## Residual Risks

- Local Apple Swift 6.3.2 still cannot compile `SpecificationCore` 1.0.0
  before Ontology code is built. Remote PR validation passed, so this remains a
  local toolchain/dependency compatibility risk rather than an ONT-037 blocker.
- This slice emits owner decision evidence only. A later slice can connect the
  exporter to registry-backed owner workflow state, signatures, or trusted
  publication decisions.
