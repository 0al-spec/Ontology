# ONT-066 validation report

Date: 2026-10-31.
Verdict: PASS locally; independent review and hosted CI remain pending.

- Swift quality gate passed: formatting, strict lint, explicit target dependency
  checking, 55 rule tests and 172 compiler/CLI tests (227 total).
- Viewer production TypeScript/Vite build and 13 unit tests passed.
- All 16 Chromium scenarios passed with real ontologyc/ontologyviz binaries.
  New coverage exercises imported policies/source inspection, lifecycle and
  transition counts, zero categories, and position retention after filtering.
- Compiler regressions cover rebasing every declaration family, nested triggers,
  source/field pointers, two-import order independence in JSON/DOT, duplicate
  imports and an unbound nested namespace. CLI full profile without expand passes.
- Real NormLab snapshot: five packages produce 53 classes, 73 relations, 25
  policies and five state machines. Browser displays 104 nodes/287 visual links,
  including external references and state nodes; imported policy inspection
  correctly addresses normlab.parking /spec/policies/BasicScope.
- Sources and pilot data remain local snapshots; NormLab was not edited.
  Build, caches, disposable test sources and generated graphs are on verified TB5.

Limits: no recursive dependency fetch, package trust admission, policy execution,
semantic validation, release or deployment. Unbound nested namespaces fail with
an actionable diagnostic. Absolute throughput/latency and coverage percentage
were not measured. Category counts describe the canvas, not only declarations.
