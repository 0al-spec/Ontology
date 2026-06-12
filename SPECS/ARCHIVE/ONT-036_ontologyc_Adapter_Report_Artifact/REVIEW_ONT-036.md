## REVIEW REPORT — ONT-036

**Scope:** `origin/main..HEAD`
**Files:** 14

### Summary Verdict

- [x] Approve
- [ ] Approve with comments
- [ ] Request changes
- [ ] Block

### Critical Issues

None.

### Secondary Issues

None.

### Architectural Notes

- The change keeps Ontology as the compiler/package authority and emits a
  review-only adapter report for SpecGraph proposal 0060 without adding
  SpecGraph canonical mutation behavior.
- `source_uri` and `source_ref` are operator-supplied metadata, while
  `package.digest` remains derived from normalized IR `sourceDigest`. This keeps
  digest authority deterministic and testable.
- The report uses portable basename refs for input/output paths so local
  worktree paths do not leak into downstream review artifacts.
- Existing `validate-specgraph` command output remains stable; the new CLI flags
  are optional and existing callers keep working.

### Tests

- `swift test` — PASS, 93 tests, 0 failures.
- `bash tools/swift-quality.sh` — PASS, SwiftFormat clean, SwiftLint strict
  clean, 93 tests, 0 failures.
- `bash tools/typescript-smoke.sh` — PASS.
- `git diff --check` — PASS.
- Manual `ontologyc validate-specgraph` smoke — PASS and generated
  `/tmp/ont-036-adapter-report-smoke/ontologyc-adapter-report.yaml`.

### Next Steps

No actionable Ontology follow-up is required from this review.

Potential cross-repo next slice remains outside ONT-036 scope: have SpecGraph
consume a freshly generated Ontology adapter report instead of only the checked-in
fixture, then expose the resulting review-only artifact to SpecSpace.

FOLLOW-UP skipped: no actionable review findings.
