# ONT-061 — Distribute ontologyviz with ontologyc

A user who downloads an Ontology archive should be able to check a package and render its saved diagram profile. The current release ships only the compiler, although both tools work from the source checkout.

## Acceptance

1. Keep the archive names, directory layout for existing files, SHA-256 manifest, tagged source identity and retry behavior. Include the two executables for macOS arm64 and Linux x86_64 when the selected source provides them.
2. Build and verify the tools selected by the pinned source revision. Reject a missing or unusable required executable before publishing. Support compiler-only historical tags and their existing assets.
3. From an extracted archive, run the compiler and render the saved motivation profile using external Graphviz. Check deterministic DOT and actual SVG/PNG output. Exercise the Linux archive in the Ubuntu 22.04 runtime without a Swift installation.
4. Explain how to use the downloaded tools and install the external renderer. A preview is verified with the same archive layout used for releases.
