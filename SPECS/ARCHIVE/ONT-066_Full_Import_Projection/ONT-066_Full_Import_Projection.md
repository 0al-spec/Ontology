# ONT-066 — Full import projection and filter counts

## Intent
The NormLab pilot exposes only classes and ontology relations in a combined
relations view. Users must be able to explore imported policies, protocols,
inheritance and lifecycle in full view, and see when a filter category is empty.

## Contract
- Full view loads every declaration from explicitly supplied exact direct imports.
  It does not fetch dependencies or recurse implicitly. Selective class expand
  remains a relations-only operation.
- Rebase semantic references into the root namespace scope. Preserve declaration
  source identity, YAML pointers and digests. Reject references that cannot be
  represented in the root scope rather than accidentally joining equal aliases.
- Unloaded root-declared dependencies remain explicit unresolved references.
- Deterministic JSON and DOT share the same projection.
- Filters display counts from the complete loaded canvas, independent of active
  filters; edge counts count visual links, including oneOf alternatives.
- Keep existing accessible filter labels, position preservation and CLI defaults.

## Acceptance and validation
Compiler/rule/CLI regressions cover full imports, alias rebasing for every
declaration family, deterministic import order, missing namespace binding and
unchanged relations selection. Viewer unit/browser checks cover zero/nonzero
counts and toggles without relayout. Run the repository Swift quality gate and
viewer build/unit/browser suite. Open full NormLab snapshots with real tools.
This validates structure and presentation, not semantic truth or policy execution.
