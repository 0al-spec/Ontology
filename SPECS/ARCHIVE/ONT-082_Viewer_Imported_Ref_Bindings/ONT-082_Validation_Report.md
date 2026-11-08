# ONT-082 validation

**Verdict:** PASS locally; hosted CI and independent review are separate.
**Date:** 2026-11-09

## Executed checks

- In a TB5 copy of `tools/ontology-viewer`, `npm test` passed 51 tests and
  `npm run build -- --outDir <TB5>` passed TypeScript and Vite.
- Added red/green tests for an imported field in both projection views, a
  changed composition alias, rebased local references, wrong package, version,
  normalized digest or type, missing class and partial target metadata. Legacy
  unverified cross-package references remain unresolved.
- An isolated local test loaded the actual SpecGraph overview from commit
  `940e5b3a`; both `candidateProposal` and `candidateDraft` connected to their
  loaded core classes, with no extra scoped external node.
- In the standalone local Viewer, opened that graph and navigated
  `interpretsIntentForProposal` → `InterpretIntentForProposal` →
  `candidateProposal: Ref<Proposal>`; the inspector showed
  `sgcore:Proposal`, `org.0al.specgraph.core@0.3.0` and its source pointer.
  The only browser console error was the absent `/favicon.ico`.
- `git diff --check` passed. Build outputs and npm cache were routed to TB5.

## Boundaries

The target match uses the compiler's normalized source digest, not independent
source authentication or proof of an instance. SpecSpace's vendored Viewer and
the production site are unchanged until a separate consumer update is merged
and deployed. No ontology declarations or graph layout policies were changed.
