# Visualize an ontology package

`ontologyviz` draws a package locally and writes SVG, PNG and the DOT source.
The example models a proposal citing evidence, its review protocol and policy,
and an explicit approval transition.

![Proposal review package](ontology.svg)

## Run

Build with Swift 6.0 or later. Install Graphviz for SVG and PNG output.

```sh
# macOS
brew install graphviz
# Debian / Ubuntu
sudo apt-get install graphviz

swift run ontologyviz \
  Examples/package-visualization/domain-ontology-package.yaml --out diagrams
```

The default produces `diagrams/ontology.dot`, `diagrams/ontology.svg` and
`diagrams/ontology.png`. Output paths are printed to stdout and errors to stderr.
Select a single image format or export DOT on its own with `--format svg`,
`--format png` or `--format dot`. Every mode retains the DOT source.

```sh
swift run ontologyviz --direction TB --format svg \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --out diagrams/examcalc
swift run ontologyviz package.yaml --out diagrams --dot /opt/homebrew/bin/dot
swift run ontologyviz --help
```

`--direction LR` is the default. Options may precede or follow the input.
`--out` selects a directory. Existing artifacts with the selected names are
replaced after all requested renderer operations succeed. Rendering errors
preserve the previous artifacts. Files from formats omitted in a subsequent run
remain in that directory, so use a fresh output directory when publishing a
complete set. Output publication uses atomic writes per file, not a directory
transaction.

## Read the diagram

| Appearance | Meaning |
|---|---|
| Blue box | Class, including scalar fields and optional `?` markers |
| Thick blue border | Class marked `central` |
| Purple box and dashed `implements` arrow | Protocol and conformance |
| Amber box and dashed `appliesTo` arrow | Policy and its declared targets |
| Hollow `extends` arrow | Inheritance |
| Named solid arrow | Relation with `[min..max]` cardinality when declared |
| Several arrows labeled `oneOf` | Alternative relation ranges |
| Teal group | Lifecycle states and transitions labeled with command/event refs |
| Dashed gray box | External concept reference with the declared import version |

An omitted cardinality bound is shown as `?` when the other bound is present.

External placeholders carry no claim of successful symbol resolution in the
imported package. Package loading and validation reuse the compiler's current
checks. The diagram is a schema view, including declared behavior structure;
policy text and actual runtime observations require their own review.

DOT output is deterministic for a fixed package and direction. Layout, fonts and
raster pixels depend on the installed Graphviz version and font environment.
SVG and PNG are rendered independently from the same DOT graph. PNG is Graphviz's
raster rendering of that graph.

The tool passes generated DOT through an argument-array invocation of local
Graphviz. Package strings are quoted as text. It performs no remote rendering.
Graphviz is an external dependency under its own license and is not bundled into
the Swift executable. See [Graphviz](https://graphviz.org/license/).

The examples that informed this interface are [Ondine](https://github.com/wevm/ondine)
and [Pumlpad](https://github.com/krus210/pumlpad). They remain independent projects.

## Exit codes and testing

- `0` means the requested files were generated successfully.
- `1` means package validation, local rendering or file I/O failed.
- `2` means invalid arguments.

The normal Swift test suite runs real SVG and PNG rendering tests. Install
Graphviz before `swift test` or `bash tools/swift-quality.sh`. The macOS and Linux
CI jobs install it explicitly. With an external SwiftPM scratch directory, build
the executables and set `ONTOLOGYC_TEST_BINARY_PATH` to that directory's
`debug/ontologyc`; the CLI tests find `ontologyviz` beside it.
