# Ontology

`Ontology` is the lower semantic layer for 0AL/SpecGraph. It defines versioned
domain ontology packages and ships `ontologyc`, a static Swift compiler that turns
those packages into normalized IR, TypeScript SDK artifacts, semantic-reference
validation outputs, and registry-compatible bundles.

The current golden example is `edu.university.examcalc@0.1.0`: an exam-controlled
calculator ontology with concepts for exams, calculator functions, policy profiles,
exam-mode sessions, audit entries, policies, protocols, and state machines.

## Layer Model

| Layer | Owns | Does not own |
|---|---|---|
| Ontology Service | Domain concepts, relations, policies, state machines, versions, publication, governance | Engineering requirements, test evidence, implementation tasks |
| `ontologyc` | Static parsing, validation, normalized IR, generated SDK files, SpecGraph semantic validation artifacts | Runtime code execution, human approval, product intent interpretation |
| SpecGraph | Requirements, tests, evidence, semantic bindings, ontology imports, ontology gaps | Local redefinition of product/domain concepts |

YAML is always treated as inert data. `ontologyc` must not execute ontology hooks,
imports, factories, expressions, or generated files during validation.

## What `ontologyc` Emits

```text
domain-ontology-package.yaml  ->  ontologyc compile  ->  TypeScript SDK + IR
                                                       |-- types.ts
                                                       |-- schemas.ts
                                                       |-- validators.ts
                                                       |-- refs.ts
                                                       |-- relations.ts
                                                       |-- policies.ts
                                                       |-- state-machines.ts
                                                       |-- protocols.ts
                                                       |-- registry.ts
                                                       `-- ontology.normalized.json
```

SpecGraph validation uses the normalized IR to emit:

| File | Purpose |
|---|---|
| `concept-refs.yaml` | Resolved ontology references used by SpecGraph artifacts. |
| `ontology.lock.yaml` | Pinned ontology import metadata for semantic drift control. |
| `ontology-gaps.yaml` | Missing ontology references that must become ontology follow-up work. |

## Requirements

- Swift 6.0+
- macOS 13+ or Linux for normal SwiftPM builds
- `swiftformat` and `swiftlint` for the local quality gate

Install quality tools on macOS:

```bash
brew install swiftformat swiftlint
```

## Build

```bash
swift build --product ontologyc
```

Run the CLI through SwiftPM:

```bash
swift run ontologyc --help
swift run ontologyc compile --help
```

## Examcalc Walkthrough

Validate the canonical golden package:

```bash
swift run ontologyc check \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml
```

Compile it to deterministic TypeScript and normalized IR baselines:

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

Validate a SpecGraph semantic binding against the compiled ontology IR:

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/examcalc-semantic-validation
```

Run compatibility analysis between package versions:

```bash
swift run ontologyc diff \
  --from SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --to SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml \
  --out /tmp/examcalc-compatibility-report.yaml
```

Registry-oriented commands are also available:

```bash
swift run ontologyc publish <package.yaml> --registry <url|file-url> [--token <token>] \
  [--channel candidate|trusted] [--decision <decision.yaml>] [--golden-report <report.yaml>]
swift run ontologyc pull <id>@<version> --registry <url|file-url> --out <directory>
swift run ontologyc compat-check <package.yaml> --against <id>@<version> --registry <url|file-url> [--out <report.yaml>]
```

`--registry` accepts HTTP(S) registry URLs and local `file://` registry URLs. A local
registry directory can be kept in git and reviewed as ordinary files:

```bash
REGISTRY_URL="file:///tmp/ontology-registry"

swift run ontologyc publish SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --registry "$REGISTRY_URL"

swift run ontologyc pull edu.university.examcalc@0.1.0 \
  --registry "$REGISTRY_URL" \
  --out /tmp/pulled-ontology

swift run ontologyc compat-check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --against edu.university.examcalc@0.1.0 \
  --registry "$REGISTRY_URL" \
  --out /tmp/examcalc-compatibility-report.yaml
```

Local publication writes deterministic artifacts under `ontologies/` plus channel index
metadata under `channels/`. `ontologyc` does not run git commands; the registry root is
git-backed when you place it inside a repository and review/commit the resulting files.

`publish` defaults to `--channel candidate`. Trusted publication requires an approved
governance decision artifact that matches the package being published. `--golden-report`
is only meaningful with `--decision`; the CLI rejects that flag when no decision is supplied.

`--token` can also be supplied through `ONTOLOGYC_TOKEN`.

Hypercode resolved graphs can be imported as draft ontology packages:

```bash
swift run ontologyc import-hypercode <hypercode-ir.json> \
  --out <draft.yaml> \
  --id org.0al.example \
  --namespace example \
  --version 0.1.0
```

`import-hypercode` is a deterministic bridge from `hypercode.ir/v1` node types to
`DomainOntologyPackage` class drafts. The output is always `approvalStatus: draft`;
review and domain refinement still happen through the ontology authoring workflow.

Staged ontology-induction artifacts can be checked before final compiler validation:

```bash
swift run ontologyc validate-draft <draft-directory> --out <draft-validation-report.yaml>
```

