# SpecGraph Core Ontology

`org.0al.specgraph.core@0.1.0` is the small compiler-backed seed for the
SpecGraph ontology layer. It materializes the curated core vocabulary that
SpecSpace can display and SpecGraph can reference through `ontologyc`
validation artifacts.

The package is intentionally minimal and remains `approvalStatus: draft`.
It is compiler evidence for downstream review surfaces, not an approved
Ontology package and not permission to mutate SpecGraph specs or lockfiles.

## Scope

The seed models the basic declarative substrate:

- `SpecGraph`
- `Intent`
- `Spec`
- `Node`
- `Edge`
- `Requirement`
- `AcceptanceCriterion`
- `Decision`
- `Constraint`
- `Invariant`
- `Evidence`
- `CodeSurface`
- `Test`
- `Release`

The relation set mirrors the current curated SpecSpace graph lens while keeping
each relation typed by domain and range in the compiler package.

## Validate

```bash
swift run ontologyc check SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml

swift run ontologyc compile \
  SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/specgraph-core/generated
```

Downstream SpecGraph work should consume
`generated/ontology.normalized.json` through `ontologyc validate-specgraph` and
should emit `OntologyGap` records for unknown `sgcore:*` refs.
