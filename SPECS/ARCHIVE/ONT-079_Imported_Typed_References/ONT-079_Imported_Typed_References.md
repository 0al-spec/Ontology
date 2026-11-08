# ONT-079 — Imported typed reference targets

## Problem and outcome

An action field can reference a class in its own package, but cannot use the
same `Ref` form for a class from an imported package. SpecGraph therefore kept
second declarations of concepts that had already moved into its shared core.
An author should be able to use the existing class, with a verifiable package
identity and a correctly typed SDK and diagram connection.

## Scope

- Accept an imported class as a `ref` target only when its exact declared
  package ID and version, supplied explicitly as a local source, contain that
  class. Do not fetch packages or guess by bare name.
- Preserve the fully qualified target in normalized IR and the generated
  TypeScript/Zod contract; a reference with another target must fail.
- Rebase imported field targets in diagram projection using the declaring
  package's own namespace bindings, including a transitive import.
- Keep current local reference behavior and existing command invocations.

## Acceptance

1. A package can check and compile an action field targeting a class in a
   supplied exact import. Missing imports, wrong version, undeclared namespace
   and absent classes fail with actionable diagnostics.
2. Generated TypeScript and Zod preserve the external target's fully qualified
   identity and reject a different target. Local reference tests still pass.
3. A full diagram with explicit imports resolves the field to the correct
   target even when package namespaces are rebound in a parent composition.
4. Tests exercise an imported target, failures, and same-named classes from
   separate namespaces. No semantic equivalence or runtime resolution is implied.

## Out of scope

Automatic package discovery, network fetching, project-wide semantic
deduplication and migration of SpecGraph's existing model are separate work.

---
**Archived:** 2026-11-09
**Verdict:** PASS (local; hosted CI and review separate)
