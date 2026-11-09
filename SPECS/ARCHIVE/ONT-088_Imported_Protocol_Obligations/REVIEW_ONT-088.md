# REVIEW REPORT — ONT-088 imported protocol obligations

**Scope:** `origin/main` through the ONT-088 implementation and archive.

## Verdict

- [x] Approve with follow-up for the bounded SDK projection.
- [ ] Independent hosted review or release approval (not performed here).

## Finding

**Medium — protocol conformance is not source-bound across imports.**
`validateProtocolConformance` skips imported protocols, including their
`requiredRelations`. It also checks local `requiredFields` against names of
relations with the class as domain, whereas the current SDK treats those names
as required string instance fields. ONT-088 resolves protocol sources and
projects the established SDK contract; it does not establish that an imported
class or runtime instance satisfies all declaration-level obligations. A
follow-up must clarify the intended meaning and validate conformance with
source-attributed diagnostics rather than infer properties from metadata.

## Review notes

The resolving package and its aliases determine the exact package identity;
missing or duplicate source and missing symbols do not become verified
protocols. Foundation export tables provide names only for this path. No
foundation declaration properties are projected into instances. No remote
package fetching is introduced.

## Validation

The 292-test Swift quality gate and 90.33% aggregate line coverage passed.
TypeScript/Zod and portable contract smokes passed with the task compiler.
Hosted CI, independent review, release and downstream adoption are separate.
