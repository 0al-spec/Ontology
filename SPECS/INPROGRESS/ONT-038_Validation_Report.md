# ONT-038 Validation Report

Date: 2026-06-18
Branch: `codex/ont-038-specgraph-core-package`

## Scope

Validated the draft compiler-backed SpecGraph Core ontology package:

- `SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml`
- `SPECS/ontology/packages/specgraph-core/generated/`
- `Tests/OntologyCompilerTests/SpecGraphCorePackageTests.swift`
- Swift 6.3 `SpecificationCore` compatibility package under `Vendor/SpecificationCore/`

## Package Contract

- Package id: `org.0al.specgraph.core`
- Namespace: `sgcore`
- Version: `0.1.0`
- Approval status: `draft`
- Core classes: 14
- Core relations: 16
- Draft authority boundary: `DraftAuthorityBoundary`
- Spec review lifecycle: `SpecReviewState`

The package is compiler evidence for downstream SpecGraph/SpecSpace semantic
surfaces. It is not trusted ontology publication and does not authorize
canonical SpecGraph mutations.

## Validation Commands

```bash
swift run ontologyc check SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml
```

Result: passed.

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/specgraph-core/generated
```

Result: passed and generated deterministic TypeScript/IR artifacts.

```bash
swift test --filter SpecGraphCorePackageTests
```

Result: passed, 3 tests.

```bash
swift build
```

Result: passed.

```bash
swift test
```

Result: passed, 106 tests.

```bash
git diff --check
```

Result: passed.

```bash
bash tools/swift-quality.sh
```

Result: passed. SwiftFormat lint, SwiftLint, isolated build, and isolated tests
all completed successfully.

## Residual Risks

- The package intentionally starts small. It should be expanded through
  compatibility-reviewed minor versions, not by treating v0 as complete.
- `approvalStatus: draft` must remain visible in downstream surfaces until a
  governance decision promotes the package.
- The repository currently vendors the minimal `SpecificationCore` API used by
  `OntologyRules` because upstream `SpecificationCore@1.0.0` fails to compile
  locally on Swift 6.3. This keeps the current compiler buildable but should be
  revisited if upstream publishes a compatible release.
