# ONT-070 — Viewer README showcase

## Intent
Make the delivered interactive Viewer visible when a reader opens the repository.
Place its screenshot and a short launch entry before “The problem: a correct
implementation of the wrong idea”, keeping the existing conceptual narrative.

## Acceptance and validation
Capture the real running Viewer with a legible graph, inspect the image, and
store a portable PNG in the repository. Exclude local paths, tokens and personal
source material from the capture. Link the image and launch manual from README;
state viewing, filtering, inspection and optional YAML workspace capabilities
without implying visual graph editing or hosted integration. Check image format,
Markdown link targets, placement and whitespace. Document exact screenshot scope;
no broad runtime suite is needed for this documentation-only change.

## Workspace
Reuse Ontology-interactive-viewer on feature/ONT-070-viewer-readme; no new worktree.
Preserve the existing preview servers and their model sources. Retain this tree
through PR review and migrate live consumers before eventual retirement.
