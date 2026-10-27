# ONT-044: Draft Responsibility Profile Package

**Date:** 2026-10-27
**Status:** Complete — draft package/mapping delivered; hosted CI and independent review pending
**Priority:** P1
**Reasoning Effort:** high
**Branch:** `codex/ont-044-responsibility-core`
**Dependencies:** ONT-042 (PR #66), ONT-043 merged in PR #67 (`0b69253`)

## Objective

Author a reusable draft responsibility vocabulary and an explicit bounded mapping
to NormLab's existing action/omission profile. Separate actor, duty bearer and
human anchor. Package compilation is not responsibility inference or Lean proof.

## Scope and decisions

- Draft `org.0al.responsibility.core@0.1.0`, namespace respcore; import the unchanged
  event-core 0.1.0 vocabulary. Use the existing compiler and scalar/object schema
  generation; do not expand the eventcore-v1 runtime profile or its exact IR pin.
- ResponsibleRelation has separate duty bearer/counterpart, DutySpecification,
  origin/continuation/termination conditions and response-rule references.
- Duty requirements are typed action/state alternatives. Conditions are opaque
  semantic identifiers, not executable expressions. Deadlines carry clock/time;
  elapsed/capability/performance/exception/attribution require scoped grounds.
- Ground assessments derive scope from one owning assessment. Positive/negative
  supports are independent links; no cached truth-state field duplicates them.
  Cited support and explicit operator support are separate alternatives.
- Assessment review is workflow only. Profile consequence candidates and response
  candidates remain proposals; breachRecorded is not a fine or imposed sanction.
- Pin mapping sources to actual NormLab main
  `e8041c937f28d3644d4df3680db5d81f0cff8ace`. Specify exact condition/predicate/
  polarity rows, full scope order, registry-bound API and IsHuman construction.
  The existing Lean scope has no separate dutyBearer or duty/rule identifier;
  document these gaps rather than silently treating fields as proved.
- Certificates reference external artifacts; they do not execute them. Distinguish
  deletion of source supports from deletion of mapped literals/rules, and generic
  Tree preservation from Profile.check's opposition-sensitive admission.

## Deliverables

1. Staged authoring intent/classification/model/critique and draft YAML; assembled
   package remains draft and byte-identical to the authoring copy.
2. Ten deterministically generated IR/TypeScript artifacts and object-schema smoke
   for valid shapes, missing required fields and wrong primitive types.
3. Pinned mapping contract/document and conceptual examples covering six omission
   grounds, missing/conflicting performance, uncited operator claims, role/scope
   mismatch, persistent relations and used/unused support deletion.
4. CI validates authoring/package/generated baseline. External references are
   checked against the actual event-core IR; no imported vocabulary is invented.
5. Actual validation report, full FLOW archive/self-review and published PR.

## Verification

Apply flow-run and the repository's FLOW checkpoints. Before artifacts, verify
TB5 and route compiler/Swift/Node temporary/cache/profile outputs there. Run actual
validate-draft/check, two independent compile outputs with byte comparison,
TypeScript typecheck/runtime smoke, required quality gate and docs/whitespace
checks. Keep compiler/event-core source artifacts unchanged.

Examples describe the existing pinned Lean semantics; no NormLab test/proof run
or cross-repo implementation is authorized by this package task. Source reading
and exact pinned references establish the mapping, not an executed adapter.
No paid inference, law corpus, legal review workflow, deployment or new proof
backend. ONT-045 owns the offline consumer pilot, ONT-047 snapshot provenance.

---
**Archived:** 2026-10-27
**Verdict:** PASS — draft vocabulary/source mapping; hosted CI and independent review pending
