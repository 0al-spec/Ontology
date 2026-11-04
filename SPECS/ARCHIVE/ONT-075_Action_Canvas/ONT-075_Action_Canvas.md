# ONT-075 — Read the structure of a named action on the canvas

The public membership package declares a relationship with a subject, action
and object. The action has a reference field. A reader of the README screenshot
currently sees an isolated class for the action and one User-to-Project line.

Show the named relationship and its participation links, distinguish the action
visually, and connect its declared repository field to its target. Use the
exported types, IDs and source pointers. Keep ordinary binary relations usable.
Verify selection, filtering, oneOf and reuse of one action across relationships.
Capture the actual Viewer for the README and inspect it at README width.

Use the visual grammar of a shader editor. Render the named slots as visible
ports on their cards and attach each wire to its own port. A side panel lists
the types and relationships in the loaded projection before any search is
entered. Selecting a declaration locates its existing card or binary relation
and shows its inspector. Mark unresolved references separately from definitions.

The first view renders type declarations. A shared action is one type even
when multiple relationship types use it. A separate follow-up will show a
supplied instance record against this schema, with concrete participants
and reference values supplied by that record.

In the membership example, place the action above the project. Arrange the
three input cards in the same vertical order as their ports and verify that
their four visible wires neither cross nor overlap.

When the inspector shows the source of a field, its package, version and both
digests must match the owning class. The pointer must address that exact field.
Opening a graph with inconsistent source metadata keeps the previous graph
visible. A field without source metadata can still link to its owning class.

Use Subject and Object in the inspector for every relationship. Show Action
when the declaration supplies one. The canvas offers rectangular (default)
and curved lines. In both modes, readers can distinguish and select parallel
relationships such as `examcalc:allows` and `examcalc:denies` by their labels.
Switching modes preserves node positions, the viewport and the selection.
