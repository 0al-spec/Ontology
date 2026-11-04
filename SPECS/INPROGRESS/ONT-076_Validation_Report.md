# ONT-076 validation — PASS locally

The new `edu.university.examcalc@0.2.0-draft.1` was checked and compiled using the current repository compiler. The seven local classes include two `ont:Action` subclasses. The SDK carries two executable relationships and the structural set-membership relation. The original quote matches the suffix of the unique source message with the declared speaker and ID. The draft introduces neither a mandatory active profile nor the older signing and audit requirements.

| Check | Observation |
|---|---|
| `ontologyc check`, TypeScript compilation | Passed for the new package. Substituting `CalculatorFunction` as the action failed with `relation.action.wrong_kind` at `spec.relations.appliesFunctionSet.action`. |
| `bash tools/typescript-smoke.sh <built ontologyc>` | Strict type-check, generated schemas and executable consumer passed. An exam reference is not a set reference. Two assignments precede both applications; addition succeeds on both exams, sine runs only on trigonometry. A different set with identical membership is rejected, as are missing and unknown references; a known empty set remains distinguishable. |
| Wrong but type-correct implementation (isolated copy) | Changed lookup to return the most recently applied set regardless of the exam. Strict TypeScript still passed; the unchanged example failed at `arithmetic/sine: available != unavailable`. |
| `ruby SPECS/ontology/fixtures/validate-fixtures.rb`; historical `examcalc/validate-golden.rb` | 15/15 package fixtures and all 25 historical semantic refs passed. The 0.1.0 input and its SDK/bindings are unchanged. |
| `bash tools/swift-quality.sh` | Local format, lint, build and all 181 Swift tests passed. |
| Viewer | `ontologyviz --format svg` rendered the new package. The local replay of the Swift Quality archive step produced a zip with the exact new YAML, matching manifest version, three compiled relationships and all listed files. |

Scope: the human's outcome is an input, not an inference from a green compiler. This is one proposed interpretation and a local SDK consumer; no tablet deployment, arbitrary Russian language processing, trusted publication or human review of the package is claimed.
