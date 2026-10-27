# Next Candidate: ONT-045 — NormLab Offline Event Graph Pilot

**Priority:** P1
**Phase:** Event and Responsibility Core
**Dependencies:** ONT-043 merged in PR #67; ONT-044 draft package PR review/CI
**Status:** Not selected; agree bounded export contract and consumer ledger first

## Description

Agree a read-only export of one saved parking episode, preserving the original
source/revision/speaker, selected findings, uncertainty and saved norm receipt.
Follow the [workplan](../Workplan.md#ont-045-normlab-offline-event-graph-pilot).

## Next Step

Review the [ONT-044 package and mapping evidence](../ARCHIVE/ONT-044_Draft_Responsibility_Profile_Package/ONT-044_Validation_Report.md)
on its published head before merge. Then inspect existing NormLab Issues,
including deferred/closed ones, and create/link its canonical consumer Issue
before implementation. This Ontology task did not start that cross-repo work.

The eventcore-v1 validator admits only its pinned event vocabulary; responsibility
objects need an explicitly agreed consumer contract and cannot silently become a
new supported graph profile. Separate the operator review event from a physical
fabula candidate. Retain missing physical states as source-only; test the exporter
itself against fabricated empty snapshots. ONT-047 owns provenance, ONT-046 Linux.
No paid inference, historical receipt rewrite or deployment is required.

## Recently Archived

- ONT-044: draft responsibility vocabulary and pinned source mapping, 2026-10-27.
- ONT-043: bounded structural validation, merged PR #67, 2026-10-27.
- ONT-042: draft event package, merged PR #66, 2026-10-27.
