# Next Task

## ONT-038 — SpecGraph Core Ontology Package

Status: INPROGRESS
Branch: `codex/ont-038-specgraph-core-package`
Priority: P0
Dependencies: ONT-036, ONT-037

## Goal

Materialize the small SpecGraph Core Ontology seed as a real
`DomainOntologyPackage`, compile it with `ontologyc`, and make its normalized IR
available for downstream SpecGraph semantic binding, gap, and diff workflows.

## Recently Archived

- ONT-037 — SpecGraph Owner Decision Report Export archived on 2026-06-14.

## Suggested Next Steps

- Create `SPECS/INPROGRESS/ONT-038_SpecGraph_Core_Ontology_Package.md`.
- Add `SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml`.
- Run `ontologyc check` and `ontologyc compile`.
- Record validation in `SPECS/INPROGRESS/ONT-038_Validation_Report.md`.
