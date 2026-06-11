# ONT-035 Validation Report

**Task:** SpecGraph Proposal 0060 Minimal Consumer Slice
**Date:** 2026-06-11
**Verdict:** PASS

## Summary

ONT-035 produced the first bounded SpecGraph-side proposal 0060 consumer slice and linked
Ontology documentation back to it.

SpecGraph PR: <https://github.com/0al-spec/SpecGraph/pull/522>

## SpecGraph Evidence

SpecGraph branch: `codex/ontology-0060-consumer-slice`

Implemented surfaces:

- `tools/ontology_import_policy.json`
- `tools/ontology_imports.py`
- `tests/fixtures/ontology_import/examcalc/import-fixture.yaml`
- `tests/fixtures/ontology_import/examcalc/ontology.normalized.json`
- `tests/test_ontology_import_policy.py`
- `Makefile` target: `ontology-imports`
- proposal runtime registry markers for proposal `0060`

The slice consumes an Ontology-generated examcalc normalized IR fixture, resolves known
refs (`examcalc:Exam`, `examcalc:requires_policy`), and emits an explicit ontology gap for
`examcalc:CASFunction`.

## SpecGraph Checks

Local runs used a Python 3.10 interpreter with PyYAML available; commands below use the
portable `python3.10` spelling instead of a machine-specific interpreter path.

| Command | Result |
|---------|--------|
| `PYTHON=python3.10 make ontology-imports` | PASS |
| `python3.10 -m pytest tests/test_ontology_import_policy.py` | PASS, `5 passed` |
| `PYTHON=python3.10 make proposal-tracking-gate` | PASS, `blocking_count: 0` |
| `PYTHON=python3.10 make test` | PASS, `1001 passed` |
| `python3.10 -m ruff check tools/ontology_imports.py tests/test_ontology_import_policy.py` | PASS |
| `git diff --check` | PASS |

## Ontology Checks

| Command | Result |
|---------|--------|
| `bash tools/swift-quality.sh` | PASS, SwiftFormat clean, SwiftLint clean, `93 tests` |
| `bash tools/typescript-smoke.sh` | PASS |
| `test -f README.md && test -f SPECS/Workplan.md` | PASS |
| `git diff --check` | PASS |

## Acceptance

- PASS: SpecGraph-side work consumes Ontology-generated normalized IR materialization
  instead of duplicating Ontology package semantics.
- PASS: Minimal binding resolves known examcalc refs.
- PASS: Missing `examcalc:CASFunction` produces an explicit ontology gap.
- PASS: Package index records package id, namespace, version, source URI, digest, and lock
  metadata.
- PASS: Ontology README and core contracts link to SpecGraph PR #522.
- PASS: SpecGraph tests validate the slice without a live HTTP registry.

## Residual Risk

SpecGraph PR #522 is open at validation time. ONT-035 closes the first consumer-slice
evidence loop, but the later stronger step is a real adapter/report contract that invokes
`ontologyc validate-specgraph` instead of consuming a checked-in IR fixture directly.
