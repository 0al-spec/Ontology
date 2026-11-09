# ONT-088 — Imported protocol obligations

## Problem

The TypeScript SDK projects fields from explicitly supplied ancestors but
reports their protocol obligations as unverified even when the defining
protocol source is available. Protocol references belong to the namespace
scope of the package that declares `implements`.

## Outcome

Resolve inherited and directly implemented protocols against explicitly
supplied sources using the declaring package's bindings and exact package ID
and version. Project their verified instance obligations into both TypeScript
and Zod using the existing local-protocol contract. Preserve diagnostics and
incomplete-output warnings when an exact source is unavailable. Preserve the
separation between instance fields and declaration metadata and relations.

## Acceptance criteria

- Local, imported and transitive ancestors use their own aliases and exact
  source identities, including conflicting aliases in different packages.
- Existing required string fields of verified protocols appear in generated
  interfaces and schemas; incompatible instance fields are rejected.
- Missing, wrong-version or otherwise unavailable protocol sources produce
  an explicit warning; unrelated supplied sources do not satisfy the import.
- Duplicate requirements are deterministic; cycles remain diagnosed and do
  not produce a valid SDK. Relations and foundation declaration metadata are
  not synthesized as instance fields.
- Regressions exercise check and compile, actual TypeScript and Zod consumer
  behavior, missing sources, conflicts and source-scope alias binding.
- Run the project Swift quality gate and applicable SDK smoke tests using the
  verified external build/cache volume.

## Scope and worktree

Ontology owns the compiler contract and this change. No network dependency
resolution or automatic change to SpecGraph's pinned tool is implied by a
source build. Reuse `.worktrees/Ontology-action-reference` on
`feature/ONT-088-imported-protocol-obligations`; retire the execution worktree
after the task is merged and its remaining local state is accounted for.
