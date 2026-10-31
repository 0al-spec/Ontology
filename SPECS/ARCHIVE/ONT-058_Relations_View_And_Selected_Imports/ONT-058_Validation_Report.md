# ONT-058 Validation Report

**Date** 2026-10-31

**Verdict** PASS for local verification; external review and hosted CI pending.

## Delivered behavior

- `--view relations` renders domain relation edges and their classes. Every root
  relation is retained. Only incident root classes are shown; all selected imported
  classes are shown. Full view is the default.
- Repeatable `--import` and `--expand` supply direct local dependencies and explicit
  qualified class selections. Exact id/version, unique aliases, alias rebasing and
  namespace scope use named SpecificationCore rules with semantic value types.
- Imported relations form the induced subgraph of selected imported/root classes.
  Every alternative of an imported oneOf relation must be selected before the
  relation is shown. Root relations retain unexpanded external placeholders.
- Loaded imported nodes are green and identify their package/version. The caption
  identifies a selected relation view. The library exposes typed diagram options.
- Every input package, including explicit imports, is protected against output
  replacement. No filesystem discovery or remote dependency fetching is performed.

## Verification

- `RUN_COVERAGE=1 bash tools/swift-quality.sh` passed with TB5 scratch/cache paths.
  All 195 tests passed, 50 rules and 145 compiler/CLI tests. This adds 16 tests to
  the 179-test ONT-056 base. Strict format/lint/build checks passed.
- Test-bundle line coverage is 90.42%. Spawned CLI coverage remains outside that
  report. Public DocC for OntologyCompiler and OntologyRules passed with
  `--warnings-as-errors`.
- Regression tests verify the existing full-view DOT byte-for-byte, relation-view
  filtering, actual imported declarations, aliases, wrong id/version, unknown
  selectors, duplicate bindings, imported namespace shadowing, selector/input order,
  partial oneOf omission and a cyclic declared reference back to the root package.
- Real Graphviz CLI tests produce parseable SVG and PNG with the expanded
  interpretation/record/Delta relations. CLI option syntax and repeatable inputs
  are checked. A supplied import named ontology.dot is preserved when it collides
  with the requested output path.
- `bash tools/portable-contract-smoke.sh` passed across the eight generated-package
  baselines and existing structural/provenance controls.
- `bash tools/typescript-smoke.sh` passed. Its npm ci operation used a copied
  package/lock manifest under the TB5 dependency prefix; the project used a temporary
  node_modules symlink for subsequent scripts. Cleanup removed that symlink.
- Motivation-core was rendered using events-core 0.2.0 with eight selected classes.
  The actual PNG was inspected. A second render with reordered selectors matched
  the saved DOT. SVG/PNG/DOT examples are checked into the worked-example directory.
- `git diff --check` passed.

All build, test, documentation and dependency outputs used the existing verified
TB5 project paths. An initial DocC archive move needed its external parent directory
created; both module documentation commands then passed. No extra dependency was
installed for this slice.

## Review boundaries

The selected view has thirteen class nodes and includes the declared paths through
Interpretation, RecordedEvent, StateSnapshot, Delta, RoleBinding and CausalHypothesis.
It is a type schema. Different event occurrences or cause/effect roles can share one
type node. The loader checks the supplied local files under the compiler's current
contract; id/version matching is not source authentication or a consumer digest pin.
Imported relations outside the selected class set are intentionally omitted as a
whole. The full package view and external references are available separately.

This task reuses `.worktrees/Ontology-visualization`, branch
`feature/ONT-058-relations-view`, atop ONT-056 PR #81. Keep it active for stack review
and retire it after the stack lands. ONT-055/057 primary work is independent.

## Review follow-up on 2026-10-31

Addressed the P1 thread on duplicated diagram-selection predicates.
`DiagramSelectionSpec` now owns expansion-mode, paired inputs and empty-selector
decisions. Both CLI and library consume that rule and its shared messages.
OntologyViz declares its direct OntologyRules dependency. Three independent
rule tests cover the acceptance matrix. The complete quality gate passed with
198 tests, strict lint/format/build and coverage. This fix precedes ONT-060
profiles so their effective selection uses the shared rule as well.
