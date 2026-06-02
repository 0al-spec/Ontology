# ONT-026: Registry Publish Governance Gate

**Status:** PRD Ready
**Date:** 2026-06-03
**Priority:** P1
**Dependencies:** ONT-025

## Summary

Integrate governance decision validation into registry publication so trusted ontology
package publication requires a valid approved `OntologyGovernanceDecision` artifact.

## Problem

ONT-024 defines the governance decision artifact and ONT-025 validates it locally, but
registry publication can still happen without proving that a package was reviewed and
approved. That leaves a gap between the governance protocol and the distribution path
that SpecGraph and downstream agents are expected to trust.

## Goals

- Add a trusted publication mode to `ontologyc publish`.
- Require a governance decision artifact for trusted publication.
- Reuse the ONT-025 validation path before any registry network call.
- Reject trusted publication for missing, invalid, non-approved, mismatched, or
  evidence-failing decisions.
- Preserve existing candidate publication behavior by default.
- Document the publication policy boundary.

## Non-Goals

- No cryptographic signature verification.
- No registry server-side policy implementation.
- No changes to `pull` or `compat-check`.
- No mandatory governance for candidate/draft publication.
- No live external registry dependency in tests.

## Policy Boundary

`ontologyc publish` has two publication channels:

- `candidate` is the default channel and preserves current behavior. It is suitable for
  draft or integration publication and does not require a governance decision.
- `trusted` requires `--decision <decision.yaml>` and rejects publication unless the
  decision validates against the supplied package and has lifecycle state `approved`.

This keeps existing workflows compatible while making the trust boundary explicit for
registry consumers that depend on reviewed ontology packages.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Publish channel/gate argument model | `Sources/OntologyCompiler/CompilerArgumentTypes.swift` |
| D2 | Trusted publish gate in compiler/CLI path | `Sources/OntologyCompiler/OntologyCompiler.swift`, `Sources/OntologyC/main.swift` |
| D3 | CLI help and parsing updates | `Sources/OntologyC/CLIArguments.swift` |
| D4 | Registry and CLI regression tests | `Tests/OntologyCompilerTests/` |
| D5 | Documentation update | `README.md`, `SPECS/ontology/ontologyc.md`, `SPECS/ontology/governance-protocol.md` |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-026_Validation_Report.md` |

## CLI Shape

```bash
swift run ontologyc publish <package.yaml> \
  --registry <url> \
  [--token <token>] \
  [--channel candidate|trusted] \
  [--decision <decision.yaml>] \
  [--golden-report <golden-intent-validation-report.yaml>]
```

## Validation Requirements

Trusted publication must reject before the registry network call when:

- `--decision` is missing;
- `--channel` is unknown;
- the decision fails ONT-025 validation;
- the decision package id/namespace/version does not match the published package;
- the decision lifecycle state is not `approved`;
- the supplied golden intent validation report is failing.

Candidate publication must keep the existing publish contract. If a decision artifact is
supplied for candidate publication, it may be validated for author feedback, but it must
not become mandatory.

## Acceptance Criteria

- [ ] `ontologyc publish` accepts `--channel candidate|trusted` and `--decision`.
- [ ] Trusted publish requires a governance decision artifact.
- [ ] Trusted publish rejects non-approved governance decisions.
- [ ] Trusted publish rejects package/version mismatch and failing golden report evidence.
- [ ] Trusted rejection happens before any registry network call.
- [ ] Candidate publish remains backward compatible.
- [ ] Existing `pull` and `compat-check` behavior remains unchanged.
- [ ] Tests cover approval pass/fail behavior without a live registry.

## Validation Plan

- `git diff --check`
- Targeted registry/governance tests
- CLI regression tests
- `bash tools/swift-quality.sh`

## Potential Follow-Up

- Add registry-side enforcement metadata once a concrete registry implementation exists.
- Add signature verification for governance decisions.
