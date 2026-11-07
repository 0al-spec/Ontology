# ONT-077 validation

**Verdict:** PASS locally; hosted CI and independent review are separate.
**Date:** 2026-11-07

## Executed checks

- `bash tools/swift-quality.sh`: SwiftFormat and SwiftLint pass; explicit target
  dependency-import build passes; 58 OntologyRules and 193 OntologyCompiler
  XCTest cases pass on macOS / Swift 6.4. Graphviz was present. SwiftPM scratch
  and dependency caches were routed to TB5. Coverage was not measured.
- `npm test` in `tools/ontology-viewer`: 40 tests pass.
- `npm run build -- --outDir <TB5 viewer output>`: TypeScript and Vite pass.
- `npm run test:e2e -- tests/transitive-import.spec.ts` with local Chrome:
  the browser displays the external package identity and explicitly says its
  declaration has not been loaded. One test passes.
- Focused Swift tests cover chain, missing file, direct and local namespace
  reuse, two versions, duplicate/conflicting inputs, a hash-prefix collision,
  unreachable packages, cycles and diamonds, deterministic import ordering,
  DOT/JSON, selected relations, profiles and input-overwrite protection.
  In separate red/green checks the selected-class inheritance and a foundation
  default-namespace DOT label both failed before their respective fixes.
- The configured FLOW checks `test -f README.md` and
  `test -f SPECS/Workplan.md` pass; `git diff --check` passes.

## Real SpecGraph composition

Test inputs are from SpecGraph commit
`27d250284ec69ef1615266fdf272b8c281279670`:

| Input | Path at that commit | SHA-256 used |
| --- | --- | --- |
| A | `specs/models/SG-SPEC-0051/proposal-promotion/domain-ontology-package.yaml` | `0b0854eabb4e55d20e3a83e8eb18dcbc2fca578733c2198065fc7e0a9ff8c936` |
| B | `specs/models/SG-SPEC-0053/intent-to-proposal/domain-ontology-package.yaml` | `95f10af181380b9f1b3cd21b219f2a63bde090626cfd345b3e913c810dd9589d` |
| C | `ontology/packages/specgraph-core/domain-ontology-package.yaml` | `5bfa2ff40b6174def589546ab2fea2501e1f256c4f1446f36c45c7f3fffcd929` |

A is an isolated test copy: its direct `specgraph.foundation` and `specgraph-core`
imports were removed to reproduce A → B → C. B and C match the commit byte for
byte. No SpecGraph source file or canonical ontology was modified.

With the older 0.8.0 visualizer, supplying B failed to bind its `sgcore:Intent`;
supplying B and C failed because C was not directly imported by A. With this
change, both runs succeed. With C supplied, `Intent` comes from
`org.0al.specgraph.core@0.1.0` with its real source digest and pointer. Without C,
the graph carries an external binding with the same package identity/version and
no source digest. A still declares only its actual direct dependencies.

The standalone Viewer was exercised in Chrome with both generated files: the
missing case identifies an unloaded external reference, while the loaded case
shows `/spec/classes/Intent` from core. Re-export after the final build matched
the browser inputs byte for byte. Local screenshots are observation artifacts,
not evidence of a deployed site.

## Consumer and scope limits

SpecSpace `main` at `e84e79d721090eb3dc94e68d2ee24718ebdbf026` parses both
generated graphs with its current v1 parser, but that parser drops the additive
`externalImports` field. Therefore SpecSpace needs a downstream update to show
the missing transitive package identity; this task changes the standalone
Ontology Viewer only. The parser check used a local Node harness, not the hosted
SpecSpace deployment. No release, pin update, network dependency fetching,
deployment or external-symbol truth verification was performed.
