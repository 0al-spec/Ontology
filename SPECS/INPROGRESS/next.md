# Current Task: ONT-044 — Draft Responsibility Profile Package

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-042, merged PR #66 (`a2e1af3`)
**Status:** Selected; ONT-043 merged in PR #67 (`0b69253`)

## Description

Author the generic duty/condition/omission/response vocabulary and its bounded
mapping to the existing NormLab attribution profiles, following the
[workplan](../Workplan.md#ont-044-draft-responsibility-profile-package).
Actor, duty bearer and human anchor remain distinct. Parking predicates/sanctions
and automatic legal responsibility do not belong to the generic event profile.

## Next Step

PLAN/EXECUTE ONT-044 from the merged event vocabulary and pinned NormLab main
`e8041c937f28d3644d4df3680db5d81f0cff8ace`. Only read NormLab sources; its
runtime, sources and ledger are not changed by this Ontology package task.
The [InstanceGraph validator](../ontology/instance-graph/README.md) establishes
bounded structural consistency, not source truth or physical causation.
ONT-045 remains the separate offline NormLab pilot; ONT-046 tracks Linux support.
ONT-047 tracks snapshot provenance; the pilot must keep missing physical states
source-only and test its exporter rather than relying on structural validation.

## Recently Archived

- ONT-043: bounded structural validation, 143-test quality gate, provenance gap explicitly tracked, 2026-10-27.
- ONT-042: draft event package, merged PR #66, 2026-10-27.
- ONT-041: proposal, merged PR #65 with unknown-observation clarification.
