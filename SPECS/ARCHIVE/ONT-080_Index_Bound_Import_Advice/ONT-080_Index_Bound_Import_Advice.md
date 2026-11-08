# ONT-080 — Index-bound imports for staged package advice

## Problem and outcome

A model with a valid imported `Ref` can pass `ontologyc check --import`, while
`advise-staged` reports its target unresolved because the advisory cannot read
the import. Authors should be able to check the staged model against the staged
import source without silently consulting the working tree.

## Scope

- Add repeatable `advise-staged --import <repository-root-relative-path>` inputs.
  Read each regular, resolved Git index blob with its exact path, honoring an
  alternate `GIT_INDEX_FILE`; do not fetch or infer package sources.
- Validate staged package text and the supplied staged import texts together
  with the same exact package ID/version/class rules as strict `check`.
- If an explicitly selected input cannot be read, report that advice was not
  completed. Preserve non-blocking advisory behavior and existing hook exits.
- Document configuration and the distinction between staged and worktree checks.

## Acceptance

1. A valid staged imported reference is quiet when its staged import is supplied,
   even when working-tree files contain different contents. Changing the staged
   target or the staged import is reported against the selected index.
2. Missing, conflicted, non-regular and invalid UTF-8 import blobs are reported
   as unavailable; they never cause fallback to worktree content or a clean claim.
3. A separate alternate index, names with spaces and an unrelated existing hook
   behave correctly. Existing advice and strict compiler tests remain green.
4. No automatic discovery, network access, canonical acceptance or runtime
   instance resolution is implied.

---
**Archived:** 2026-11-09
**Verdict:** PASS (local; hosted CI and review separate)
