# ONT-078 — Viewer Namespace Badges

## Intent

Display a node's namespace in a quiet badge at the upper right of its card,
leaving the declaration name easier to read beneath the node kind.

## Contract

- Split a qualified label at its namespace separator for presentation only.
  Keep the complete identifier available as the title and unchanged in graph
  identity, search, filters, inspector, relationship ports and source records.
- Unqualified labels keep their original text and have no fabricated namespace.
- Long namespaces must remain within the card, with the full value accessible;
  badges must not overlap the type label, node name or connection ports.
- Apply consistently to class, action, relation and external-reference nodes.
  Existing compact node sizing and layout must continue to work.
- SpecSpace imports the component from a pinned Ontology revision and verifies
  the same behavior in its UI catalog and embedded viewer.

## Validation

- Browser regression on qualified, unqualified and long labels, searching and
  selecting by full ID; inspect desktop and mobile layout and port geometry.
- Viewer tests and build; repository quality checks per AGENTS.md.
- Cross-repository source hash check and SpecSpace focused UI checks.
