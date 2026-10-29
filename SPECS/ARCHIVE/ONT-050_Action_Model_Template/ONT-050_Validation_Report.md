# ONT-050 validation report

Date: 2026-10-28. Verdict: PASS for the documentation/skill/template scope.
Base: ONT-049 `a170fceeb256f7778b61015642d31105c9a8725f`; this layer adds no runtime.

## Checks performed

| Check | Result |
|---|---|
| skill-creator `quick_validate.py` against repository skill | PASS |
| Same check against personal installed skill | PASS |
| Local skill/resource/navigation links | PASS, 16 checked |
| UI metadata | PASS, short-description bounds and default implicit discovery |
| Official `@cucumber/gherkin` 42.0.1 parser (MIT) | PASS, 5 scenario definitions, 12 expanded cases |
| Scenario Outline numerical consistency | PASS, all 8 rows: signed reduction, exact/at-least comparator, stated evaluation |
| Malformed-table negative control | PASS, parser rejects inconsistent cell count |
| `.flow/params.yaml` Markdown-scope gates | PASS, README and Workplan exist |
| Git whitespace checks | PASS |
| Local installation parity | PASS, all 6 installed files byte-identical to repository skill |

The first parser harness attempt omitted the library-required ID generator and
failed before parsing. Supplying `newId` fixed the harness; the table above records
the successful run, not that failed invocation.

## Evidence boundaries

Gherkin parsing and outline expansion are syntax/specification checks. No step
definitions, app acceptance tests, actual codec execution, PBT engine, production
goal evaluator or new Lean theorem were implemented or run. PBT material is a
catalogue of proposed properties, assumptions and mutation controls for a consumer.
Independent skill forward-testing and structured review are recorded separately.

The parent review of the forward exercise found one ambiguous Russian command/team
reading that had been silently treated as an actor. The skill now explicitly
separates action/command names from participants and keeps unspecified actors
unresolved or labeled as assumptions. A clarified follow-up prompt checks that
boundary; its result is recorded in the structured review.

Only guidance, templates and workflow documentation changed. Existing package
source/IR/SDK/profile bytes, compiler code and runtime tests are unchanged. The
unchanged Swift compiler was not rebuilt locally for this documentation-only layer;
hosted CI is a separate check on the final PR head.

## Local reproducibility

The official parser and its dependency were installed with lifecycle scripts
disabled under the verified TB5 checkout-specific `tmp/ont050-validation` directory.
The npm cache used the verified TB5 cache. No node_modules or build output was added
to the repository. Parser options included GherkinDocument, Pickles and a fresh ID
generator; the check inspected parse errors, scenario/expanded-case counts, all eight
example rows and rejection of a deliberately shortened table row.

The complete `skills/ontology-action-model` directory was copied into the user's
personal Codex skills directory only after confirming that destination did not
exist. Files were compared by SHA-256; the source remains versioned in this PR.
This installs a reusable skill, not a compiler plugin or changed profile default.
