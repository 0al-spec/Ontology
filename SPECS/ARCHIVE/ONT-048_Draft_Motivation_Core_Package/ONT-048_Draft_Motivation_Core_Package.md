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

## PR review correction plan — 2026-10-28

The review of PR #70 at 6c02230 found that a contribution record's own Delta
does not exhaust its hypothesized downstream consequences. In the canonical
car fixture, the omission record preserves its own state while the movement
record changes location. The earlier consequence wording above is superseded
by this correction; no frozen event/profile semantics will change.

1. Distinguish local record change from hypothesized downstream effect change.
   Follow an explicit CausalHypothesis whose hypothesisCauseView is the selected
   motivation view, then hypothesisEffectView and its own record/Delta. Retain
   hypothesis identity/state; do not promote the causal attribution to fact.
2. For this pilot use a separate omission record plus causal hypothesis. Do not
   substitute an owner reading of the movement record as the same motive scope.
   An empty local Delta says nothing about downstream effects or other projections.
3. Define actor-role binding by an outgoing interpretationBindsRole or
   candidateBindsRole edge from the selected view, with roleName actor. Shared
   RoleBinding nodes are allowed; exclusive ownership is not required.
4. Regenerate the staged package/IR and align the inert contract and examples.
   Add fixture-backed smoke controls using the real frozen graph validator:
   empty omission Delta passes, movement Delta stays nonempty, moving that Delta
   to omission fails, and shared role references remain structurally admissible.
   These controls test event structure, not a new motivation admission engine.

Re-run package generation/pin checks and TypeScript smoke. Preserve the existing
159-test quality result unless compiler changes or a fresh failure require a
broader local rerun; hosted CI will validate the correction head separately.
