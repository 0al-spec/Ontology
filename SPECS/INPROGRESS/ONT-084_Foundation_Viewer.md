# ONT-084 — Foundation definitions in the Viewer

## Intent

A user inspecting a package should see the actual versioned declarations of
the foundation types it references when their catalog has been explicitly
provided. Missing catalogs remain visibly unresolved.

## Deliverables

- Accept repeatable local foundation model inputs for diagram generation.
- Bind them to reachable imports by exact package identity and version;
  preserve the diagram alias, catalog bytes and model source provenance.
- Expose catalog-backed referenced definitions in the standalone Viewer and
  show their source and declaration without treating them as YAML packages.
- Document repeatable use and compatibility with older diagrams.

## Acceptance criteria

- No implicit network fetch or local-path guessing. A missing model never becomes
  a loaded declaration; unsupported, modified, duplicate or unrelated inputs
  are rejected, with no output files written.
- Both historical 0.1.0 identities remain distinguishable from 0.2.0, and
  transitive imports use their graph-local alias rather than name matching.
- Existing diagrams without supplied catalogs remain valid and unchanged.
- Viewer filters and source inspection distinguish loaded from unresolved nodes.
- Swift, viewer tests and quality checks cover the boundary, exact identities,
  malformed inputs and expected real examples.

## Out of scope

Changing or approving foundation meanings, treating a catalog as a
DomainOntologyPackage, or silently changing deployed consumers. SpecGraph and
SpecSpace consume the new projection in subsequent coordinated work.
