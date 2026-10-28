# REVIEW REPORT — ONT-049 Generic Agency Core

Scope: origin/main through the ONT-049 implementation/archive checkpoints.
Review includes parent integration review and an independent read-only code pass.

## Summary verdict

- [x] Approve within local package/reference-envelope scope
- [ ] Treat as independently verified psychological or normative model

## Correctness and architecture

The additive package separates unasserted content, actor-relative scope and five
independent kinds of hypothesis. Awareness of a motivation preserves exact view,
optional actor role and action/omission kind. Goal, intention, anticipation,
attitude, support-presence and review remain independent. Unknown actor/time and
mental properties do not turn into default negative or psychological claims.

The pure TypeScript reference consumer is explicitly narrower than universal
InstanceGraph admission. Its index is caller-provided, bounded and checked for
internal references; authentication, graph validity, source relevance, mental
truth and chronology are not inferred. This boundary is reflected consistently
in API docs, profile JSON, README, examples and all-false authority fields.

## Findings and corrections

An independent pass found one P2 before EXECUTE completion: the motivation index
omitted contributionKind. This allowed action/omission substitution while view
and actor stayed equal. The parent added the required enum and scope comparison,
updated package policy/pins and added the isolated negative control. The reviewer
confirmed the exact correction by reading it. Parent-run gates pass afterward.
No unresolved blockers or actionable findings remain in the selected scope.

## Maintainability, safety and resources

Ten classes/24 relations avoid duplicating Motive or importing domain categories.
Old package/profile/report bytes are untouched. Dependency pins and actual IR
navigation are checked, rather than assuming namespace acceptance is resolution.
Strict consumer objects reject physical/authority fields. IDs, arrays, text and
diagnostics are bounded; the entry point accepts already parsed objects, not an
authenticated transport or a guarantee on parser/transport resource limits.
No I/O or credentials are used by the consumer. No event is physically enriched.

## Verification

See the archived validation report: 159 Swift tests, line coverage 89.87%, staged
package checks, deterministic generation/pins, portable contracts and TypeScript
typecheck/smoke. The explicit agency consumer passed 37 positive and 79 negative
controls. Swift line coverage does not measure the TypeScript consumer; no such
coverage percentage is claimed. Hosted Linux/macOS CI remains an exact-head PR
check, separate from this local review.

## Next steps

FOLLOW-UP skipped: the single actionable issue was corrected and verified inside
this task. Future graph admission and separately pinned NormLab domain mappings
remain explicit extensions, not missing acceptance silently labeled complete.
Publish the PR using the repository template; report current hosted checks and
external review without treating this local verdict as a GitHub approval.
