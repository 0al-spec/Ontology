# ONT-082 — Resolve imported Ref targets in the viewer

## Problem and outcome

In a combined SpecGraph diagram, fields on an imported action can refer to
classes from another loaded package. The visualizer exports their exact target
identity, but the viewer treats any nonlocal imported field as unresolved. This
adds a false external node and prevents inspector navigation.

## Scope

- Bind a typed field to its loaded class only when the graph alias, canonical
  type, ontology URI and source digest all match the loaded declaration.
- Preserve original field source and port semantics. Support a local reference
  rebased to the owning package's composition alias.
- Keep legacy unverified cross-package references and mismatched or incomplete
  identities visibly unresolved; do not infer equivalence from bare names.
- Retain behavior for local fields, filters, layout and unloaded references.

## Acceptance

1. An imported action's field connects to the exact loaded class and inspector
   navigation reaches that declaration in both views.
2. Same-named classes, wrong package/version/digest/type, absent classes and
   partial metadata do not attach to an unrelated declaration.
3. A rebased local reference stays connected, while an old unverified imported
   field remains external. Tests include the real SpecGraph composition.
4. The Viewer remains read-only; matching graph metadata does not authenticate
   a source or establish instance existence or semantic approval.

---
**Archived:** 2026-11-09
**Verdict:** PASS (local; hosted CI and review separate)
