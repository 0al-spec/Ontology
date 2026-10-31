# ONT-056 — Package Visualization CLI

The operator needs to inspect a package as a diagram and share the same view as
SVG and a raster image. Ondine and Pumlpad illustrate local text-to-diagram
rendering and vector/raster export.

## Deliverables

1. A separate SwiftPM executable `ontologyviz`, backed by `OntologyCompiler`.
2. A deterministic DOT projection of the compiler's validated, normalized package.
3. Local Graphviz rendering to SVG and PNG, with DOT retained for inspection.
4. Usage documentation and a small checked-in example diagram.
5. CLI, projection and real rendering regressions in the macOS/Linux gates.

## Contract

```sh
ontologyviz package.yaml --out diagrams
ontologyviz --format svg --direction TB package.yaml --out diagrams
ontologyviz package.yaml --out diagrams --format dot
```

Default output contains `ontology.dot`, `ontology.svg` and `ontology.png`.
`--format` accepts `both`, `svg`, `png` or `dot`. DOT requires no renderer.
`--dot` selects an executable explicitly, otherwise resolve `dot` from PATH.
Options can precede or follow the input. `--help` describes dependencies and exits
successfully. Bad arguments exit 2, validation/rendering/I/O errors exit 1.

The graph shows classes, protocols, policy targets, inheritance, implementation,
relation names/cardinalities and lifecycle states/transitions. Imported concept
references are explicitly marked external with their import package/version;
their declarations are not loaded or certified. Local identity includes concept
kind so overlapping class/protocol names cannot silently merge.

Graphviz is a separately installed local dependency. Every renderer invocation
uses an argument array and a generated DOT file. Package content is quoted as
text and cannot introduce DOT attributes, images or executable instructions.
Each run stages all requested artifacts before publishing them. Renderer failure
must preserve previously generated output. No hosted render service is involved.

## Verification

- Determinism, kinds, external refs, oneOf relation branches, cardinality, policy
  and lifecycle semantics, Unicode/quotes/backslashes and invalid package refusal.
- CLI option order, help, duplicate/unknown/missing options and renderer failure.
- Real dot produces parseable SVG and a nonempty PNG with valid signature/dimensions.
- Full Swift quality gate and existing generated-output baseline checks.

## Scope and follow-up

This is a package schema diagram. It follows the compiler's existing validation
contract, including its current imported-symbol resolution limitations. Instance
graphs, remote import fetching, GUI editing and renderer bundling are separate
slices. ONT-055 release packaging remains independently reviewable.
