# ONT-083 — Source-attributed foundation model catalogs

## Problem

The versioned foundation exports verify symbol names, but cannot supply the
actual definitions behind those names to a viewer. Foundation is the compiler's
terminal vocabulary, not a normal self-importing DomainOntologyPackage.

## Deliverables

- Preserve the exact published foundation model documentation for versions
  0.1.0 and 0.2.0 with commit and byte digest provenance.
- Provide a deterministic machine-readable catalog for each version containing
  the exact TypeScript interface declarations for all exported classes and
  protocols, plus the supporting interfaces referenced by those declarations.
- Check catalog coverage against the existing export tables and source text;
  stale, omitted or altered definitions fail the verification.
- Document the format and the legacy `specgraph.foundation@0.1.0` alias.

## Boundaries

Catalogs expose published declarations, not invented domain packages,
inheritance edges, semantic approval, or execution evidence. A subsequent
visualizer/consumer slice will read them using their own source pointers;
this task alone does not claim the website has loaded the definitions.
