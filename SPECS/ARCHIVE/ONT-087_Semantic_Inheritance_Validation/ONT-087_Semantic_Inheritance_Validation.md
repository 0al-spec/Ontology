# ONT-087: Semantic inheritance validation

## Problem

The ONT-086 TypeScript projection rejects cyclic or incompatible inherited
fields, but `check` and staged advice can report the same invalid source as
valid. Diagnostics in a multi-package request must identify a real source and
location, including when the defect is reached through an imported ancestor.

## Deliverables and acceptance

- Run the same available-source inheritance rules in `check`, snapshot checking,
  and staged advice without writing output or downloading dependencies.
- Detect cycles, incompatible inherited fields and ambiguous reference targets;
  retain package-local import aliases and exact identity/version resolution.
- Attribute diagnostics to a source and a valid declaration in that source.
- Cover valid local and imported hierarchies, invalid cycles and overrides,
  incomplete imports and the staged CLI; retain explicit unverified warnings.
- Keep ONT-088 imported protocol projection as a separate limitation.

## Dependency

This task builds on ONT-086 (PR #113) and is reviewed as a separate stack layer.
