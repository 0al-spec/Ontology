# REVIEW ONT-029: Agent Model Selection Guidance

**Date:** 2026-06-04
**Verdict:** PASS

## Findings

No blocking issues found.

## Review Notes

- Guidance is vendor/model-name neutral and does not encode the user's informal benchmark
  as a universal claim.
- Trust boundary remains correct: model choice is operational; prompt contracts, rubric
  review, golden expectations, compiler validation, and governance approval remain the
  evidence path.
- The docs explicitly prevent using cheaper models as a reason to approve weak ontology
  output.

## Verification

```bash
rg -n "strongest available model|cheapest|faster|governance|provider|gpt-|GPT-|OpenAI|universal|benchmark|trusted ontology evidence|do not bypass" \
  README.md \
  SPECS/ontology/authoring-guide.md \
  SPECS/ontology/induction-protocol.md \
  SPECS/ontology/ontology-quality-rubric.md \
  SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance
```

Result: PASS. Wording is neutral and keeps governance/validation boundaries visible.

```bash
bash tools/swift-quality.sh
```

Result: PASS. 79 tests passed.

## Follow-Up

No immediate follow-up task required. A future `Model Selection Benchmark Harness` can be
added if model routing needs measured regression evidence against golden intent
expectations.
