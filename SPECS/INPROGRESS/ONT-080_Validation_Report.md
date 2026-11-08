# ONT-080 validation

**Verdict:** PASS locally; hosted CI and independent review are separate.
**Date:** 2026-11-09

## Executed checks

- `bash tools/swift-quality.sh` with SwiftPM scratch and cache on TB5 passed
  SwiftFormat, SwiftLint, the explicit dependency-import build, 59 rule tests
  and 198 compiler tests on macOS. Coverage was not measured locally.
- `bash tools/staged-package-advice-smoke.sh <fresh ontologyc>` passed with
  both `git commit` and `rtk git commit` in disposable repositories.
- The smoke stages valid model and import blobs, overwrites both working-tree
  files, and confirms advice remains quiet. A separate alternate index with an
  invalid reference or wrong import version reports `class.field.target.unresolved`
  while the original index still passes. Paths contain spaces.
- Missing, unmerged, symlink and non-UTF-8 import paths report the affected
  package could not be checked; no worktree substitution occurs. Existing
  malformed-package, 4 MiB bound and independent hook veto checks still pass.
- `git diff --check` passed. The configured FLOW README and workplan files exist.

## Boundaries

Only explicitly named repository-root-relative index paths are supplied; there
is no discovery or network fetch. Advice is non-blocking and is not canonical
acceptance. Strict `check --import` continues to read its explicit filesystem
sources. The existing installed hook may still point to an older binary until
it is intentionally updated; this change does not rewrite user Git configuration.
