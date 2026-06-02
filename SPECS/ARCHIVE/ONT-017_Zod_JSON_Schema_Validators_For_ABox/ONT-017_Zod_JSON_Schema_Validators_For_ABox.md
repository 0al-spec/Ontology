# PRD: ONT-017 - Zod/JSON Schema Validators for ABox Instances

**Status:** Archived
**Priority:** P2  
**Phase:** Protocol Interfaces and Advanced Validation  
**Reasoning Effort:** medium  
**Dependencies:** ONT-016  

## TL;DR

`emitValidators` today only checks whether a string value is a known ontology ref alias. It
has no knowledge of ABox instance shape. This task extends the emitter to produce
runtime-usable Zod schemas (and, as a by-product, JSON Schema equivalents) for each class in
the ontology so that downstream code can parse and validate real domain objects in one line.

## Objective

Generate a `schemas.ts` file alongside the existing compiler outputs. The file exports one
Zod schema per ontology class, a discriminated-union `AnyOntologyEntity` schema, and a
`toJsonSchema()` utility that converts any class schema to JSON Schema draft-2020-12. The
schemas encode the `$type` discriminant, the `id` field, and — once ONT-016 lands — any
required fields contributed by implemented protocols.

## Background

`TypeScriptEmitter.swift::emitValidators` (line 139) presently ignores the `ir` parameter
entirely (`_ = ir`). The normalized IR already contains all the information needed to
generate structural schemas: class FQIDs for `$type` literals, protocol `requiredFields`,
and relation domain/range pairs for foreign-key fields. Zod was chosen because it is the
de-facto TypeScript runtime-validation library and ships its own `toJsonSchema()` function
since v3.24; consumers who prefer plain JSON Schema receive it through that single call.

## Scope

### In Scope

- **New emit function** `emitSchemas(_ ir: JSONObject) -> String` in
  `TypeScriptEmitter.swift`, wired into `emit()` → writes `schemas.ts`.
- **Per-class Zod schema** for every class in the IR:
  ```typescript
  export const ExamSchema = z.object({
    $type: z.literal("examcalc:Exam"),
    id: z.string().optional(),
  });
  export type Exam = z.infer<typeof ExamSchema>;
  ```
- **Protocol field injection** (conditional on ONT-016): if a class carries
  `implementedProtocols`, the generated schema is extended with the protocol's
  `requiredFields` as `z.string()` entries.
- **Discriminated union**: `AnyOntologyEntitySchema` covering all classes.
- **JSON Schema export helper**:
  ```typescript
  import { toJsonSchema } from "zod/v4";
  export function toJsonSchemaFor<T extends z.ZodTypeAny>(schema: T) {
    return toJsonSchema(schema);
  }
  ```
- **Updated `validators.ts`**: add `parseOntologyEntity(unknown): AnyOntologyEntity`
  convenience wrapper using `AnyOntologyEntitySchema.parse`.
- **`emitValidators` refactor**: replace the `_ = ir` no-op with real IR reads for ref
  guards (existing behavior preserved, ir is no longer ignored).
- **Regression tests**: hash the new `schemas.ts` output; add a TypeScript smoke test in
  the fixture folder that imports and exercises the generated schemas.
- **Zod declared as a peer dependency** in generated output header comment; not added to the
  Swift package itself.

### Out of Scope

- Relation-range validation (foreign-key checks against other ABox instances).
- Recursive or nested schema generation.
- OpenAPI schema output format.
- Zod v3 compatibility; target is Zod v4 (current).

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Schema emitter function | `Sources/OntologyCompiler/TypeScriptEmitter.swift` | `emitSchemas()` generates valid TypeScript; wired into `emit()` |
| D2 | Generated schemas file | `<out>/schemas.ts` | Exports one Zod schema per class, `AnyOntologyEntitySchema`, and `toJsonSchemaFor` |
| D3 | Updated validators | `<out>/validators.ts` | `parseOntologyEntity` wrapper exported; `_ = ir` no-op removed |
| D4 | Regression tests | `Tests/OntologyCompilerTests/` | `schemas.ts` hash recorded; existing hashes unchanged |
| D5 | Smoke fixture | `SPECS/ontology/typescript-smoke/examcalc-schemas.ts` | Demonstrates `ExamSchema.parse` and `toJsonSchemaFor(ExamSchema)` |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|----|-------------|---------------------|--------------|
| FR-001 | `schemas.ts` MUST be emitted alongside existing outputs for every `compile` invocation. | File present in output directory. | Regression test |
| FR-002 | Each class MUST produce a named Zod schema constant (`<ClassName>Schema`). | Count of schema exports equals count of classes in IR. | Regression hash |
| FR-003 | The `$type` field MUST use the class FQID as a Zod literal. | `z.literal("examcalc:Exam")` in `ExamSchema`. | Regression hash |
| FR-004 | `AnyOntologyEntitySchema` MUST be a `z.discriminatedUnion` on `$type`. | Type narrows correctly in TypeScript. | Smoke fixture |
| FR-005 | Protocol `requiredFields` MUST appear in conforming class schemas when ONT-016 is implemented. | `SignableSchema` fields present in `ExamSchema` if `Exam implements Signable`. | Conditional regression test (enabled post ONT-016) |
| FR-006 | `toJsonSchemaFor` MUST produce valid JSON Schema draft-2020-12. | Output passes `ajv` validation in the smoke fixture. | Smoke fixture |
| FR-007 | Packages without protocols MUST generate identical schemas to today's behavior. | All pre-existing hashes pass. | Regression suite |
| FR-008 | Generated `schemas.ts` header MUST document the required Zod version (`zod@^4`). | Comment present in generated file. | Regression hash |

## Implementation Roadmap

### Phase 1 — Emitter

1. Add `emitSchemas(_ ir: JSONObject) -> String` to `TypeScriptEmitter.swift`.
2. Wire `emitSchemas` into `emit()` → `schemas.ts`.
3. Remove `_ = ir` no-op from `emitValidators`; read class FQIDs for the existing ref guard
   (behavior unchanged, compiler warning eliminated).
4. Add `parseOntologyEntity` to `emitValidators` output.

### Phase 2 — Protocol Integration Hook

5. Add conditional path in `emitSchemas` that reads `implementedProtocols` and injects
   required fields if present (no-op when array is absent or empty, so it compiles today
   and activates after ONT-016).

### Phase 3 — Tests and Fixtures

6. Update regression baselines with new `schemas.ts` hash.
7. Add `examcalc-schemas.ts` smoke fixture to `SPECS/ontology/typescript-smoke/`.
8. Document Zod peer-dependency requirement in `SPECS/ontology/ontologyc.md`.
