# Ontology diagram projection v1

`OntologyCompiler.diagramProjection` and `ontologyviz --format json` expose the
same validated declaration selection used by the DOT renderer. The compiler API
also offers `diagramJSON` for deterministic, sorted-key JSON. The CLI writes
`ontology.graph.json`; it does not require Graphviz. See the
[worked profile](../../Examples/package-visualization/README.md#machine-readable-graph).

The top-level `schemaVersion` is `ontology.diagram-projection/v1`. `id`,
`version`, `namespace`, `sourceDigest` and `sourceByteDigest` identify the root. `view` is `full`
or `relations`. `imports` are the root's declared direct dependencies. `sources`
lists the loaded root followed by explicitly supplied reachable imports, in alias
order. Each source contains its own `id`, `version`, canonical `namespace`, diagram
`alias`, `sourceDigest` and `sourceByteDigest`. Both digests use a `sha256:`
prefix. `sourceDigest` matches the existing compiler IR's digest of loaded UTF-8
text. `sourceByteDigest` hashes the exact input bytes and should be used for
detecting changes before editing; these values differ for a UTF-8 BOM because
the compiler loader removes it from text across supported Swift versions.
Paths are not embedded: a caller associates those identities and digests with
the local input paths it supplied. An identity/version match does not authenticate
the provenance of supplied content.

The graph contains `classes`, `relations`, `protocols`, `policies` and
`stateMachines` arrays. Their records use the compiler's normalized declaration
fields. Relation `domain` is a qualified class reference; `range` is either a
qualified reference or `{ "oneOf": [...] }`. A `oneOf` is one relation with
alternative targets. References can identify unloaded imported declarations;
their presence does not fabricate a node or prove the external symbol exists.

Each visible declaration carries `source` with its owning package `id`,
`version`, both source digests and a logical JSON `pointer` into the original YAML
document. Class fields carry their own pointers. Pointer components follow JSON
Pointer escaping (`~0`, `~1`). This is a logical location, not a source byte,
line/column span, editable syntax tree or guarantee of round-trip preservation.
The Viewer accepts a field source when its package ID, version and both digests
match the class and its pointer is `<class pointer>/fields/<escaped field id>`.
If the source is omitted, the inspector shows the class location.
Normalized fields may omit source metadata and comments; do not regenerate YAML
from the projection. Recheck `sourceByteDigest` before applying edits to a source file.

`full` shows every declaration family of the root and explicitly supplied exact
reachable imports. It loads entire supplied packages without `expand`. Each
reference is resolved using the imports of the package that declares it, by exact
package ID and version; it is then rebased to a unique diagram alias. Root and
direct-import aliases retain their existing meaning. A transitive package gets
a deterministic collision-safe synthetic alias, `pkg-<id-tail>-<digest>`,
derived from its ID and version. Synthetic aliases are projection identifiers,
not declarations added to the root package. Declaration sources and pointers
remain those of the original package.

The additive `externalImports` array, when present, lists reachable transitive
dependencies that were declared by a loaded package but not supplied as files.
Each entry has `id`, `version` and diagram `alias`; it has no source digest and
does not claim any symbol exists. References into it render as external
placeholders. A missing direct import remains represented by root `imports` as
before. Alias collisions and multiple versions retain distinct bindings; duplicate
supplied identities and unreachable supplied files are rejected. Cycles are
bounded by package identity. No dependency file is discovered or fetched.

Imported `Ref` field targets are stricter than ordinary external relation
references: their exact source package must be supplied and contain the target
class. The field's display target is rebased to the diagram alias, while its
canonical type, URI and source digest retain the imported package's identity.

`relations` follows the
existing visualizer selection: root relations and incident root classes plus
explicitly selected classes from exact reachable local imports; imported relations
are included only when their entire domain and range are selected/visible.
Protocols, policies and state machines are empty in that view. Class metadata is
retained for inspection even where the diagram hides it. Selection aliases use
the diagram aliases in `sources`; source records retain the owning package identity.

The JSON projection has no layout, pixel positions or diagnostics. A consumer
can run `ontologyc check --format json` separately; a successful graph does not
assert that warnings are absent or that manual policies are satisfied. This is a
schema view, not an instance graph, factual proof or publication approval.
Readers should ignore additive fields they do not use and reject unsupported
`schemaVersion` values.
