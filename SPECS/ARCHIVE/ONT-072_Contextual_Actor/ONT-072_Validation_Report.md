# ONT-072 verification

Local macOS run on the ONT-072 branch:

- Swift quality gate passed format, lint, build, 55 rules tests and 175 compiler tests.
- The portable contract smoke passed the theatre replay, frozen SDK comparisons and structural profiles. The release smoke matched the 0.2.0 export bytes and rendered the diagram.
- The Ruby reference checker passed all 12 fixtures including the theatre package.
- The new CLI rejected class inheritance from Actor and SystemActor for the theatre package at 0.2.0. The archived 0.1.0 vocabulary retains its original type inventory.
- The replay validated both recorded appointments, rejected incomplete replacement and a dangling director, and accepted an alternative existing director with sourceTruthVerified false.

## Repository inventory at c52553f

The compiler export table, checked-in catalog, foundation type documentation and glossary defined both actor kinds. Package reference-slot tests exercised sg:Actor. Five induction fixtures used sg:Actor for Speaker (the valid voice recorder and four negative variants). They now use DomainEntity with the existing hasSpeaker relation. The active packages under SPECS/ontology/packages used contextual roles and had no inheritance from either actor kind.

This inventory covers the Ontology repository. A consuming project selects the new vocabulary and compiler together.
