# ONT-071 Foundation identity

Ship ontology.foundation@0.1.0 with default namespace ont. Make new exports,
examples and authored package generators use it. Existing specgraph.foundation
imports must continue to validate offline against the same role-specific
catalog with version checks. Preserve historical packages, generated fixtures
and profile pins. Verify valid and invalid imports, generated defaults, catalog
bytes, full CI and the published CLI archives on macOS and Linux.
