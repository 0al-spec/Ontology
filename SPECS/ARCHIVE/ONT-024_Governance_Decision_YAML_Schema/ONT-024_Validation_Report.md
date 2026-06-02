# ONT-024 Validation Report

**Task:** Governance Decision YAML Schema  
**Date:** 2026-06-03  
**Verdict:** PASS

## Scope

ONT-024 defines the governance decision artifact contract only. It adds a schema,
examples, and documentation links. It does not change compiler, CLI, registry, or
generated TypeScript behavior.

## Deliverable Verification

| Deliverable | Path | Status |
|-------------|------|--------|
| Governance decision YAML schema | `SPECS/ontology/governance-decision.schema.yaml` | PASS |
| Valid approval decision example | `SPECS/ontology/examples/governance/approved-decision.yaml` | PASS |
| Invalid agent approval example | `SPECS/ontology/examples/governance/invalid-agent-approval.yaml` | PASS |
| Governance protocol linkage | `SPECS/ontology/governance-protocol.md` | PASS |
| Authoring / compiler contract linkage | `SPECS/ontology/authoring-guide.md`, `SPECS/ontology/ontologyc.md` | PASS |

## Acceptance Criteria

| Criterion | Result |
|-----------|--------|
| Schema defines required top-level fields and lifecycle states | PASS |
| Schema distinguishes human reviewer authority from generated-agent evidence production | PASS |
| Valid approval example conforms to intended schema shape | PASS |
| Invalid agent approval example documents future rejection case | PASS |
| Governance protocol links to schema and examples | PASS |
| Authoring docs identify decision records as future publish-gate artifacts | PASS |
| No compiler, CLI, registry, or generated TypeScript behavior changes | PASS |

## Commands

```bash
git diff --check
test -f SPECS/ontology/governance-decision.schema.yaml
test -f SPECS/ontology/examples/governance/approved-decision.yaml
test -f SPECS/ontology/examples/governance/invalid-agent-approval.yaml
python3 - <<'PY'
import yaml
from pathlib import Path
for path in [
    'SPECS/ontology/governance-decision.schema.yaml',
    'SPECS/ontology/examples/governance/approved-decision.yaml',
    'SPECS/ontology/examples/governance/invalid-agent-approval.yaml',
]:
    with Path(path).open() as f:
        yaml.safe_load(f)
print('yaml parse: PASS')
PY
python3 - <<'PY'
import jsonschema
import yaml
from pathlib import Path
schema = yaml.safe_load(Path('SPECS/ontology/governance-decision.schema.yaml').read_text())
approved = yaml.safe_load(Path('SPECS/ontology/examples/governance/approved-decision.yaml').read_text())
invalid = yaml.safe_load(Path('SPECS/ontology/examples/governance/invalid-agent-approval.yaml').read_text())
jsonschema.Draft202012Validator.check_schema(schema)
jsonschema.validate(approved, schema)
try:
    jsonschema.validate(invalid, schema)
except jsonschema.ValidationError:
    print('jsonschema smoke: PASS')
else:
    raise SystemExit('invalid example unexpectedly passed schema validation')
PY
bash tools/swift-quality.sh
```

## Results

- `git diff --check`: PASS
- File existence checks: PASS
- YAML parse smoke check: PASS
- JSON Schema smoke check: PASS
  - Valid approval example passes.
  - Invalid agent approval example fails as expected.
- `bash tools/swift-quality.sh`: PASS
  - SwiftFormat: 0/46 files require formatting
  - SwiftLint: 0 violations
  - Build: PASS
  - Tests: 66 passed, 0 failed

## Follow-Up

- ONT-025 should validate `OntologyGovernanceDecision` YAML deterministically with
  `ontologyc validate-governance-decision`.
- ONT-026 should use that validator as the registry publish governance gate.
