# Next Task: ONT-029 Agent Model Selection Guidance

**Status:** INPROGRESS

## Description

Add documentation guidance for ontology-authoring agents that model choice should be
role-specific and validated by artifacts. Strongest/most expensive models are useful for
high-risk framing, critique, and governance-facing review, but routine structured
extraction and YAML assembly can use cheaper/faster models when validation remains stable.

## Current State

- README links to authoring guide, induction protocol, prompt contracts, and rubric.
- Authoring guide defines agent roles but does not yet explain model selection.
- Induction protocol defines validation layers but does not yet state the model-selection
  trust boundary.
- Rubric evaluates semantic output quality but does not yet separate that from model cost
  and latency.

## Selected Task

| Task ID | Title | Phase | Priority | Source |
|---------|-------|-------|----------|--------|
| ONT-029 | Agent Model Selection Guidance | Documentation | P2 | Prompt benchmark observation |

## Sequencing Notes

- Keep guidance vendor/model-name neutral.
- Do not claim a universal benchmark result.
- Make validation artifacts, not model ranking, the trust boundary.
- No compiler behavior changes.

## Recently Implemented

| Task ID | Implemented | Folder |
|---------|-------------|--------|
| ONT-028 | Node24 cache action migration | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | CI SwiftPM and quality tool cache optimization | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | Registry publish governance gate | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | Governance decision CLI validation | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | Governance decision YAML schema | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |

## Recently Archived

| Task ID | Archived | Verdict | Folder |
|---------|----------|---------|--------|
| ONT-028 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-028_Node24_Cache_Action_Migration/` |
| ONT-027 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-027_CI_SwiftPM_And_Quality_Tool_Cache_Optimization/` |
| ONT-026 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-026_Registry_Publish_Governance_Gate/` |
| ONT-025 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-025_Governance_Decision_CLI_Validation/` |
| ONT-024 | 2026-06-03 | PASS | `SPECS/ARCHIVE/ONT-024_Governance_Decision_YAML_Schema/` |
