# ONT-058 — Relations View and Selected Imports

The full motivation-core schema is crowded by policies and inheritance. Its
README also follows relations into events-core that appear only as external
placeholders in the current renderer. The operator approved a domain-relations
view with selected expansion of those imports.

## CLI and library

Add `--view full|relations`, keeping `full` as the default. The relations view
shows root classes incident to displayed root relations, and all explicitly
selected imported classes. It omits class fields, inheritance, protocols,
policy/lifecycle scaffolding. All root relations stay visible.

`--import <package.yaml>` is repeatable and explicitly supplies a local YAML
package. Its id/version must match exactly one direct root import with a unique
non-root namespace. Canonical source namespaces can differ from the root alias.
Duplicate/conflicting supplied identities are errors. Local packages are loaded
and checked through the existing compiler; no remote or implicit file lookup.

`--expand <namespace:Class,...>` is repeatable. Every selector must identify a
class in a supplied package using the root import alias. Imported relations are
included when their domain and every range alternative are selected types or
visible root classes. This is an induced subgraph; partial oneOf alternatives
are omitted as a whole. The diagram states that it is a selected view. Unselected
root relation targets remain explicit external placeholders. Metadata shows the
source package/version for expanded nodes. Cross-package references are remapped
by declared identity, never by namespace spelling alone.

Imports and expansion must be supplied together and require relations view.
Expose an options-based library overload while retaining the existing API and
the default DOT bytes. Rendered output retains source protection for every input
file, including supplied imports.

## Pilot

Render motivation-core with local events-core 0.2.0 and select Interpretation,
InterpretationCandidate, RoleBinding, Entity, CausalHypothesis, RecordedEvent,
StateSnapshot and Delta. Show the record snapshots, record-owned Delta, role
binding and causal-view declarations. The schema has one declaration per type;
distinct occurrences/roles in the README example are not fabricated instance nodes.

## Verification

Regressions cover unchanged default output, hidden scaffolding, actual imported
declarations, aliases, wrong version/id, duplicate and ambiguous bindings,
unknown/missing selectors, partial oneOf omission, source overwrite protection,
determinism and real SVG/PNG CLI rendering. Run the repository quality gate,
generated-output contracts, TypeScript and DocC checks. Save and inspect the
motivation-core render. Follow FLOW checkpoints and open a focused PR atop #81.

---
**Archived** 2026-10-31

**Verdict** PASS for local checks; external review and hosted CI pending.
