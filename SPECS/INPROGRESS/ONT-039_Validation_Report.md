# ONT-039 Validation Report

Date: 2026-06-20
Branch: `codex/ont-039-layered-ontology-model`

## Scope

Validated the first compiler-backed layered ontology model contract:

- optional `layer` metadata on primary ontology elements;
- constrained layer vocabulary:
  `objective`, `mechanics`, `execution`, `meta`, `multi_agent`;
- deterministic compiler diagnostics for unsupported layer values;
- normalized IR preservation for layer metadata;
- generated TypeScript projection through refs and definitions;
- compatibility report `layerChanges` for class/relation layer additions and
  changes;
- updated generated `refs.ts` baselines for `examcalc` and `specgraph-core`.

## Validation Commands

```bash
swift test --filter MetadataSpecsTests --filter PackageValidationTests --filter TypeScriptEmitterTests --filter RegistryClientTests
```

Result: passed, 32 tests.

```bash
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/examcalc/generated
```

Result: passed.

```bash
swift run ontologyc compile SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml --target typescript --out SPECS/ontology/packages/specgraph-core/generated
```

Result: passed.

```bash
swift test --filter OntologyCRegressionTests --filter SpecGraphCorePackageTests
```

Result: passed, 16 tests.

```bash
swift test
```

Result: passed, 111 tests.

```bash
bash tools/swift-quality.sh
```

Result: passed. SwiftFormat lint, SwiftLint, isolated build, and isolated tests
all completed successfully.

## Residual Risks

- `layer` remains optional. Existing packages may still be flat until authors or
  downstream tools choose to annotate them.
- Compatibility reporting classifies class/relation layer changes as compatible
  review data in this MVP; stricter breaking semantics are deferred until
  downstream consumers prove they need them.
- `ModelApplicabilityProfile`, SpecGraph `LayeredConceptRef`, and SpecSpace
  layer lenses are intentionally deferred to follow-up repositories/tasks.
- Product ontology storage remains outside this repository except for
  examples/fixtures.
