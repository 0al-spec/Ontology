# Ontology Validation Report Template

**Task:** `{TASK_ID}`  
**Ontology:** `{ontology_id}@{version}`  
**Input:** `{path}`  
**Verdict:** `PASS | PARTIAL | FAIL`

## Summary

| Check | Result | Notes |
|---|---|---|
| Schema validation | `PASS | FAIL` | |
| Class inheritance | `PASS | FAIL` | |
| Protocol resolution | `PASS | FAIL` | |
| Relation domain/range | `PASS | FAIL` | |
| State machines | `PASS | FAIL` | |
| Policy applicability | `PASS | FAIL` | |
| Semantic refs | `PASS | FAIL` | |
| Compatibility | `PASS | FAIL | N/A` | |
| Security | `PASS | FAIL` | |
| Competency questions | `PASS | FAIL` | |

## Test Mapping

| Test ID | Description | Evidence | Result |
|---|---|---|---|
| T-001 | Package without `metadata.version` fails. | invalid fixture / diagnostic `metadata.required` | |
| T-002 | Class with two `extends` parents fails. | invalid fixture / diagnostic `class.extends.multiple` | |
| T-003 | Relation range points to unknown class fails. | invalid fixture / diagnostic `relation.range.unresolved` | |
| T-004 | `examcalc:ExamPolicyProfile` resolves. | resolver output canonical URI | |
| T-005 | Missing `examcalc:CASFunction` emits `OntologyGap`. | `OntologyGap` artifact | |
| T-006 | Golden compile emits stable IR and SDK file list. | file list + IR digest | |
| T-007 | Executable-looking YAML is inert or rejected. | diagnostic `security.executable_content` or scalar evidence | |
| T-008 | Relation range change is breaking. | compatibility report | |
| T-009 | Competency questions resolve or emit gaps. | competency validation output | |

## Diagnostics

| Code | Severity | Path | Message | Hint |
|---|---|---|---|---|

## Generated Artifacts

| Artifact | Present | Digest |
|---|---|---|
| `refs.ts` | | |
| `types.ts` | | |
| `relations.ts` | | |
| `policies.ts` | | |
| `state-machines.ts` | | |
| `registry.ts` | | |
| `validators.ts` | | |
| `ontology.normalized.json` | | |
| `ontology.schema.json` | | |
| `ontology.lock.yaml` | | |

## Security Notes

- Confirm YAML was parsed as data only.
- Confirm no hooks, factories, expressions, or generated code were executed.
- Confirm external references were resolved through declared import mechanisms only.

## Follow-Up

List unresolved gaps, deferred ABox work, compatibility risks, or reviewer follow-ups.
