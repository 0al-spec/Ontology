# ONT-060 Validation Report

**Date** 2026-10-31

**Verdict** PASS for local implementation and verification; hosted CI/review pending.

## Delivered contract

`ontologyviz --profile <profile.json> --out <directory>` loads schemaVersion 1 JSON
with a package, view, direction, imports and expanded selectors. The worked example
saves the eight motivation-core/events-core type selections. Paths resolve relative
to the profile's actual file directory, including symlink targets. Output paths
remain relative to the invocation directory. CLI direction can override a valid
profile direction; format/output/renderer remain runtime options.

The loader rejects unknown keys, explicit nulls, wrong primitive/array types and
unsupported schema versions. It reuses shared typed view/direction parsing and the
normal CLI/library selection rule. Profile source is included in output-overwrite
protection. A JSON Schema and portable example are tracked alongside usage docs.

## Verification

- The final quality gate passed with 205 tests, 53 rule tests and 152 compiler/CLI
  tests. Format, strict lint, explicit-dependency build and coverage mode passed.
  Test-bundle line coverage is 90.45%; spawned CLI coverage is outside that report.
- Seven new profile CLI tests cover actual SVG/PNG from an unrelated working
  directory, DOT equality with the existing fixture, direction/runtime-format
  overrides, defaults, symlink-relative paths, invalid JSON/shape/version/choice,
  explicit nulls, conflicting flags and profile overwrite preservation.
- The complete existing diagram CLI suite passed, now 16 tests. The motivation
  profile's actual DOT equals the prior explicit-selector fixture byte-for-byte.
- The Draft 2020-12 schema, example and minimal profile were validated using the
  existing Platform Python environment's jsonschema validator, with negative
  structural controls. Python bytecode was routed to TB5.
- Both DocC catalogs passed with warnings-as-errors. TypeScript SDK smoke and
  the eight-package portable generated-output/structural contract gate passed.
- `git diff --check` passed. No new dependency was installed. All reproducible
  build/test/documentation/dependency outputs used the verified TB5 project paths.
  The temporary TypeScript node_modules symlink was removed by its wrapper.

## Base review finding

During this task, PR #82 received a P1 finding about duplicated semantic selection
predicates. It was fixed in base commit 1608c362a0e486283e029abc84594b84f1f3cf8f by
introducing DiagramSelectionSpec, used by both CLI and library. Independent rule
coverage and the 198-test base quality gate passed. The source thread was replied
to, reacted to and resolved. This profile branch was rebased onto that corrected
base, then the final 205-test and contract/DocC checks were rerun.

## Workspace and scope

Branch `feature/ONT-060-diagram-profiles` reuses `.worktrees/Ontology-visualization`.
The focused PR targets `feature/ONT-058-relations-view`. The current chain is
#81 → #82 → this profile layer. Keep the worktree active through review and retire
it once the stack lands. Primary ONT-059 work is independent.

One profile is an explicit local file. Profiles do not auto-discover files or
inherit each other. The runtime validates import/type selections and does not
fetch the optional editor schema hint. It remains the same type-schema renderer;
profiles add repeatable inputs, not instance evidence or ontology approval.
