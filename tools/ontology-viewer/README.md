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

Current node positions are local display state. There is no YAML writer or live
agent connection in this viewer; those belong to the next editing layer.

## Checks

```sh
npm test
npm run build
npx playwright install chromium
ONTOLOGY_GRAPH_FIXTURE=/tmp/motivation-graph/ontology.graph.json npm run test:e2e
```

Browser tests use a real graph produced by `ontologyviz`. They verify desktop and
mobile navigation, inspection, dragging and invalid-input recovery. To use an
existing local Chromium binary, set `PLAYWRIGHT_CHROMIUM_EXECUTABLE`.
