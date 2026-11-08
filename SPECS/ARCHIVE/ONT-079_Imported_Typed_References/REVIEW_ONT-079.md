# REVIEW REPORT — ONT-079 imported typed references

**Scope:** ONT-079 changes above Ontology `main`.

## Verdict

- [x] Approve locally, subject to hosted CI and independent review.

## Findings and follow-up

- **Medium:** `advise-staged` reads only a changed package from the Git index
  and has no way to supply staged import sources. It therefore reports a valid
  imported `Ref` as unresolved. Strict `check --import` works; the advisory is
  non-blocking. Add index-bound import support without reading unstaged working
  files or guessing between package identities.
- **Medium:** `diff`, registry `publish` and other commands without import inputs
  cannot operate on packages using an imported `Ref`. They fail closed. Add
  explicit source-bound inputs and define compatibility behavior separately.

## Correctness and architecture

The imported target must match a declared package ID, version, alias and class.
The rule rejects ambiguous runtime type discriminators. Normalized IR retains
both the local alias and canonical target identity; diagrams rebind only display
references. No network fetching or inference from an unqualified name occurs.
A resolved type does not establish an instance or a semantic equivalence.

## Tests

[Local validation](ONT-079_Validation_Report.md) covers Swift quality, 256
Swift tests, SDK consumers, a transitive diagram, and an isolated real
SpecGraph composition. Coverage was not measured locally. CI, independent
review and release remain separate.
