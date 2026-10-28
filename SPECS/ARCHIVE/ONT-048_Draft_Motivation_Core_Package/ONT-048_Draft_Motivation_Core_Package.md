# ONT-048 — Draft Motivation Core Package

**Date:** 2026-10-28
**Status:** Draft implementation complete; hosted CI and independent review pending
**User concept:** a reason prompting an actor's action/omission that may lead to a consequence.
**Confirmed scope:** any Entity actor; conscious intention is not required.

## Deliverables

1. A separate org.0al.motivation.core@0.1.0 draft, namespace motivcore, importing
   events-core 0.2.0. Keep frozen event/responsibility packages and profile pins.
2. Motive content, contextual MotivationHypothesis, explicit uncited operator
   support, a review lifecycle and manual boundary policies. Target one existing
   Interpretation or InterpretationCandidate; bind its actor RoleBinding only
   when known, deriving actor Entity and episode/event scope through the view.
3. Positive/negative source/operator support as independent links, not a duplicate
   truth-state field. Unknown is distinct from absent motive, and review is not
   truth. Preserve quote speaker and operator authorship separately from actor.
4. Optional contextual reason anchors to Entity, Fact or prior interpretation;
   broadly represent instructions, physical influences and reported internal
   reasons. Anchors are declarations, not automatic proof of motivation/causation.
5. Derive an actual consequence only through a known view's recorded event and
   its optional exact Delta. Source-only hypotheses require no artificial states.
   No goal/intention, performance, omission grounds, fault or sanction is inferred.
6. Staged authoring, compiled IR/SDK, pinned inert semantic design contract,
   examples/diagram, object-shape/type/runtime smoke and CI generation/import gate.

## Acceptance and checks

- Compile/validate staged draft and assembled package; two fresh outputs match.
- New object smoke checks all required fields and discriminators, plus neutral
  method text (not executable). Consumer imported refs resolve against exact
  event IR; the pin and non-executable authority flags are checked.
- Examples cover parking action/omission, abstract/nonhuman actors, unknown actor,
  unknown/opposed support, source-only missing states and unintended consequences.
- State clearly that generic object schemas do not enforce graph role ownership,
  contribution kind enums, episode/timing coherence, source relevance or truth.
  No new instance profile, executor, Lean proof, NormLab edit/deployment or paid call.
- Full configured quality gate and existing TypeScript/fixture/generation gates
  remain green. Preserve source evidence/history and existing package bytes.

## Implementation and review

Follow FLOW checkpoints; archive PRD/validation and self-review, then publish a PR.
Independent review and hosted CI remain separate from local validation. ONT-045
stays the next pilot; motivation runtime admission will need its own explicitly
reviewed consumer contract before anyone claims these invariants are executed.

---
**Archived:** 2026-10-28
**Verdict:** PASS (local package/object/generation checks)
