# Ontology Glossary

## Purpose

This glossary defines the terms used by the Ontology Layer and the SpecGraph semantic import model. Terms in this document are normative when referenced by ONT-001 deliverables.

## Core Terms

| Term | Definition |
|---|---|
| ABox | Concrete facts or instances that conform to a TBox ontology, such as a signed exam policy document. ABox validation is deferred for ONT-001. |
| Bounded Context | A semantic boundary where terms, relations, and policies are internally consistent. |
| Capability | A product ability that can be allowed, denied, constrained, or referenced by requirements. |
| Command | An intentional action that requests a state transition or domain behavior. |
| Competency Question | A validation question the ontology must be able to answer using defined concepts and relations. |
| ConceptRef | A canonical reference to one ontology concept, including ontology id, version, kind, URI, and alias. |
| DomainOntologyPackage | A versioned declarative ontology package that defines domain concepts, relations, policies, and state machines. |
| Event | A meaningful occurrence in the domain, usually emitted by a workflow or state transition. |
| Foundation Meta-Model | The stable set of base kinds and protocols used by product ontologies. |
| OntologyGap | A SpecGraph artifact created when a required concept cannot be resolved in imported ontology packages. |
| OntologyImport | A SpecGraph project declaration that imports and pins a domain ontology package. |
| OntologyLockfile | A resolved record of ontology imports, versions, content digests, and aliases used to prevent semantic drift. |
| Ontology Service | The lower layer that owns ontology induction, governance, registry, publication, and versioning. |
| OntologyDelta | A candidate or approved change set against an existing ontology version. |
| SemanticBinding | A SpecGraph artifact that links an engineering artifact, such as a requirement or test, to ontology references. |
| Semantic Drift | A change in concept meaning or relation semantics that can invalidate older specifications. |
| SpecGraph | The engineering graph over imported ontologies; it owns requirements, tests, evidence, decisions, and traceability. |
| TBox | The ontology schema layer: classes, relations, policies, state machines, and constraints. |

## Foundation Kinds

| Kind | Meaning |
|---|---|
| Actor | Human, organization, role, or party acting in the domain. |
| SystemActor | External system or managed runtime actor. |
| DomainEntity | Object with identity and lifecycle. |
| ValueObject | Structured value without independent identity. |
| Capability | Something the product can do or expose. |
| Command | Intentional action initiated by an actor or system. |
| Event | Something meaningful that happened. |
| Policy | Rule controlling what is allowed, required, or forbidden. |
| Invariant | Condition that must always hold. |
| StateMachine | Named lifecycle model with states and transitions. |

## Protocols

| Protocol | Meaning |
|---|---|
| Approvable | The concept has explicit approval state and authority metadata. |
| Auditable | The concept can be referenced by durable audit evidence. |
| DeviceBound | The concept is bound to a device identity or trust context. |
| RestrictableCapability | The capability can be allowed, denied, or constrained by policy. |
| Signable | The concept can carry a signature or signer reference. |
| TimeBound | The concept has validity or activity windows. |
| Versioned | The concept has version identity and compatibility semantics. |