The draft directory contains `intent-classification.yaml`, `product-ontology-draft.yaml`,
`draft-critique.yaml`, and `domain-ontology-package-draft.yaml`. This command checks
artifact shape, provenance, uncertainty fields, and draft package status. It is structural
evidence only; trusted publication still requires compiler validation and governance.

## Ontology Authoring

Do not start ontology authoring by writing YAML directly. For new product/domain intents,
use the staged induction workflow:

```text
intent -> prompt contracts -> validate-draft -> DomainOntologyPackage YAML
       -> ontologyc check -> ontologyc compile
```

Start with the [authoring guide](SPECS/ontology/authoring-guide.md), then use the
[induction protocol](SPECS/ontology/induction-protocol.md), stage-specific
[prompt contracts](SPECS/ontology/authoring-prompts/), and
[quality rubric](SPECS/ontology/ontology-quality-rubric.md).

Authoring agents do not need to use the strongest available model for every stage. Use
role-specific model selection from the authoring guide: stronger models are most valuable
for high-risk framing, critique, and governance-facing review, while cheaper/faster models
are acceptable for structured extraction or YAML assembly when golden expectations,
rubric review, and `ontologyc` validation remain stable.

## Quality Gate

Run the same local gate shape used by CI:

```bash
bash tools/swift-quality.sh
```

The gate checks:

- SwiftFormat in lint mode;
- SwiftLint with repository rules;
- Swift build with explicit-target dependency import checking;
- Swift tests in an isolated scratch path.

Run the gate with coverage reporting:

```bash
RUN_COVERAGE=1 bash tools/swift-quality.sh
```

Check the generated TypeScript SDK and Zod smoke fixture:

```bash
bash tools/typescript-smoke.sh
```

GitHub Actions runs the same script with `RUN_COVERAGE=1` on pull requests and
pushes to `main`, followed by the TypeScript SDK smoke gate.

## Documentation

DocC documentation is generated for the library targets and deployed to GitHub
Pages on pushes to `main`.

Generate local DocC output:

```bash
swift package --allow-writing-to-directory ./docs/ontologyrules \
  generate-documentation \
  --target OntologyRules \
  --output-path ./docs/ontologyrules \
  --transform-for-static-hosting \
  --hosting-base-path Ontology/ontologyrules

swift package --allow-writing-to-directory ./docs/ontologycompiler \
  generate-documentation \
  --target OntologyCompiler \
  --output-path ./docs/ontologycompiler \
  --transform-for-static-hosting \
  --hosting-base-path Ontology/ontologycompiler
```

The Pages workflow publishes:

- `OntologyRules`: `documentation/ontologyrules/`
- `OntologyCompiler`: `documentation/ontologycompiler/`

## Project Layout

```text
Sources/
  OntologyC/          Thin CLI entry point.
  OntologyCompiler/   Loading, validation orchestration, normalization, emitters.
  OntologyRules/      SpecificationCore-backed predicates and decisions.

Tests/
  OntologyCompilerTests/   Integration, CLI, emitted-baseline, registry tests.
  OntologyRulesTests/      Pure tests for Specification and DecisionSpec rules.

SPECS/
  ontology/           Ontology contracts, examples, golden package, baselines.
  specgraph/          Semantic validation fixtures.
  INPROGRESS/         Active task planning.
  ARCHIVE/            Completed task artifacts.
  Workplan.md         Phase-by-phase roadmap.
```

## Specification Pattern

Validation and classification logic belongs in `OntologyRules` as named
`Specification` or `DecisionSpec` types from
[SpecificationCore](https://github.com/SoundBlaster/SpecificationCore). Compiler
phases should call those rules instead of embedding domain decisions inline.

Examples:

- `OntologySymbolNameSpec`
- `ProtocolRelationConformanceSpec`
- `AllowedPolicyEnforceabilitySpec`
- `DeclaredStateSpec`
- `SpecGraphRefDecisionSpec`
- `OntologyReferenceSetResolutionSpec`

## Key Specs

- [Glossary](SPECS/ontology/glossary.md)
- [Core contracts](SPECS/ontology/core-contracts.md)
- [`ontologyc` compiler contract](SPECS/ontology/ontologyc.md)
- [Compiler IR](SPECS/ontology/compiler-ir.md)
- [Foundation types](SPECS/ontology/foundation-types.md)
- [Domain ontology package schema](SPECS/ontology/domain-ontology-package.schema.yaml)
- [Ontology authoring guide](SPECS/ontology/authoring-guide.md)
- [SpecGraph Ontology Induction Protocol](SPECS/ontology/induction-protocol.md)
- [Ontology quality rubric](SPECS/ontology/ontology-quality-rubric.md)
- [Golden intent set](SPECS/ontology/golden-intents/README.md)
- [Examcalc golden package](SPECS/ontology/packages/examcalc/README.md)
- [Hypercode roadmap](SPECS/ontology/hypercode-roadmap.md)

## Generated Baselines

Regression tests compare generated files in
`SPECS/ontology/packages/examcalc/generated/` byte-for-byte. When compiler output
changes intentionally, regenerate the baselines with:

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

Commit compiler changes and regenerated baselines together.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).
