# ONT-054 — Optional Local Package Sections

Status: Planned; bounded implementation authorized by the operator on 2026-10-30.

## Problem and source

The SpecGraph SG72-MIXED pilot needed a manual policy and an unbound draft-to-draft
state machine solely to satisfy the compiler's package shape. This invents
irrelevant declarations when an author wants to compile a small local model.
The current schema, Swift validator and Ruby fixture validator require nonempty
maps, while normalization and TypeScript emission already support empty ones.

Source: [SpecGraph #839](https://github.com/0al-spec/SpecGraph/pull/839),
`specs/models/SG-SPEC-0072/domain-ontology-package.yaml` and the curated record
`docs/reviews/0233_mechanical_specification_authoring/local-model-pilot/README.md`.
The operator requested Sol 6.1 High to make fixes directly in Ontology. This
task implements the package-shape issue; it does not reinterpret the scenario.

## Contract and deliverables

1. `spec.policies` and `spec.stateMachines` are optional object/map sections.
   Omission and `{}` mean no local declarations. Explicit `null`, arrays and
   scalar values remain invalid. Other required sections retain their contract.
2. Every supplied policy and state machine retains existing structural and
   reference checks. A lifecycle reference to an absent machine remains an
   error; allowing an empty section must not silently drop referenced behavior.
3. Normalized IR uses the existing empty collection representation, and the SDK
   keeps the existing output-file/registry surfaces. Existing nonempty package
   outputs remain stable; no generated ontology package or vocabulary revision
   changes are needed merely for the relaxed authoring shape.
4. Align the YAML schema, Swift package validation and Ruby fixture validation.
   Add small valid fixtures and public compiler regression tests. Malformed
   sections, malformed supplied declarations, missing lifecycle machines and
   invalid local relation references remain negative cases.
5. Document the current compiler contract. Explain previous padding as historical
   friction in the pilot README without rewriting saved intent, observations,
   generated IR or old evidence to pretend the historical run had this behavior.

## Implementation scope

- `Sources/OntologyCompiler/PackageValidation.swift`.
- `SPECS/ontology/domain-ontology-package.schema.yaml` and `ontologyc.md`.
- `SPECS/ontology/fixtures/validate-fixtures.rb` and two minimal valid fixtures.
- `Tests/OntologyCompilerTests/OptionalPackageSectionsTests.swift`.
- Narrow explanatory updates to the existing image-pilot README where needed.

Keep existing SpecificationCore predicates authoritative. This is structural
input handling and removal of unnecessary emptiness requirements, not a new
runtime policy. If another predicate needs a change, explain it before expanding
the file scope. Do not introduce a generic instance graph validator or import
resolver: namespace-only imported-reference recognition and EventCore-specific
instance profiles are separate declared capability boundaries.

## Verification

- Reproduce the rejected minimal shape using the existing release compiler.
- Test omitted/empty/mixed optional sections through real public compilation.
- Verify empty IR/SDK surfaces and retained rejection of malformed supplied data.
- Run Ruby fixture validation, the project Swift quality gate and deterministic
  existing-package baselines with per-worktree outputs on the verified TB5 disk.
- Run the original SpecGraph package with only the artificial sections removed
  against the new binary, keeping the source copy and outputs in scratch space.
- Record exact commands, results, limitations and generated output locations.

## Workflow and ownership

Base: Ontology main `1a47f7058228efb412cbdeaabbaf27bca25e9846`.
Branch: `feature/ONT-054-local-package-ergonomics` in an isolated task worktree.
Root owns FLOW checkpoints, independent review, archive and PR publication;
Sol 6.1 High owns the bounded implementation and regression validation.
Publish a focused PR after local verification. Merge, release and updating
SpecGraph's compiler pin are subsequent tasks, not automatic consequences.
