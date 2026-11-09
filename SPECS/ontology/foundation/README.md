# Versioned foundation model catalogs

Each supported foundation version contains:

- `exports.json`: the compiler-owned names and their reference roles.
- `model.md`: an exact snapshot of the published foundation model source.
- `model.json`: a deterministic, machine-readable projection of the
  exact exported class and protocol interfaces and supporting types.

`model.json` uses `ontology.foundation-model/v1`. Its `classes`, `protocols`
and `supportingTypes` maps are keyed by symbol name; each interface retains
its exact source declaration, declared parent and ordered properties with their
source type text and optionality. Type text is not evaluated. JSON pointers such as
`/classes/DomainEntity/declaration` address the catalog itself. The `source`
object identifies the original Git revision, local snapshot and SHA-256 of its
bytes. It does not authenticate a signer or imply semantic approval.

The 0.1.0 legacy import identity `specgraph.foundation` uses the same 0.1.0
catalog as `ontology.foundation`. Consumers must retain the identity and
namespace actually declared by each import; this compatibility rule is not a
general rule that differently named ontologies are equivalent.

These files describe the compiler's terminal foundation vocabulary; they are
not `DomainOntologyPackage` documents and have no synthetic `/spec/classes`
locations. A viewer must explicitly consume this catalog format before it may
claim to have loaded a definition.

Regenerate or verify the catalogs without network access:

```bash
python3 tools/generate_foundation_models.py
python3 tools/generate_foundation_models.py --check
```

The generator verifies the pinned source hashes, requires the exact exported
names and rejects ambiguous or missing interfaces. Swift tests also compare
the catalog against the retained source and export table.
