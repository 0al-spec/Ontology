# agents.md — Ontology Project Guide

## What this project is

`ontologyc` is a static compiler for domain ontology packages. Authors write ontology
definitions in YAML (`DomainOntologyPackage`), and the compiler validates them, normalizes
them into a deterministic JSON IR, and emits a TypeScript SDK: typed interfaces, relation
and policy constants, state-machine definitions, a unified registry, and ref validators.
A secondary `validate-specgraph` command checks that SpecGraph binding documents reference
only concepts that exist in a compiled ontology.

The project is a Swift package (macOS 13+, Swift 6.0) with three targets:

| Target | Role |
|--------|------|
| `OntologyC` | Thin CLI entry point (`Sources/OntologyC/main.swift`) |
| `OntologyCompiler` | Compiler phases: loading, validation, normalization, emit, diff |
| `OntologyRules` | All validation predicates and decision logic as named specifications |

---

## Running and validating

```bash
# Check a package
swift run ontologyc check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml

# Compile to TypeScript
swift run ontologyc compile SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript --out /tmp/examcalc-out

# Validate a SpecGraph binding against compiled IR
swift run ontologyc validate-specgraph <binding.yaml> \
  --ontology-ir <ontology.normalized.json> --out <dir>

# Compatibility diff between two versions
swift run ontologyc diff --from <old.yaml> --to <new.yaml> --out <report.yaml>

# Full quality gate (format + lint + tests)
bash tools/swift-quality.sh

# With coverage
RUN_COVERAGE=1 bash tools/swift-quality.sh

# Tests only
swift test
```

---

## Specification pattern (SpecificationCore)

**The central architectural pattern throughout `OntologyRules` is the Specification pattern**,
provided by the `SpecificationCore` SPM dependency.

Every validation predicate is a named, single-responsibility Swift type that conforms to one
of two protocols:

```swift
// True/false predicate — used for guard checks
protocol Specification {
    associatedtype T
    func isSatisfiedBy(_ candidate: T) -> Bool
}

// Multi-outcome classification — used where a decision has named branches
protocol DecisionSpec {
    associatedtype Context
    associatedtype Result
    func decide(_ context: Context) -> Result?
}
```

Examples in `Sources/OntologyRules/`:

| File | What it specifies |
|------|-------------------|
| `MetadataSpecs.swift` | ID pattern, namespace pattern, semver, symbol names |
| `ReferenceSpecs.swift` | Local/imported concept ref resolution |
| `ReferenceDecisionSpecs.swift` | `.local` / `.imported` / `.unresolved` / `.invalidSyntax` |
| `SecuritySpecs.swift` | Unsafe YAML tags, executable-looking values, dangerous keys |
| `RelationDecisionSpecs.swift` | Relation range shape: `.scalarRef` / `.oneOfRefs` / `.invalid` |
| `CompatibilityDecisionSpecs.swift` | Change classification: `.breaking` / `.compatible` / `.unknown` |
| `PolicySpecs.swift` | Allowed enforceability values |
| `SpecGraphDecisionSpecs.swift` | Resolved vs. gap concept reference decisions |

`OntologyCompiler` calls into these specs; it never duplicates the predicate logic inline.
`OntologyRulesTests` unit-tests each specification cluster in isolation.

---

## Where specifications live

```
SPECS/
  Workplan.md                          Task list with status and dependencies
  INPROGRESS/
    next.md                            Current / next tasks
    ONT-016_*.md  ONT-017_*.md  …      PRDs for tasks in progress
  ARCHIVE/
    INDEX.md                           Completed task index
    ONT-001_*/  …  ONT-010_*/          Archived PRDs and validation reports
  ontology/
    domain-ontology-package.schema.yaml  YAML schema for DomainOntologyPackage
    ontologyc.md                         Compiler contract and module boundaries
    glossary.md  core-contracts.md …    Domain and architecture specs
    examples/    fixtures/   packages/  Sample ontologies and test fixtures
  COMMANDS/
    FLOW.md                            Development workflow definition
```

---

## Task workflow starts in FLOW.md

All development tasks follow the documentation-driven workflow defined in
**`SPECS/COMMANDS/FLOW.md`**. Every task has a PRD in `SPECS/INPROGRESS/` before
implementation begins. The sequence is:

```
BRANCH → SELECT → PLAN → EXECUTE → ARCHIVE → REVIEW → FOLLOW-UP → ARCHIVE-REVIEW
```

Each step ends with a commit. New tasks are listed in `SPECS/Workplan.md`; the current
task and sequencing notes are in `SPECS/INPROGRESS/next.md`.
