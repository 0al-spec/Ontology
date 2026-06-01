# ontologyc

A static compiler that transforms a `DomainOntologyPackage` YAML specification into a
versioned TypeScript SDK — including type definitions, Zod runtime schemas, relation
maps, policy and state-machine descriptors, and a Specification-pattern validation layer.

## What it does

```
domain-ontology-package.yaml  ──►  ontologyc compile  ──►  TypeScript SDK
                                                            ├── types.ts          (interfaces + protocol extends)
                                                            ├── schemas.ts        (Zod v4 runtime schemas)
                                                            ├── validators.ts     (type guards + ABox parser)
                                                            ├── refs.ts           (typed concept reference map)
                                                            ├── relations.ts
                                                            ├── policies.ts
                                                            ├── state-machines.ts
                                                            ├── protocols.ts      (protocol interface definitions)
                                                            ├── registry.ts       (bundle export)
                                                            └── ontology.normalized.json  (IR)
```

## Requirements

- macOS 13+ or Linux (Swift 6.0+)
- Swift toolchain ≥ 6.0

## Build

```bash
swift build --product ontologyc
# binary lands at .build/debug/ontologyc
```

## Usage

```bash
# Validate a package YAML (no output written)
ontologyc check <package.yaml>

# Compile to TypeScript
ontologyc compile <package.yaml> --target typescript --out <directory>

# Validate specgraph semantic bindings against an ontology IR
ontologyc validate-specgraph <binding.yaml> --ontology-ir <ontology.normalized.json> --out <directory>

# Diff two package versions for compatibility breaks
ontologyc diff --from <old-package.yaml> --to <new-package.yaml> --out <report.yaml>

# Publish a compiled package to a semver registry
ontologyc publish <package.yaml> --registry <url> [--token <token>]

# Download a published package from a registry
ontologyc pull <id>@<version> --registry <url> --out <directory>

# Check local package compatibility against a registry version
ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url> [--out <report.yaml>]
```

`--token` can also be supplied via the `ONTOLOGYC_TOKEN` environment variable.

## Project layout

```
Sources/
  OntologyC/          Thin CLI entry point (main.swift)
  OntologyCompiler/   Compiler phases: load → validate → normalize → emit
  OntologyRules/      Specification-pattern predicates (no I/O)

Tests/
  OntologyCompilerTests/   Integration + regression tests (byte-exact baseline comparison)
  OntologyRulesTests/      Pure unit tests for all Specification types

SPECS/
  ontology/           Sample package + committed baseline artifacts
  specgraph/          Semantic-binding fixtures
  INPROGRESS/         Active PRDs (one file per feature)
  Workplan.md         Phase-by-phase roadmap
```

## Specification pattern

All validation logic lives in `OntologyRules` and is expressed as `Specification<T>` or
`DecisionSpec<Context, Result>` types from the
[SpecificationCore](https://github.com/SoundBlaster/SpecificationCore) SPM package.
No raw booleans or ad-hoc conditionals in validation paths — every predicate has a
named type and a dedicated unit test.

Examples: `OntologySymbolNameSpec`, `ProtocolRelationConformanceSpec`,
`AllowedPolicyEnforceabilitySpec`, `DeclaredStateSpec`, `SpecGraphRefDecisionSpec`.

## Running tests

```bash
swift test
```

Regression tests compare generated TypeScript against committed baselines byte-for-byte.
When intentional output changes are made, regenerate with:

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
