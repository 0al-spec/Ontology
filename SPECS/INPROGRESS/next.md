# Current Task: ONT-043 — Instance Graph Contract And Validation

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-042, merged PR #66 (`a2e1af3`)
**Status:** Selected; planning bounded eventcore-v1 validation

## Description

Choose the concrete InstanceGraph wire contract and implement the bounded
identity/reference/observation-availability checks from the
[workplan](../Workplan.md#ont-043-instance-graph-contract-and-validation).
The [event core package](../ontology/packages/events-core/README.md) provides
vocabulary and structural SDK artifacts; its semantic policies remain manual.
PR #66 review fixes make registry membership, direct snapshots, record-owned
Delta and causal endpoint Interpretations explicit in ONT-043 acceptance.
ONT-046 tracks Linux compiler portability independently.

## Next Step

PLAN/EXECUTE ONT-043 using the existing compiler and rule layer. Keep structural
graph validation distinct from source truth, causal proof and responsibility.
ONT-044 remains a separate responsibility-profile package.

## Recently Archived

- ONT-042: draft event package, local compiler/quality evidence, 2026-10-27.
- ONT-041: proposal, merged PR #65 with unknown-observation clarification.
