# ONT-032 Validation Report

**Task:** ONT-032 Class Field Semantics And Rich SDK Generation
**Date:** 2026-06-11
**Verdict:** PASS

## Summary

ONT-032 adds first-class primitive class fields to `DomainOntologyPackage` and projects
them through schema validation, compiler validation, deterministic normalized IR, generated
TypeScript interfaces, generated Zod schemas, JSON Schema helper smoke coverage, and
compatibility reports.

The canonical `examcalc` package now carries a required `title` field and optional
`durationMinutes` field on `Exam`, and the committed generated artifacts are updated to
prove the SDK output is field-bearing.

## Changed Areas

| Area | Result |
|------|--------|
| Class field YAML schema | PASS |
| Field name/type/required validation | PASS |
| Deterministic normalized IR fields | PASS |
| TypeScript interface field emission | PASS |
| Zod schema field emission | PASS |
| JSON Schema helper smoke coverage | PASS |
| Compatibility field change buckets | PASS |
| Examcalc generated baselines | PASS |
| TypeScript smoke fixture | PASS |

## Validation Commands

```bash
swift test --filter OntologyRulesTests
```

Result: PASS. Field name/type specs and compatibility decision specs are covered.

```bash
swift test --filter TypeScriptEmitterTests
```

Result: PASS. Generated `types.ts` and `schemas.ts` include required and optional class fields.

```bash
swift test --filter PackageValidationTests
```

Result: PASS. Compiler validation accepts the supported field shape and rejects invalid
field declarations.

```bash
swift test --filter RegistryClientTests/testCompatibilityReportClassFieldChanges
```

Result: PASS. Compatibility reports classify added, removed, changed, and breaking class
field changes.

```bash
swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Result: PASS. The canonical examcalc package validates with class fields.

```bash
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/examcalc/generated
```

Result: PASS. Generated artifacts were refreshed and regression-locked.

```bash
swift test --filter OntologyCRegressionTests
```

Result: PASS. Generated artifacts, normalized IR hash, SpecGraph validation outputs, and
compatibility report baselines match committed files.

```bash
bash tools/typescript-smoke.sh
```

Result: PASS. The TypeScript smoke fixture type-checks and parses the field-bearing
`ExamSchema`.

```bash
bash tools/swift-quality.sh
```

Result: PASS. SwiftFormat, SwiftLint, build, and all `86` tests pass.

```bash
git diff --check
```

Result: PASS. No whitespace or patch-format issues.

## Acceptance Mapping

| Acceptance Criteria | Evidence |
|---------------------|----------|
| Schema accepts constrained class `fields` | `domain-ontology-package.schema.yaml` `$defs.classFieldDefinition` and `fieldName` |
| Validation rejects unsupported field types | `PackageValidationTests.testClassFieldsRejectInvalidShape` |
| Validation rejects invalid field names | `PackageValidationTests.testClassFieldsRejectInvalidShape` |
| Validation rejects non-boolean `required` | `PackageValidationTests.testClassFieldsRejectInvalidShape` |
| Normalized IR includes deterministic field metadata | Updated `examcalc/generated/ontology.normalized.json` and regression hash |
| `types.ts` projects required and optional fields | `TypeScriptEmitterTests.testEmitTypesProjectsClassFields` |
| `schemas.ts` projects required and optional fields | `TypeScriptEmitterTests.testEmitSchemasProjectsClassFields` |
| `toJsonSchemaFor` continues to work | `tools/typescript-smoke.sh` fixture assertions |
| Compatibility diff classifies class field changes | `RegistryClientTests.testCompatibilityReportClassFieldChanges` |
| TypeScript smoke covers required and optional fields | `examcalc-schemas.ts` parses `title` and `durationMinutes` |
| Full gates pass | `bash tools/swift-quality.sh`, `bash tools/typescript-smoke.sh`, `git diff --check` |

## Residual Risk

- Field types are intentionally limited to primitive scalars; references, enums, lists,
  units, and nested objects remain follow-up work.
- Protocol `requiredFields` and class-owned fields coexist but are not unified in this
  slice.
- Compatibility field buckets are now emitted for all reports, including empty arrays, so
  downstream consumers should tolerate the new keys.

## Potential Next Step

Run ONT-033 to add file/git registry transport so `publish`, `pull`, and `compat-check`
can be dogfooded without waiting for a reference HTTP registry service.
