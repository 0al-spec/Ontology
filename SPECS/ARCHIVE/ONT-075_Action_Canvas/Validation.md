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
