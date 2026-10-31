# Ontology Viewer

Explore an `ontology.diagram-projection/v1` JSON file locally. The canvas can be
embedded by a future host; this application does not require SpecSpace, an agent
or an API server. Opening a JSON graph never writes to its YAML sources.

## Start here

Follow the [first-run and restart manual](LAUNCH.md). It gives the
requirements, a pinned source checkout, complete build commands and two modes:

- **Read-only:** export JSON and open it in the frontend.
- **YAML workspace:** open a full profile on copied sources, with compiler
  diagnostics and source-preserving saving.

The manual builds matching `ontologyc`/`ontologyviz` binaries explicitly, so
neither must already be on PATH. It also explains full/relations profiles,
ports, shutdown and troubleshooting. This directory contains the frontend;
it is not a globally installed `npm` command.

Search finds nodes and relations; select a result to focus the canvas and inspect
its declaration. Drag nodes, zoom and pan to explore. Visual links from one
`oneOf` relation lead to the same underlying relation record. Imported classes
are tinted blue; unresolved external references are gray and never presented as
loaded declarations. The inspector shows the owning package, logical YAML pointer
and byte digest where a declaration is available.

Open **Filters** to enable or disable node types, their origin (local, imported,
unresolved), and relationship kinds independently. **Hide** removes inactive
elements from the canvas and keyboard navigation; **Dim** keeps them visible as
context. An edge is inactive when its kind or either endpoint is inactive.
Search covers enabled elements, and the inspector marks a filtered selection.
Filtering preserves manually positioned nodes, zoom and pan; use the existing
canvas controls only when you want to change the view. The **Packages** group selects exact `id@version` identities independently of
namespace aliases. Rows show **nodes / owned visual links** from the complete
canvas. Loaded packages and declared dependencies are listed; unloaded
dependencies are marked explicitly. Unattributed references have their own
bucket when present. State nodes belong to their machine's source package.

A node requires its package, type and origin enabled. A link also requires its
owning package, link kind and both endpoints enabled, so hiding a package can
hide links declared by other packages that point into it. Package filters compose
with Hide/Dim, search and inspector state without changing layout or YAML.
Workspace refresh keeps choices for known identities and enables new ones.
Opening another graph resets package choices; Reset filters enables everything.

Category counts describe the entire canvas, including unloaded placeholders and
state nodes; relationship counts count visual links, including oneOf branches.
Counts remain unchanged while toggling filters. Filter state lasts until
the page is reloaded and does not modify YAML. Only elements in the loaded
projection can be enabled: a `relations` view omits other declarations and the
filter panel explains this. Use a `full` profile with explicit imports to load
policies, protocols, inheritance and lifecycle from those packages too.

## Reuse and boundaries

`src/index.ts` exposes `parseProjection`, `buildGraph`, `GraphCanvas`, `Inspector`,
the filter component/model and related TypeScript types to a host in this source tree; import `src/style.css`
for this application's styling. This is source-level reuse, not a published npm
package or a SpecSpace integration. The projection contains type declarations,
not runtime instances, proof of factual truth or approval of manual policies.

Current node positions are local display state. The viewer's file-open mode is
read-only; the optional local workspace below edits source text.

## Local YAML workspace

For a complete setup on copies, use [the workspace recipe](LAUNCH.md#3b-shared-yaml-workspace-on-copies).
After setup, this is the command shape for an explicit source file (run from
`tools/ontology-viewer`):

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
are retained around a text replacement; new lines use a neighboring line-ending
style. The browser's edit range distinguishes identical-looking lines with
different terminators. If the range or an undo state is ambiguous, the draft
remains visible and saving is disabled: undo the edit or copy the draft before
reloading. A save compares the last loaded byte digest against disk and rejects
stale writes and unpaired Unicode surrogates. If an agent changes a clean buffer
it refreshes; if the human has unsaved changes, those remain visible and saving
is disabled until the conflict is reconciled. Reload asks before discarding an
unsaved draft.

The workspace pins the resolved root, import and profile paths at startup. If a
selected symlink is retargeted or the profile changes, it stops saving and marks
the graph stale; restore the original input or restart the workspace to select
the new one. A snapshot interrupted by a concurrent edit is retried, as is a
transient visualizer failure. The editor keeps the draft during these events.

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

## Development checks (optional)

These are not needed for normal viewing. After the manual's setup, generate the
relations fixture expected by the browser tests and use explicit tool paths:

```sh
"$VIEWER_BIN/ontologyviz" \
  --profile "$VIEWER_REPO/Examples/package-visualization/motivation-relations.profile.json" \
  --format json --out "$VIEWER_BUILD/test-graph"
cd "$VIEWER_REPO/tools/ontology-viewer"
npm test
ONTOLOGY_VIEWER_DIST="$VIEWER_DIST" npm run build
npx playwright install chromium
ONTOLOGY_GRAPH_FIXTURE="$VIEWER_BUILD/test-graph/ontology.graph.json" \
  ONTOLOGY_COMPILER="$VIEWER_BIN/ontologyc" ONTOLOGY_VIZ="$VIEWER_BIN/ontologyviz" \
  ONTOLOGY_VIEWER_DIST="$VIEWER_DIST" npm run test:e2e
```

Browser tests use a real graph produced by `ontologyviz`. They verify desktop and
mobile navigation, inspection, dragging and invalid-input recovery. Workspace
tests additionally require `ONTOLOGY_COMPILER`, `ONTOLOGY_VIZ` and
`ONTOLOGY_VIEWER_DIST` pointing to the built tools and frontend. They use
disposable YAML copies and verify comments, BOM/line endings, validation,
external changes and conflicts. To use an existing local Chromium binary, set
`PLAYWRIGHT_CHROMIUM_EXECUTABLE`.
