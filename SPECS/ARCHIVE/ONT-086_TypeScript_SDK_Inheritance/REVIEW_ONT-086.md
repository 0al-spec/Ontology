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

The local quality gate passed 277 Swift tests with 89.73% line coverage, and
the SDK TypeScript/Zod smoke passed. CI, independent review, downstream pins,
publication, and deployment are separate.
