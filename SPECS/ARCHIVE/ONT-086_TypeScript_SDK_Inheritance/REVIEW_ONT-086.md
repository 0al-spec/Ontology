# REVIEW REPORT — ONT-086 TypeScript instance inheritance

**Scope:** `origin/main` through the ONT-086 implementation and archive.

## Summary verdict

- [x] Approve with comments for the bounded generator change.
- [ ] Independent hosted review or release approval (not performed here).

## Findings and follow-up

- **Medium — standalone validation gap:** a cyclic class ancestry passes
  `ontologyc check` but `compile` now fails with `class.inheritance.cycle`.
  Commit-time advice uses the check path, so it cannot yet prevent this defect.
  Move the shared source-attributed inheritance checks into validation and
  exercise `checkSources` and `advise-staged` as ONT-087.
- **Medium — imported protocol obligations:** source-bound imported class
  fields are projected, but imported protocol obligations are not. The SDK and
  CLI explicitly warn rather than asserting complete inheritance. Preserve
  package/alias identity when implementing these obligations in ONT-088.

## Architectural and validation notes

Concrete `$type` defaults remain exact; `Parent<string>` is an intentionally
structural supertype, not a verified descendant registry. Foundation model
declarations are distinct from instance fields. The generated Zod schemas and
action-relationship records are checked alongside actual TypeScript consumers.
Source IR and pinned foundation catalogs remain unchanged.

The local quality gate passed 280 Swift tests with 89.68% line coverage, and
the SDK TypeScript/Zod smoke passed. CI, independent review, downstream pins,
publication, and deployment are separate.

## PR review corrections

- Local protocol requirements now reach standalone class schemas, including
  inherited `id`; the real TypeScript/Zod consumer tests presence, retention,
  and missing-field rejection.
- Inherited `Ref` targets now fail SDK generation if another supplied package
  or the root supplies a distinct class with the same canonical runtime name.
  Regressions cover collisions with local and other imported classes.
- A type-only foundation instance marker preserves the exact foundation URI
  without treating declaration metadata as runtime instance fields.
