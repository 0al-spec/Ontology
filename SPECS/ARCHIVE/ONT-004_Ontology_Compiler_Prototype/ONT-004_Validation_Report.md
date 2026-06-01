# ONT-004 Validation Report

**Task:** ONT-004 - Ontology Compiler Prototype  
**Date:** 2026-06-01  
**Verdict:** PASS

## Scope Validated

- Swift Package Manager executable target `ontologyc`.
- YAML parsing through `Yams` as inert data.
- `ontologyc check` for canonical valid packages and ONT-002 invalid fixtures.
- `ontologyc compile` from canonical `examcalc` package to deterministic normalized IR and TypeScript SDK artifacts.
- Invalid compile fails before output emission.
- ONT-004 implementation and generated artifacts contain no Ruby implementation dependency.

## Commands

```bash
test -f README.md
test -f SPECS/Workplan.md
swift build
.build/debug/ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
.build/debug/ontologyc check SPECS/ontology/fixtures/valid/minimal-domain-ontology-package.yaml
for f in SPECS/ontology/fixtures/invalid/*.yaml; do
  if .build/debug/ontologyc check "$f" >/tmp/ontologyc-invalid.out 2>&1; then
    echo "UNEXPECTED_PASS $f"
    exit 1
  else
    echo "EXPECTED_FAIL $f"
  fi
done
rm -rf /tmp/ontologyc-invalid-out
if .build/debug/ontologyc compile SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml --target typescript --out /tmp/ontologyc-invalid-out >/tmp/ontologyc-compile-invalid.out 2>&1; then
  exit 1
fi
test ! -e /tmp/ontologyc-invalid-out
.build/debug/ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/examcalc/generated
for f in ontology.normalized.json refs.ts types.ts relations.ts policies.ts state-machines.ts registry.ts validators.ts; do
  test -f "SPECS/ontology/packages/examcalc/generated/$f"
done
before=$(shasum -a 256 SPECS/ontology/packages/examcalc/generated/ontology.normalized.json | awk '{print $1}')
.build/debug/ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/examcalc/generated
after=$(shasum -a 256 SPECS/ontology/packages/examcalc/generated/ontology.normalized.json | awk '{print $1}')
test "$before" = "$after"
grep -R -n "Ruby\\|ruby" Package.swift Sources SPECS/INPROGRESS/ONT-004_Ontology_Compiler_Prototype.md SPECS/ontology/packages/examcalc/generated >/tmp/ontologyc-ruby-grep.out 2>&1; test $? -eq 1
```

## Results

| Gate | Result | Notes |
|---|---|---|
| Flow configured test gate | PASS | `README.md` exists |
| Flow configured lint gate | PASS | `SPECS/Workplan.md` exists |
| Swift build | PASS | `swift build` completed |
| Valid package checks | PASS | Canonical `examcalc` and minimal fixture pass |
| Invalid fixture checks | PASS | All ONT-002 invalid fixtures fail as expected |
| Invalid compile guard | PASS | Unsafe YAML compile exits non-zero and emits no output directory |
| Generated file existence | PASS | IR + 7 TypeScript SDK artifacts exist |
| Determinism | PASS | Repeated IR hash: `bb626c69bb0989ab6e7e5605e0dde73dee9e220b6b203d584924e22a6e20936d` |
| No Ruby dependency in ONT-004 | PASS | `Package.swift`, `Sources/`, ONT-004 PRD, and generated files contain no Ruby references |

Compiler outputs:

```text
ontologyc check: PASS SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
ontologyc check: PASS SPECS/ontology/fixtures/valid/minimal-domain-ontology-package.yaml
EXPECTED_FAIL SPECS/ontology/fixtures/invalid/invalid-inheritance.yaml
EXPECTED_FAIL SPECS/ontology/fixtures/invalid/missing-metadata.yaml
EXPECTED_FAIL SPECS/ontology/fixtures/invalid/unknown-relation-ref.yaml
EXPECTED_FAIL SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml
ontologyc compile: PASS SPECS/ontology/packages/examcalc/generated
```

## Generated Artifacts

| Artifact | Path |
|---|---|
| Normalized IR | `SPECS/ontology/packages/examcalc/generated/ontology.normalized.json` |
| Refs | `SPECS/ontology/packages/examcalc/generated/refs.ts` |
| Types | `SPECS/ontology/packages/examcalc/generated/types.ts` |
| Relations | `SPECS/ontology/packages/examcalc/generated/relations.ts` |
| Policies | `SPECS/ontology/packages/examcalc/generated/policies.ts` |
| State machines | `SPECS/ontology/packages/examcalc/generated/state-machines.ts` |
| Registry | `SPECS/ontology/packages/examcalc/generated/registry.ts` |
| Validators | `SPECS/ontology/packages/examcalc/generated/validators.ts` |

## Acceptance Mapping

| Acceptance Criterion | Evidence |
|---|---|
| Compiler parses YAML as inert data. | `Yams` parsing, static unsafe-content scan, unsafe fixture check failure |
| Compiler emits deterministic normalized IR. | `ontology.normalized.json`, repeated hash match |
| Compiler emits `refs.ts`, `types.ts`, `relations.ts`, `policies.ts`, `state-machines.ts`, `registry.ts`, and validators. | Generated file existence checks |

## Residual Risks

- The prototype does not implement production JSON Schema evaluation, registry resolution, lockfiles, or compatibility diffing.
- Generated TypeScript is not typechecked because the repository has no TypeScript toolchain configured.
- `Yams` is an external MIT-licensed parser dependency pinned by `Package.resolved`; future dependency updates should be reviewed explicitly.

