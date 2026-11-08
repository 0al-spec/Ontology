# REVIEW REPORT — ONT-082 imported Ref Viewer binding

**Scope:** ONT-082 changes above Ontology 0.9.1.

## Verdict

- [x] Approve locally, subject to hosted CI and independent review.

## Correctness and boundaries

Cross-package binding requires the projected alias, canonical type, package ID,
version, class and normalized source digest to match a loaded declaration. A
partial or conflicting identity remains an unresolved external node. Older
projections without target identities retain the prior conservative scoping;
local references rebased to the owner's alias remain connected.

The field wire and inspector navigation use the same resolved node and preserve
the source of the field declaration. Matching metadata describes the selected
projection; it does not authenticate source truth or prove an instance exists.
No unresolved local correctness findings were identified. SpecSpace needs a
separate reviewed upstream synchronization and browser test; no FLOW follow-up
inside Ontology is required for that consumer work.

## Tests

[Validation](ONT-082_Validation_Report.md) records 51 Viewer unit tests, the
TypeScript/Vite build, a local real SpecGraph graph check, and browser inspector
navigation. CI, independent review and SpecSpace deployment remain separate.
