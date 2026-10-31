# REVIEW REPORT — ONT-058 Relations View and Selected Imports

**Scope** `feature/ONT-056-package-visualization..HEAD`, self-review on 2026-10-31.

## Verdict

Approve for external review following passing local gates. Hosted CI remains a
separate PR result. FOLLOW-UP is skipped with no unresolved implementation finding.

## Correctness and architecture

- The existing diagram API delegates to a typed-options overload. A byte comparison
  against the existing DOT fixture protects the default full view. Relations view
  changes only the projection and retains all root relations.
- Explicit local package sources reuse the compiler's parser/validator/normalizer.
  Named rules bind semantic id/version values and namespace scopes. The supplied
  source's canonical namespace is distinct from the root alias. Unknown selectors
  and duplicate/ambiguous bindings fail before rendering.
- Cross-package relation refs map by declared package identity/version. A cyclic
  reference back to the already loaded root resolves without recursive I/O.
  Selection order and supplied-package order produce equal DOT.
- Imported oneOf relations are omitted wholesale unless every endpoint is visible.
  Root alternatives remain complete. The caption and documentation identify this
  view as a selected subgraph, so omitted declarations do not imply their absence.
- Imported class labels carry their source package/version. They are type nodes;
  distinct own/effect record occurrences remain one shared type. The documentation
  distinguishes these schemas from instance identity, truth and causal evidence.
- All package inputs, including imports, are checked against destination paths.
  Existing staging, renderer-failure preservation and atomic per-file publication
  remain exercised. No new subprocess, network discovery or output format was added.

## Verification and review corrections

All 195 tests, lint, format/build and coverage mode passed. Sixteen new tests cover
binding predicates, projection selection, aliases, oneOf, cycles, legacy bytes and
actual SVG/PNG CLI execution. Eight generated-package baselines, TypeScript smoke
and both DocC catalogs with warnings-as-errors passed. The real motivation-core
raster was inspected and reordered-selector DOT compared byte-for-byte.

The binding inputs were aligned with the repository's existing semantic ID,
namespace and version value types. A test's invalid-namespace example was corrected
to an underscore because the established namespace grammar allows hyphens. The
DocC command's missing external parent directory was created before a successful
rerun. No product defect or documentation warning remains from these corrections.

## Handoff

The branch is a dependent layer over ONT-056 PR #81 in the same worktree. Preserve
that base and retain the worktree for stack review, then retire it after merge.
Reusable selection profiles can be a later ergonomics task. The foundation-export
and release-binary work remain independently owned.
