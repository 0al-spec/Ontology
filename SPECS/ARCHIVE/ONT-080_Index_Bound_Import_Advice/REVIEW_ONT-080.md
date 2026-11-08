# REVIEW REPORT — ONT-080 index-bound import advice

**Scope:** ONT-080 changes above Ontology 0.9.0.

## Verdict

- [x] Approve locally, subject to hosted CI and independent review.

## Findings

No unresolved local correctness or safety findings. The advisory loads only
explicit index paths, requires a single regular stage-0 blob and never reads
an import from the working tree. Missing or unreadable imports say that the
package could not be checked. The existing advisory remains non-blocking.

A caller must still select and stage the intended dependencies. A configured
older binary continues to have its old behavior until the hook is updated.
`diff` and registry publication support are separately tracked by ONT-081.
No additional FLOW follow-up is needed for this slice.

## Tests

[Validation](ONT-080_Validation_Report.md) covers both git and RTK hooks,
partially staged worktrees, alternate and unmerged indices, missing and invalid
sources, and the complete local Swift gate. Linux CI and coverage are separate.
