# ONT-068 — Viewer launch manual

## Intent and contract
A developer can start the viewer without the author's chat history, local
binaries, package profiles or PATH configuration. Document prerequisites,
a concrete source revision, both source-built CLIs, read-only JSON browsing,
copied-YAML workspace, full/relations choice, shutdown and repeat startup.
Keep optional development tests separate. Preserve existing demo edits.

## Acceptance
Follow the manual commands against an isolated tracked-source snapshot with
fresh npm dependencies, Swift products and explicit cache/build paths on TB5.
Verify the generated projection, both HTTP entry points and workspace content.
Check repeated preparation preserves edited demo YAML. Record exactly which
platforms/tool versions and browser evidence were used; no claim of clean OS,
empty shared download cache or unperformed Linux validation.
Deliver documentation only in a focused PR above #92.
