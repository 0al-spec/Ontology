# ONT-086 — TypeScript SDK inheritance

## Problem and evidence

SpecGraph's `GraphInvariant` migration exposed that ontologyc 0.10.0 preserves
semantic `extends` in normalized IR, but omits class inheritance from generated
TypeScript instance types and Zod schemas. The SpecGraph defect record is
`docs/reviews/0232_project_ontology_context/graph-invariant-typescript-defect.md`.

The foundation model describes ontology declarations, whereas `types.ts`
describes instances. Declaration properties such as `kind` and `appliesTo`
are not automatically instance properties. Instance `$type` is a per-class
discriminator, so direct extension of a fixed literal parent is incompatible.

## Outcome

Project verified class ancestry into generated instance types and schemas,
including inherited declared fields. Preserve exact concrete discriminators
and provide a usable structural supertype for callers that accept descendants.
Resolve explicitly supplied imported ancestors by package identity/version and
the declaring package's alias. Treat foundation declarations as a distinct
metadata layer. An unavailable ancestor must be identified rather than
invented; incompatible field definitions and inheritance cycles must not yield
an apparently valid inherited schema.

## Acceptance

- Local multi-level inheritance retains required and optional fields, exact
  discriminators and local protocol obligations; unrelated classes remain as
  before.
- A source-bound imported parent is selected by exact identity/version; aliases
  are interpreted in their declaring package. Missing or ambiguous source does
  not silently become a verified ancestor.
- Generated schemas enforce inherited fields consistently with the interfaces.
- Real strict TypeScript checks accept valid instances and reject missing
  inherited fields and incorrect discriminators. Runtime schema checks exercise
  the same examples. Regression cases cover cycles and conflicting fields.
- Document the declaration/instance boundary and the behavior of incomplete
  ancestry; do not infer `kind` or `appliesTo` as instance fields.
- Run the project quality gate and relevant SDK smoke checks with output on
  the configured external build volume.

## Worktree

Reuse `.worktrees/ont-sg-ss/Ontology-imported-typed-references` on branch
`feature/ONT-086-typescript-inheritance` through review, then account for
local data and retire it if no consumer needs it.
