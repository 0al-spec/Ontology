# ONT-051 — Intent Preservation Review Pilot

Date: 2026-10-28. Priority: P1. Review subject: ONT-051.
Base: ONT-050 `7ec4b0c`, separate dependent PR.

## User outcome

Review a compact difference at each boundary from structured intent through
application ontology and Hypercode to implementation evidence. A person can spot
and correct a changed interpretation without reading the entire code or test suite.
The first experiment is in-place raster image encoding. It tests preservation of
the chosen meaning, not the completeness of a universal software ontology.

## Deliverables and boundaries

1. A small typed, editable intent with stable obligation IDs, source/assumption
   labels and unknown/unapproved human-alignment status. Companion application
   model binds values to a real draft ontology package/compiled IR.
2. A caller-owned Hypercode composition and explicit scalar contracts, validated
   and emitted by the real CLI. Full file hashes supplement node hashes.
3. Minimal image-domain code and real JPEG observations in disposable test data.
   Selected image, in-place identity, dimensions, numerical goal and missing-input
   behavior have separate evidence. No personal files are transformed.
4. A bounded consumer report with adjacent-layer comparisons and a fixed intent
   baseline: retained/added/removed/modified/unmapped or unknown mappings; bounded
   satisfied/violated/unknown findings; locations, hashes and method of evidence.
   Markdown and HTML summaries collapse unchanged rows and expose full details.
5. Negative controls for altered ontology/Hypercode obligations, resizing, copy
   creation, wrong input, wrong reduction basis/comparator, missing and stale evidence.
   A runtime success cannot repair a missing/contradictory declaration.
6. Readable correction workflow: edit the source artifact named by a finding and
   rerun. Reports never rewrite intent, mark a model human-approved or modify the
   existing generic package/profile/SpecGraph canonical state.

`Examples/intent-preservation` owns the executable consumer. New application
vocabulary lives under `SPECS/ontology/packages/image-encoding-pilot`. This is not
a new generic ontologyc command, universal code scanner or SpecGraph comparator.
No new Lean proof is claimed; checked formal models and runtime test evidence are
explicitly separate. The prototype tests selected observations and known controls,
not arbitrary source equivalence or all codec inputs.

## Implementation contract

Obligations cover selected Entity, action kind, in-place identity, preserved
dimensions, goal basis/comparator/byte target and unknown-input treatment. Policy
meaning is explicitly defined by the local versioned profile, not inferred from
names or prose. Model values, compiled field/ref shape, resolved Hypercode values,
code/config bindings and observations are independently inspected.

Keep full expected inputs separate from observed evidence and retain unknown
rows. Only use bounded known example code for runtime probes; no arbitrary shell
commands or automatically supplied source programs are executed from data files.

## Validation and ownership

Parent owns FLOW, consumer contract/adapters/reporting, integration and Git/PR.
One agent authors the draft package; another implements isolated image-domain
code/tests. No agent changes branches, shared contracts, installed environments,
publication or unrelated files. Independent review focuses on false-success paths.

Run package validation/deterministic generation, real Hypercode validate+emit,
Python example/unit/property/mutation tests, existing Swift/portable/TypeScript
gates as applicable and dedicated CI for the consumer. Local artifacts/dependencies
use verified TB5 roots. Record exact tool/dependency versions and hashes; missing
tool execution is unavailable/not-run, never successful validation.

No deployment, release, merge, paid model call or unrelated application creation.
Complete FLOW checkpoints and publish a reviewable dependent PR.
