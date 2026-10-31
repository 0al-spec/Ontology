# Ontology Viewer

Explore an `ontology.diagram-projection/v1` JSON file locally. The canvas can be
embedded by a future host; this application does not require SpecSpace, an agent
or an API server. Opening a JSON graph never writes to its YAML sources.

## Run

Build or install an `ontologyviz` version containing ONT-062, then generate a
projection from the saved motivation-core/events-core selection:

```sh
ontologyviz --profile Examples/package-visualization/motivation-relations.profile.json \
  --format json --out /tmp/motivation-graph

cd tools/ontology-viewer
npm ci
npm run dev
```

Open the printed loopback URL and choose `/tmp/motivation-graph/ontology.graph.json`.
After dependencies are installed the viewer works without an internet connection.
The visualizer and browser app can also be used separately with an exchanged JSON
file. `npm run build` creates a static `dist/` site for a local web server.

Search finds nodes and relations; select a result to focus the canvas and inspect
its declaration. Drag nodes, zoom and pan to explore. Visual links from one
`oneOf` relation lead to the same underlying relation record. Imported classes
are tinted blue; unresolved external references are gray and never presented as
loaded declarations. The inspector shows the owning package, logical YAML pointer
and byte digest where a declaration is available.

## Reuse and boundaries

`src/index.ts` exposes `parseProjection`, `buildGraph`, `GraphCanvas`, `Inspector`
and related TypeScript types to a host in this source tree; import `src/style.css`
for this application's styling. This is source-level reuse, not a published npm
package or a SpecSpace integration. The projection contains type declarations,
not runtime instances, proof of factual truth or approval of manual policies.

Current node positions are local display state. The viewer's file-open mode is
read-only; the optional local workspace below edits source text.

## Local YAML workspace

Use an `ontologyc` and `ontologyviz` build containing ONT-062. After `npm ci`
and `npm run build`, start a workspace for an explicit source file:

```sh
npm run workspace -- --package /path/to/domain-ontology-package.yaml \
  --ontologyc /path/to/ontologyc --ontologyviz /path/to/ontologyviz
```

Open the printed `127.0.0.1` URL. To use a saved selection and its local imports,
replace `--package ...` with `--profile /path/to/view.profile.json`. Only the
root YAML selected by the package or profile is editable; imported packages can
be viewed and are monitored for changes. To edit an import, open its own
workspace. The binaries default to `ontologyc` and `ontologyviz` on `PATH`.
`--dist` selects an alternate already-built frontend directory; `--port` selects
a loopback port (default: a free port).

The editor works on the original text instead of serializing YAML. Unchanged
regions, comments and the UTF-8 BOM remain as written. Existing line terminators
are retained in order during a text replacement; new lines use a neighboring
line-ending style. A save compares the last loaded byte digest against disk and
rejects stale writes. If an agent changes a clean buffer it refreshes; if the
human has unsaved changes, those remain visible and saving is disabled until the
conflict is reconciled. Reload asks before discarding an unsaved draft.

The workspace runs `ontologyc check --format json` and refreshes the graph with
`ontologyviz`. Invalid draft text may be saved and corrected: diagnostics appear
in the editor and the last valid graph is marked stale. A no-op save does not
rewrite the file. Save uses a temporary file and atomic rename while retaining
permission bits; extended attributes, ACLs and hard-link identity are not
preserved. A direct external writer that ignores this service can still race in
the small interval between the last digest check and rename; this is not an
atomic filesystem compare-and-swap.

The canvas retains its viewport, node positions and selection across refreshes.
If the selected transition itself changes, the selection is cleared rather than
silently identifying another transition in the same state machine.

The service binds to `127.0.0.1`, checks the request host/origin and uses a
per-session token for its API. It exposes no shell or arbitrary file picker. It
is a local development tool, not a network service or an approval mechanism.

## Checks

```sh
npm test
npm run build
npx playwright install chromium
ONTOLOGY_GRAPH_FIXTURE=/tmp/motivation-graph/ontology.graph.json \
  ONTOLOGY_COMPILER=/path/to/ontologyc ONTOLOGY_VIZ=/path/to/ontologyviz \
  ONTOLOGY_VIEWER_DIST="$PWD/dist" npm run test:e2e
```

Browser tests use a real graph produced by `ontologyviz`. They verify desktop and
mobile navigation, inspection, dragging and invalid-input recovery. Workspace
tests additionally require `ONTOLOGY_COMPILER`, `ONTOLOGY_VIZ` and
`ONTOLOGY_VIEWER_DIST` pointing to the built tools and frontend. They use
disposable YAML copies and verify comments, BOM/line endings, validation,
external changes and conflicts. To use an existing local Chromium binary, set
`PLAYWRIGHT_CHROMIUM_EXECUTABLE`.
