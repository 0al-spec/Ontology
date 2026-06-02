# ``OntologyRules``

SpecificationCore-backed validation and decision rules for ontology packages.

## Overview

`OntologyRules` is the pure rules layer of the Ontology package. It owns named
`Specification` and `DecisionSpec` types and intentionally contains no file I/O,
CLI parsing, YAML loading, or generated-output materialization.

The compiler uses this module to keep ontology validation decisions explicit,
testable, and reusable:

- metadata and symbol pattern checks;
- local/imported concept-reference resolution decisions;
- relation range-shape classification;
- protocol conformance checks;
- policy enforceability checks;
- state-machine state membership checks;
- SpecGraph semantic-reference resolution;
- compatibility change classification.

## Rule Ownership

Every domain predicate should be a named `Specification` type. Every
classification that returns a typed result should be a named `DecisionSpec`.
Compiler phases should call these rules instead of embedding domain decisions
inline.

```swift
let spec = SpecGraphRefDecisionSpec()
let decision = spec.decide(SpecGraphRefDecisionContext(
    ref: "examcalc:Exam",
    conceptIndex: conceptIndex
))
```

## Typed Inputs

Rule inputs should use semantic value types instead of raw Foundation
primitives whenever the argument has domain meaning. For example,
``OntologySymbolNameSpec`` accepts ``OntologySymbolName`` instead of `String`,
and ``ExpectedOntologyApiVersionSpec`` accepts ``OntologyApiVersion`` instead of
`String`.

The value types are intentionally lightweight wrappers around parsed source
values. They make call sites self-documenting and let Swift reject accidental
mixing of package IDs, namespaces, versions, symbol names, YAML keys, and other
domain literals. Validation remains the responsibility of the named
`Specification` types.

## Topics

### Semantic Value Types

- ``OntologySymbolName``
- ``OntologyStateName``
- ``OntologyConceptReferenceLiteral``
- ``OntologyPackageId``
- ``OntologyNamespace``
- ``OntologySemanticVersion``
- ``OntologyApiVersion``
- ``OntologyPackageKind``
- ``PolicyEnforceability``
- ``YamlMappingKey``
- ``YamlScalarText``
- ``YamlSourceLine``

### Reference Decisions

- ``SpecGraphRefDecisionSpec``
- ``OntologyReferenceSetResolutionSpec``
- ``ConceptRefResolutionDecisionSpec``

### Compatibility Decisions

- ``CompatibilityChangeDecisionSpec``

### Relation Decisions

- ``RelationRangeShapeDecisionSpec``

### Metadata and Shape Specifications

- ``OntologySymbolNameSpec``
- ``OntologyNamespacePatternSpec``
- ``OntologySemVerPatternSpec``
- ``ExpectedOntologyApiVersionSpec``
- ``ExpectedDomainOntologyPackageKindSpec``

### Protocol, Policy, and State Specifications

- ``ProtocolRelationConformanceSpec``
- ``AllowedPolicyEnforceabilitySpec``
- ``DeclaredStateSpec``
