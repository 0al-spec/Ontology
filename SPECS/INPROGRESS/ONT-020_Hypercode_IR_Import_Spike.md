# PRD: ONT-020 - Hypercode IR Import Spike

**Status:** Complete  
**Priority:** P2  
**Phase:** Hypercode Bridge  
**Reasoning Effort:** medium  
**Dependencies:** ONT-019

## TL;DR

Add a small deterministic `ontologyc import-hypercode` command that consumes a
Hypercode resolved graph IR (`hypercode.ir/v1`) and writes a reviewable
`DomainOntologyPackage` draft.

## Objective

Provide the first concrete bridge between the Hypercode tooling repository and Ontology
without moving Hypercode parsing or cascade resolution into Ontology. Ontology consumes
only the resolved IR contract and emits YAML that can be checked by the existing compiler.

## Scope

### In Scope

- `ontologyc import-hypercode <hypercode-ir.json> --out <draft.yaml> --id <package-id> --namespace <namespace> --version <semver>`.
- Validate that the input is JSON object IR with `version: hypercode.ir/v1`.
- Traverse IR nodes and map each unique node `type` to a draft ontology class.
- Mark the root node type as the central class.
- Emit synthetic review scaffolding:
  - `contains` relation;
  - `GeneratedDraftRequiresReview` policy;
  - `GeneratedDraftLifecycle` state machine;
  - `ReviewGeneratedDraft` command.
- Regression test that the generated YAML passes `ontologyc check`.
- README documentation.

### Out of Scope

- Reading `.hc` or `.hcs` directly.
- Performing Hypercode cascade resolution inside Ontology.
- Inferring domain-specific policies, state machines, or relation semantics.
- Writing approved ontology packages.
- Updating generated TypeScript baselines.

## Contract

The importer is a draft bridge. It preserves the separation:

```text
Hypercode repo: .hc + .hcs -> hypercode.ir/v1
Ontology repo: hypercode.ir/v1 -> DomainOntologyPackage draft
```

The output MUST remain `approvalStatus: draft`; domain refinement and approval happen via
the ontology authoring protocol from ONT-019.

## Verification

```bash
swift run ontologyc import-hypercode \
  SPECS/ontology/hypercode/service.production.ir.json \
  --out /tmp/service-domain-ontology.yaml \
  --id org.0al.hypercode.service \
  --namespace hypercodeservice \
  --version 0.1.0

swift run ontologyc check /tmp/service-domain-ontology.yaml
bash tools/swift-quality.sh
```
