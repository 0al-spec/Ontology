# ONT-052 — Intent Preservation Contract

## Problem and intent

The accepted image pilot detects semantic drift, including a successful size goal reached by unwanted resizing. Its receipt is image-specific. A reusable contract must preserve independently authored intent, account for every obligation, describe bounded evidence and show a compact correction-oriented diff.

## Scope

Deliver contract version 0.1 as a specification, JSON Schema and bounded reference validator; publish a separate PR above ONT-051 (#75). Keep compiler IR, existing package pins, Hypercode language and prior receipts unchanged. Add an explicit new common receipt from fresh image runs. Demonstrate the same format with a small executable edit/cancel scenario; no application UI or generic code understanding is claimed.

## Deliverables

- Domain-neutral intent/stage/mapping/evidence/decision receipt with exact artifact bindings and semantic checks beyond JSON shape.
- Normative workflow: baseline, translate with mapping, compare adjacent/original, observe independently, review/correct/version.
- Compact Markdown/HTML views with full coverage accessible, changed/unknown requirements visible and correction source named.
- Image adapter preserving existing report and bounded checks; second profile for cancellation restoring document contents and identity, without synthesizing observations.
- Regression controls for lost requirements, downstream collusion, missing data/evidence, stale hashes, unsupported profiles and acceptance that does not override a failed check.

## Acceptance

1. Both profiles emit schema-valid common receipts and independently executed bounded evidence. The core has no JPEG, image size or cancellation-specific fields.
2. Required obligation coverage is checked across the declared ordered stages. Unknown or unsupported facts cannot become success; matching downstream mistakes retain the original mismatch.
3. Changes, verification verdict and human decision are separate. Human acceptance applies to exact versions, never factual truth or generic correctness.
4. Each positive claim has its checker/profile version, evidence scope and binding. Stale/missing artifacts produce unknown without rewriting prior reports.
5. Negative controls are executed, not only described; invalid inputs are rejected and unsupported semantic content is explicit.
6. Reports remain usable as compact mobile-readable content with details available. No universal equivalence, source truth, new Lean proof or automatic human approval.

## Validation

Run existing image tests and new contract/cancel tests with dependencies and scratch output on the verified TB5 path. Run fresh image receipt generation with real ontologyc and pinned Hypercode, cancellation success and deliberate violation, schema/reference/freshness controls, relevant documentation checks and independent code review. Existing Swift sources/packages are unchanged; hosted checks cover the repository on the exact new head. Record exact local commands/results and remaining boundaries.

## Design constraints

A translation can refine or split obligations without one class per ontology node. Domain profiles own semantics; the shared validator checks coverage, reference integrity, evidence linkage and declared outcomes. Independent observations remain independent from the implementation declaration. Existing image profile v1 receipts are retained and are not upgraded in place. No merge or release is part of this task.
