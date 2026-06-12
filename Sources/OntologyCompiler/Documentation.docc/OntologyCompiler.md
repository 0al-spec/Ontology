# ``OntologyCompiler``

Compiler orchestration for DomainOntologyPackage validation, normalization,
emission, registry interaction, and SpecGraph semantic validation.

## Overview

`OntologyCompiler` owns the impure compiler boundary. It loads YAML and JSON as
inert data, delegates validation decisions to `OntologyRules`, normalizes package
content into deterministic IR, emits TypeScript SDK artifacts, and materializes
SpecGraph validation outputs.

The public executable target `OntologyC` is intentionally thin: it parses the
command shape, delegates to this module, prints stable command output, and exits
with the expected status code.

## Main Workflows

### Package Check

`check` parses a `DomainOntologyPackage`, validates metadata, imports, classes,
relations, policies, protocols, and state machines, then emits diagnostics.

```bash
swift run ontologyc check \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

### TypeScript Compilation

`compile` validates the package, writes `ontology.normalized.json`, and emits
deterministic TypeScript artifacts such as `types.ts`, `schemas.ts`,
`validators.ts`, `relations.ts`, `policies.ts`, and `registry.ts`.

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

### SpecGraph Semantic Validation

`validate-specgraph` resolves imported ontology references from SpecGraph
artifacts and emits `concept-refs.yaml`, `ontology.lock.yaml`, and
`ontology-gaps.yaml`. It also emits `ontologyc-adapter-report.yaml`, a
review-only adapter boundary report that records package source/version/digest,
input and output refs, summary counts, and explicit no-canonical-mutation
authority flags.

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/examcalc-semantic-validation \
  --source-uri git+https://github.com/0al-spec/Ontology.git \
  --source-ref main
```

### Compatibility Reports

`diff` compares package versions and emits an
`OntologyCompatibilityReport` describing compatible and breaking changes.

## Security Boundary

Ontology YAML is untrusted input. The compiler must not execute hooks, imports,
factories, expressions, generated files, or any YAML-derived code. All parsing is
data-only, and executable-looking YAML content is validated as inert data.

## Topics

### Compiler Argument Types

- ``OntologySourcePath``
- ``OntologyOutputDirectory``
- ``OntologyOutputPath``
- ``RegistryBaseURL``
- ``OntologyPackageReference``

### Compiler Entry Point

- ``OntologyCompiler``

### Diagnostics

- ``Diagnostic``
