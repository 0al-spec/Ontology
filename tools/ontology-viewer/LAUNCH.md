# Start Ontology Viewer

This guide builds matching compiler tools and opens the included motivation/events
example. No SpecSpace, agent, global CLI installation or NormLab checkout is needed.
Run the commands in one terminal unless a new terminal is explicitly mentioned.

## Requirements

- Git, a shell, and a current browser.
- Node.js **24 recommended** (the package minimum is 20.19) with npm.
- Swift **6.0 or newer** on macOS 13+ or a supported Linux Swift environment.
  Linux source-built executables use the installed Swift runtime.
- Internet access for Git and the first dependency installation.

Check the selected tools:

```sh
git --version
node --version
npm --version
swift --version
```

Graphviz is needed only for optional SVG/PNG rendering, not for JSON export or
the interactive viewer. Playwright, SwiftLint and SwiftFormat are development
check tools; they are not required to start the viewer.

## 1. Obtain a compatible source checkout

The reproducible source example below pins
`7da2e7ceb7ba862d57dd662eb34af89e516849e4`, which contains JSON projection,
full direct-import loading and package filters. A source SHA is used because
older release executables need not have those features. Build both tools from
this checkout instead of mixing them with arbitrary binaries on PATH.

```sh
mkdir -p "$HOME/Development"
git clone https://github.com/0al-spec/Ontology.git "$HOME/Development/Ontology-viewer-demo"
cd "$HOME/Development/Ontology-viewer-demo"
git fetch origin 7da2e7ceb7ba862d57dd662eb34af89e516849e4
git switch --detach 7da2e7ceb7ba862d57dd662eb34af89e516849e4
```

If you already have a compatible checkout, use its directory instead. Keep
uncommitted work safe; a separate clone avoids switching an active task branch.

## 2. Configure paths and build the tools

Run this block from the checkout root. The overrideable build/data paths keep
generated output separate from editable examples. Honor any workspace-specific
external-disk/cache policy before installing; npm's `node_modules` stays in the
checkout even when its download cache is elsewhere.

```sh
export VIEWER_REPO="$PWD"
export VIEWER_BUILD="${VIEWER_BUILD:-$HOME/.cache/ontology-viewer-demo}"
export VIEWER_DATA="${VIEWER_DATA:-$HOME/.local/share/ontology-viewer-demo}"
export VIEWER_DIST="$VIEWER_BUILD/web"
mkdir -p "$VIEWER_BUILD" "$VIEWER_DATA"

swift build --package-path "$VIEWER_REPO" --product ontologyc \
  --scratch-path "$VIEWER_BUILD/swift" --cache-path "$VIEWER_BUILD/cache/swiftpm"
swift build --package-path "$VIEWER_REPO" --product ontologyviz \
  --scratch-path "$VIEWER_BUILD/swift" --cache-path "$VIEWER_BUILD/cache/swiftpm"
VIEWER_BIN=$(swift build --package-path "$VIEWER_REPO" --show-bin-path \
  --scratch-path "$VIEWER_BUILD/swift" --cache-path "$VIEWER_BUILD/cache/swiftpm")
export VIEWER_BIN

npm --prefix "$VIEWER_REPO/tools/ontology-viewer" ci --cache "$VIEWER_BUILD/cache/npm"
```

`VIEWER_BIN` is obtained from SwiftPM rather than assuming a build-directory
layout. These commands do not require `ontologyc` or `ontologyviz` on PATH.

## 3A. Read-only browsing

Export the full example, then start the frontend development server:

```sh
"$VIEWER_BIN/ontologyviz" \
  --profile "$VIEWER_REPO/Examples/package-visualization/motivation-full.profile.json" \
  --format json --out "$VIEWER_DATA/full-graph"
cd "$VIEWER_REPO/tools/ontology-viewer"
npm run dev
```

Open the loopback URL printed by Vite and click **Open graph**. Select
`$VIEWER_DATA/full-graph/ontology.graph.json` using its actual expanded path.
The header says **READ ONLY**. Search and select
`eventcore:SnapshotOriginAdmission`: the inspector should show its policy source.
**Filters → Packages** selects packages; node/relationship counts explain empty
categories. Drag nodes and try Hide/Dim: filtering preserves their positions.

This mode never writes YAML and does not automatically regenerate a loaded JSON
file after source edits. Export and reopen the JSON to see those changes.
Stop the development server with **Ctrl+C** before choosing the workspace mode.

## 3B. Shared YAML workspace on copies

Prepare this example once. Existing copied YAML and profile files are retained
when the block is repeated, so edits are not replaced by the original example.

