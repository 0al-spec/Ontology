# ONT-032: Class Field Semantics And Rich SDK Generation

**Status:** PRD Ready
**Priority:** P0
**Phase:** SpecGraph Value Loop Closure
**Reasoning Effort:** high
**Dependencies:** ONT-030, ONT-031

## TL;DR

Add first-class data fields to ontology classes and project them through the whole compiler
surface: YAML schema, validation, normalized IR, generated TypeScript interfaces, generated
Zod schemas, JSON Schema helper output, compatibility reports, and the TypeScript smoke
gate.

This is the first slice that makes the generated SDK model actual data shape rather than
only concept identity, protocol interfaces, and semantic reference constants.

## Problem

The current generated SDK is type-safe for concept identity but semantically thin for
consumer data. Class interfaces currently contain only `$type` and optional `id`, while
Zod schemas parse the same minimal shape. Protocol `requiredFields` can force string fields
through emitted TypeScript interfaces, but class-owned data fields are not part of
`DomainOntologyPackage`.

That leaves three gaps:

- TypeScript consumers cannot rely on generated class data shapes.
- Zod/JSON Schema smoke coverage does not prove field-bearing SDK output.
- Compatibility reports cannot detect field additions, removals, type changes, or
  requiredness changes.

## Goals

1. Add a constrained `fields` section to class definitions.
2. Validate field names, field types, and required/optional declarations.
3. Normalize fields deterministically into `ontology.normalized.json`.
4. Emit field-bearing TypeScript interfaces and Zod schemas.
5. Extend compatibility reports for class field changes.
6. Update committed examcalc generated artifacts and TypeScript smoke coverage.

## Non-Goals

- No ABox instance validation implementation.
- No nested object, list, reference, enum, unit, or custom scalar fields in this slice.
- No changes to relation semantics or protocol conformance rules beyond coexistence with
  class fields.
- No registry transport work.
- No SpecGraph repository changes.
- No runtime execution of ontology YAML or generated SDK during `ontologyc check`.

## Field Syntax

Fields live under each class definition:

```yaml
classes:
  Exam:
    extends: sg:DomainEntity
    description: Exam definition.
    fields:
      title:
        type: string
        required: true
        description: Human-readable exam title.
      durationMinutes:
        type: integer
        required: false
        description: Planned exam duration in minutes.
```

Supported field types:

| YAML Type | TypeScript | Zod |
|-----------|------------|-----|
| `string` | `string` | `z.string()` |
| `boolean` | `boolean` | `z.boolean()` |
| `integer` | `number` | `z.number().int()` |
| `number` | `number` | `z.number()` |

Field names must be TypeScript-safe identifiers using lower-camel or lower-snake style:
`^[a-z][A-Za-z0-9_]*$`.

## Normalized IR

Each normalized class should include a sorted `fields` array only when fields exist:

```json
{
  "id": "Exam",
  "fqid": "examcalc:Exam",
  "fields": [
    {
      "id": "durationMinutes",
      "type": "integer",
      "required": false,
      "description": "Planned exam duration in minutes."
    },
    {
      "id": "title",
      "type": "string",
      "required": true,
      "description": "Human-readable exam title."
    }
  ]
}
```

The order must be deterministic by field id.

## Generated SDK Contract

`types.ts` should emit class fields into the corresponding interface:

```ts
export interface Exam {
  readonly $type: "examcalc:Exam";
  readonly id?: string;
  readonly durationMinutes?: number;
  readonly title: string;
}
```

`schemas.ts` should emit matching Zod schemas:

```ts
export const ExamSchema = z.object({
  $type: z.literal("examcalc:Exam"),
  id: z.string().optional(),
  durationMinutes: z.number().int().optional(),
  title: z.string(),
});
```

`toJsonSchemaFor(ExamSchema)` should continue to work through the existing Zod helper.

## Compatibility Contract

Compatibility reports must include field-level changes in deterministic order.

Suggested change buckets:

- `addedFields`
- `removedFields`
- `changedFields`
- `breakingChanges`

Compatibility rules:

| Change | Compatibility |
|--------|---------------|
| Add optional field | compatible |
| Add required field | breaking |
| Remove any field | breaking |
| Change field type | breaking |
| Change required `false -> true` | breaking |
| Change required `true -> false` | compatible |
| Change description only | compatible |

The breaking decisions should live in `OntologyRules` as `SpecificationCore`-backed
decision specs rather than inline compiler conditionals.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Schema field definitions | `SPECS/ontology/domain-ontology-package.schema.yaml` |
| D2 | Field validation specs/types | `Sources/OntologyRules/` |
| D3 | Compiler validation and normalized IR | `Sources/OntologyCompiler/PackageValidation.swift`, `Normalization.swift` |
| D4 | TypeScript/Zod emitter updates | `Sources/OntologyCompiler/TypeScriptEmitter.swift` |
| D5 | Compatibility field change classification | `Sources/OntologyRules/CompatibilityDecisionSpecs.swift`, `Sources/OntologyCompiler/CompatibilityDiff.swift` |
| D6 | Examcalc fixture/generated baseline updates | `SPECS/ontology/packages/examcalc/` |
| D7 | TypeScript smoke fixture update | `SPECS/ontology/typescript-smoke/examcalc-schemas.ts` |
| D8 | Unit/regression tests | `Tests/OntologyRulesTests/`, `Tests/OntologyCompilerTests/` |
| D9 | Validation report | `SPECS/INPROGRESS/ONT-032_Validation_Report.md` |

## Acceptance Criteria

- [ ] `domain-ontology-package.schema.yaml` accepts constrained class `fields`.
- [ ] Compiler validation rejects unsupported field types.
- [ ] Compiler validation rejects invalid field names.
- [ ] Compiler validation rejects non-boolean `required` declarations.
- [ ] Normalized IR includes deterministic field metadata.
- [ ] Generated `types.ts` projects required and optional fields correctly.
- [ ] Generated `schemas.ts` projects required and optional fields correctly.
- [ ] `toJsonSchemaFor` continues to work for field-bearing schemas.
- [ ] Compatibility diff classifies field additions/removals/type changes/requiredness changes.
- [ ] TypeScript smoke covers at least one required and one optional field.
- [ ] Full Swift quality gate and TypeScript smoke gate pass.

## Validation Plan

- `swift test --filter OntologyRulesTests`
- `swift test --filter OntologyCompilerTests`
- `swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml`
- `swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/examcalc/generated`
- `bash tools/typescript-smoke.sh`
- `bash tools/swift-quality.sh`
- `git diff --check`

## Risks

| Risk | Mitigation |
|------|------------|
| Field semantics become too broad | Limit ONT-032 to primitive scalars only. |
| Emitter and normalized IR drift | Update regression baselines and TypeScript smoke together. |
| Compatibility reports get noisy | Track deterministic field buckets and only mark truly breaking field changes as breaking. |
| Protocol requiredFields and class fields conflict | Keep protocol fields as TypeScript protocol obligations; class fields are class-owned data. Follow-up can unify them if needed. |

## Potential Next Step

After ONT-032, run ONT-033 to dogfood registry publish/pull/compat-check through a local
file/git-backed registry transport.
