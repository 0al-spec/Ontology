# ONT-081 validation

Verdict: PASS locally on 2026-11-09; hosted CI and review are separate.

- `bash tools/swift-quality.sh`, with the checkout-specific Swift scratch
  directory on TB5: SwiftFormat, SwiftLint, build and complete Swift test suite
  passed, including 201 OntologyCompiler tests.
- Scoped CLI and library regression tests exercise missing, wrong-version and
  missing-target dependencies; separate old/new dependency snapshots; target
  version and canonical type changes; digest-only changes; trusted governance;
  a local registry round-trip; repeated imports; and legacy unbound registry IR.
- Failed dependency validation precedes compatibility report or registry
  publication. No network fetch of dependencies is introduced.
- This checks compatibility of declared target identities; it does not prove
  the imported package's behavioral or semantic compatibility.
