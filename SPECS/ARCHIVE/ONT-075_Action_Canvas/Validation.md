# ONT-075 verification

- The baseline membership graph showed four local classes and one wire after
  hiding unresolved imports. The new graph shows five local declarations and
  four semantic wires, with a dedicated socket for each action participant
  and typed field.
- The frontend build and 21 unit tests passed. All 23 repository Chromium
  scenarios passed. Five independent Chromium checks covered the membership
  canvas, action reuse and aliases, imported event-core types in the catalog,
  wire endpoints and a same-size reference-field edit in a live YAML workspace.
- Both projection modes preserve loaded reference-field targets. The screenshot
  and its README caption describe types. Viewing a supplied instance and its
  recorded participant values is the next separate slice.

The membership inputs now start in subject, action, object order. A Chromium
regression sampled the painted strokes of all four visible wires: two pairs
intersected on the earlier layout and zero on the updated layout. The screenshot
was recaptured after reopening the Viewer without dragging any card. The
build, 21 unit tests and all 24 repository Chromium scenarios passed.

Review reproduced a field whose source pointed to a different package or
field. On fresh `full` and `relations` exports of the membership example, the
Viewer now rejects independent edits to the package ID, version, either
digest or pointer. With the source omitted it shows the owning class location.
A Chromium test opens the genuine export, selects the relationship, attempts
to open a graph with the altered field pointer and verifies that the original
file and selection remain visible. The build, 33 unit tests and 25 Chromium
scenarios passed.

The examcalc regression now selects `requires_policy` and `records` in the
exported graph. The inspector shows Subject and Object for both, shows the
`oneOf` alternatives for `records`, and omits Action. Chromium clicked both
`allows` and `denies` directly on their separate paths in Rect and Curve
modes and verified the selection, node position and viewport across switches.
The production build, 35 unit tests and 26 Chromium scenarios passed.
