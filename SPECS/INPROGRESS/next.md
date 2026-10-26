# Next Candidate: ONT-043 — Instance Graph Contract And Validation

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-042 PR review/CI
**Status:** Not selected; awaiting event-core draft review

## Description

Choose the concrete InstanceGraph wire contract and implement the bounded
identity/reference/observation-availability checks from the
[workplan](../Workplan.md#ont-043-instance-graph-contract-and-validation).
The [event core package](../ontology/packages/events-core/README.md) provides
vocabulary and structural SDK artifacts; its semantic policies remain manual.

## Next Step

Review and merge ONT-042, then SELECT/PLAN ONT-043. Do not infer a checked graph
from a successful draft package compilation. ONT-044 remains a separate profile
package that can follow the accepted event vocabulary independently.

## Recently Archived

- ONT-042: draft event package, local compiler/quality evidence, 2026-10-27.
- ONT-041: proposal, merged PR #65 with unknown-observation clarification.
