# Contributing

## Workflow

All planned work starts in [SPECS/INPROGRESS/](SPECS/INPROGRESS/) — read
[FLOW.md](SPECS/COMMANDS/FLOW.md) for the branch-to-archive lifecycle before starting
any feature.

## Making changes

1. Branch from `main`. Use the prefix that matches the task ID, e.g.
   `codex/ont-018-registry-cli`.
2. Run the local quality gate before pushing:

   ```bash
   bash tools/swift-quality.sh
   ```

   To include the same coverage report mode used by CI:

   ```bash
   RUN_COVERAGE=1 bash tools/swift-quality.sh
   ```

   The CI gate enforces lint, format, build, tests, and coverage.
3. Keep commits focused. One logical change per commit.

## Code conventions

**Validation lives in `OntologyRules`.** Every predicate must be a named
`Specification<T>` or `DecisionSpec<Context, Result>` type. Do not inline
boolean conditions in the compiler phases.

**No comments explaining what the code does.** Name things well instead.
Add a comment only when the *why* is non-obvious — a hidden constraint, a
workaround, an invariant that would surprise the reader.

**Parameter counts.** SwiftLint is configured with `function_parameter_count`
warning at 6 and error at 7. When a function needs more context, pass a
dedicated context struct.

**Swift 6 strict concurrency.** Do not add `@preconcurrency` or `nonisolated`
suppression without a comment explaining why it is safe.

## Baselines

Generated TypeScript files in `SPECS/ontology/packages/examcalc/generated/`
are committed baselines compared byte-for-byte by `OntologyCRegressionTests`.
When an intentional output change is made, regenerate them:

```bash
swift run ontologyc compile \
  SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --target typescript \
  --out SPECS/ontology/packages/examcalc/generated
```

Then commit the updated baselines alongside the compiler change in the same
commit so the test never goes red on `main`.

## Tests

- Unit tests for new `Specification` types go in `Tests/OntologyRulesTests/`.
- Integration tests and regression comparisons go in
  `Tests/OntologyCompilerTests/`.
- Every new CLI command needs an argument-parsing test (flag-order independence,
  `--help` output).
- Competency-question and SpecGraph semantic-reference tests should resolve
  references through `OntologyRules` decision specs instead of duplicating lookup
  logic in tests.

## Documentation

- Public library API documentation lives in DocC catalogs under
  `Sources/OntologyRules/Documentation.docc/` and
  `Sources/OntologyCompiler/Documentation.docc/`.
- Keep DocC symbol links in sync with real Swift symbols when adding or renaming
  rules, decisions, diagnostics, or compiler entry points.
- The GitHub Pages workflow builds DocC on pull requests and deploys it only on
  pushes to `main`.

## Pull requests

- PR titles should be short (≤ 70 characters) and start with the task ID,
  e.g. `ONT-018: Add publish/pull/compat-check CLI commands`.
- Include a brief description of *why* the change is made, not just *what*
  changed.
- All CI checks must be green before merging.
