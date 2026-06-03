# Next Tasks: Agent Model Selection Follow-Up

**Status:** ONT-029 archived with PASS

## Description

ONT-029 documents that ontology-authoring model choice should be role-specific and
validated by artifacts. Strongest/most expensive models are useful for high-risk framing,
critique, and governance-facing review, but routine structured extraction and YAML assembly
can use cheaper/faster models when validation remains stable.

## Current State

- README points authors to role-specific model selection.
- Authoring guide includes `Model Selection Guidance`.
- Induction protocol includes `Model Selection Boundary`.
- Rubric includes `Model Efficiency Boundary`.

## Potential Next Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| TBD | Model Selection Benchmark Harness | Quality | P3 | Optional follow-up if model routing needs measured regression evidence |

## Sequencing Notes

- Keep any future benchmark vendor/model-name neutral in repository docs.
- Compare outputs against golden intent expectations and rubric outcomes, not subjective
  preference alone.
- Treat benchmark evidence as routing guidance, not as trusted ontology approval.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-029 | Agent model selection guidance | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-029 | 2026-06-04 | PASS | `SPECS/ARCHIVE/ONT-029_Agent_Model_Selection_Guidance/` |
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
