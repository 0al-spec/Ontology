# REVIEW REPORT — ONT-050 Action Model Template

Scope: `a170fce..a0c70b6`, documentation/skill layer above ONT-049.
Date: 2026-10-28. Review: parent inspection plus independent skill forward exercise.

## Summary verdict

- [x] Approve for the documented template scope
- [ ] Request changes
- [ ] Block

No remaining blocking or actionable findings. The scope does not include an app,
codec, executable goal interpreter, new profile or test engine.

## Findings and corrections

- **Low, fixed:** in an independent Russian prompt, “команда” was read as a team
  and silently asserted as a collective actor instead of preserving the ambiguity
  with an application command. Parent identified this in the produced answer.
  SKILL now separates action/command names from entities and explicitly preserves
  unspecified actors or labels assumptions (`486a659`). A follow-up with an
  unambiguous application-command prompt kept actor/initiator unresolved.
- Parent/author review aligned `unknown` wording across the skill, worksheet and
  guide: insufficient inputs block satisfaction, but a known false conjunct can
  already establish `not_satisfied`. Action, relation and configuration fields
  were made explicit in the worksheet before validation/implementation commit.

## Forward exercise cases

These are bounded regression prompts, not executable test bindings:

1. An operator re-encodes an existing image, wants it 200 kB smaller, but the only
   supplied observation is final size 640 kB. The model must preserve the unknown
   baseline, label units/exact-versus-minimum assumptions, and avoid inferring the
   motive or reporting a known reduction. Independent result did so.
2. An application command “Save copy” creates a separate image <= 500 kB; the caller
   is unspecified. The output has separate identity, a final-size criterion and no
   invented caller. Source-image size is not the new copy's before-state. The
   clarified independent rerun did so, and distinguished command requirement from
   an attributed desire of the unknown caller.

The evaluator reviewed the skill, guide, worksheet, example and Gherkin source.
It reported no substantive document contradictions in the final inspected state.
It did not run parsers/tests; those checks belong to the parent validation report.

## Architecture and evidence

The criterion may inspect post-state, difference, transition or interval history.
An actor/evaluator applies it. The same observations can support different role
interpretations; additional delegation events are explicit decomposition. Motive
is optional and actor/view scoped; the template imposes no consciousness or goal.

All deliverables are inert documentation or skill metadata. The local personal
copy is byte-identical to the six repository skill files. Existing package/profile
bytes and reports remain unchanged. Gherkin syntax/12 expanded cases and eight
arithmetic rows passed; no acceptance bindings, PBT runs or codec correctness are
claimed. Full unchanged Swift tests are deferred to hosted CI for this doc-only PR.

## Next steps

FOLLOW-UP skipped: no unresolved actionable findings. Archive this review, publish
the dependent PR, and report current-head CI separately. Applying this template to
an actual consumer and implementing its evaluator/tests requires that consumer's
own selected task; ONT-045 remains the roadmap's next candidate.
