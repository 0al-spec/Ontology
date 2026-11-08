# ONT-079 validation

**Verdict:** PASS locally; hosted CI and independent review are separate.
**Date:** 2026-11-09

## Executed checks

- `bash tools/swift-quality.sh`: SwiftFormat, SwiftLint and the explicit Swift
  dependency-import build passed; 59 OntologyRules and 197 OntologyCompiler
  tests passed on macOS. SwiftPM scratch, package cache and temporary files
  were routed to TB5. Coverage was not measured locally.
- `bash tools/typescript-smoke.sh <fresh ontologyc>` in a TB5 source snapshot:
  TypeScript typechecking, existing SDK examples and the new imported-reference
  consumer passed. The latter rejects a same-named local type and accepts only
  the imported package's canonical discriminator in both TypeScript and Zod.
- Imported reference tests cover absent sources, wrong version, missing class,
  undeclared alias, duplicate inputs, ambiguous canonical namespace, local
  namesakes, a BOM-normalized source digest, and full projection through a
  transitive import with rebased aliases.
- An isolated copy of the SpecGraph review composition compiled after replacing
  four repeated class declarations and six repeated relations with references
  to core; the generated graph retained all five action relationships. This is
  a prototype, not a SpecGraph migration or production observation.
- A separate Git index was used to probe `advise-staged`: the current compiler
  reports an imported target as unresolved because the advisory cannot receive
  staged import sources. The repository's separately installed older hook also
  reports `ref` as unsupported. Neither message is a failed strict check.
- `git diff --check` passed; FLOW's configured README and workplan files exist.

## Boundaries

Imports are supplied local sources only; no discovery or fetching occurs.
Generated references preserve a type discriminator and source identity, not
proof that a referenced runtime instance exists. `diff`, registry `publish` and
other workflows without import arguments do not yet support these imported
fields and fail closed; the non-blocking staged advisory consequently reports
an unresolved target. A release and consumer migration are separate steps.