```sh
mkdir -p "$VIEWER_DATA/sources"
if [ ! -e "$VIEWER_DATA/sources/motivation.yaml" ]; then
  cp "$VIEWER_REPO/SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml" \
    "$VIEWER_DATA/sources/motivation.yaml"
fi
if [ ! -e "$VIEWER_DATA/sources/events.yaml" ]; then
  cp "$VIEWER_REPO/SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml" \
    "$VIEWER_DATA/sources/events.yaml"
fi
if [ ! -e "$VIEWER_DATA/full.profile.json" ]; then
  cat > "$VIEWER_DATA/full.profile.json" <<'JSON'
{
  "schemaVersion": 1,
  "package": "sources/motivation.yaml",
  "view": "full",
  "imports": ["sources/events.yaml"]
}
JSON
fi

cd "$VIEWER_REPO/tools/ontology-viewer"
ONTOLOGY_VIEWER_DIST="$VIEWER_DIST" npm run build
npm run workspace -- --profile "$VIEWER_DATA/full.profile.json" \
  --ontologyc "$VIEWER_BIN/ontologyc" --ontologyviz "$VIEWER_BIN/ontologyviz" \
  --dist "$VIEWER_DIST"
```

Open the exact `http://127.0.0.1:PORT/` URL printed by the workspace.
The graph loads automatically; the header says **LOCAL WORKSPACE**.
The YAML editor edits **the copied root motivation.yaml**. Save writes that file;
it is not merely a visual preview. The imported events package is read-only in
this workspace. Compiler diagnostics and the graph refresh after source changes.
An invalid source keeps the last graph visibly stale.

An external editor or agent may edit the same copied files. A clean browser
buffer refreshes; unsaved browser edits are preserved on conflict. Reconcile or
copy the draft before using Reload. Changing the profile or retargeting an input
symlink requires restoring it or restarting the service.

## Full versus relations

- `"view": "full"` with explicit `imports` loads every declaration family of
  those direct packages. Omit `expand`. Dependencies are not fetched recursively.
- `"view": "relations"` shows classes/ontology relations. Supplied imports require
  explicit `expand` class selectors, as in the included relations profile.
  Filters cannot restore families omitted by this projection.
- A count of `0` may mean that a package actually declares no protocols or other
  category. Unloaded dependencies remain marked references.
- Counts are canvas nodes and visual links, including state nodes, placeholders
  and individual `oneOf` branches, not only declaration counts.

Profile paths are relative to the profile file. CLI paths such as `--profile`
and `--dist` should be absolute when launching from another directory.

## Stop and run again

Keep the terminal running while using the page. **Ctrl+C** stops the service;
it does not delete copied sources. A free port is chosen each time: use the newly
printed URL and reload after a server restart. Add `--port 4180` to the workspace
command if a fixed free port is useful.

In a new terminal, change to your checkout root, restore the path variables from
step 2 (including any custom build/data overrides), and recompute/export
`VIEWER_BIN` with the `--show-bin-path` command. Then run just the last workspace
command. Rebuild the frontend after pulling frontend changes; rebuild both CLI
products after compiler changes. Dependency-lockfile changes require `npm ci`.
No rebuild is needed for ordinary edits to the copied YAML.

The recipe does not pin the copied files to Git automatically. Keep valuable
model changes in your project's normal version control/backup workflow.
To use your own model, pass an absolute package or profile path; Save then edits
that actual root file. For another disposable example, choose a different
`VIEWER_DATA` directory.

## Troubleshooting

| Symptom | What to check |
|---|---|
| Unknown `json` format or full import rejected | Use the pinned checkout and both source-built tools via explicit paths. In full view remove `expand`. |
| Missing `dist/index.html` | Build with `ONTOLOGY_VIEWER_DIST="$VIEWER_DIST"`, then pass `--dist "$VIEWER_DIST"`. |
| Only classes and ontology relations appear | Check `view` and loaded inputs. Use the full profile; unused families can still legitimately have zero counts. |
| Browser page is unreachable | Keep the terminal alive and open its newly printed loopback URL. A fixed port may already be occupied. |
| Host/origin/session rejected | Use the exact `127.0.0.1` URL and reload after restart; avoid substituting `localhost` or a proxy hostname. |
| npm reports dependency advisories | Inspect `npm audit`; keep dependency upgrades in a separate validated change instead of applying `npm audit fix --force` as a setup step. |
| Input/profile changed | Restore the input or restart to select the new profile/target. Copy an unsaved draft before navigating away. |
| Save disabled or conflict shown | Reconcile the preserved draft with disk; Reload may discard it after confirmation. Ambiguous line-ending edits must be undone or copied before reloading. |

For implementation details and optional development checks, return to the
[viewer README](README.md). For the compiler's full platform setup, see the
[tooling guide](../../SPECS/ontology/tooling-guide.md).
