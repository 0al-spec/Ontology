# REVIEW REPORT — ONT-060 Saved Diagram Profiles

**Scope** `feature/ONT-058-relations-view..HEAD`, self-review on 2026-10-31.

## Verdict

Approve for external review with local gates passing. FOLLOW-UP is skipped with
no unresolved implementation finding. Hosted CI remains pending.

## Correctness and architecture

- Profile loading is a CLI data boundary. It converts a strict versioned JSON
  document into the existing argument/diagram model. View/direction parsing is
  shared; semantic selection acceptance delegates to DiagramSelectionSpec after
  the base review fix. No alternate graph projection or import resolver exists.
- Unknown fields, explicit nulls, wrong JSON shapes and unsupported versions fail
  before output creation. Optional defaults are applied only to absent fields.
  The editor schema hint is inert and never fetched by the CLI.
- Source paths bind to the actual profile file directory. A symlink points to
  that file's directory. Runtime output stays bound to the invocation directory.
  Existing explicit local package checks handle import identity and selected refs.
- Positional/selection flag conflicts are rejected. A valid direction can be
  overridden by CLI; invalid profile direction is rejected before overrides.
  Format/output/renderer remain explicitly selected runtime options.
- The profile joins the protected source set, with regression coverage that an
  output named ontology.dot cannot replace the profile itself.

## Evidence

Seven new profile CLI tests exercise the real executable, actual SVG/PNG, an
unrelated working directory, symlink resolution, defaults, option conflicts,
version/shape failures and profile preservation. DOT matches the existing
motivation-relations fixture exactly. The final 205-test quality gate, TypeScript,
eight-package generated-output contracts and both DocC catalogs passed. The
Draft 2020-12 schema and example passed structural validation with negative controls.

## Integration and handoff

The P1 base finding was fixed and pushed in PR #82 as 1608c362, its source thread
resolved, and this branch rebased onto it before final verification. This layer
will target the current PR #82 branch. Retain the existing visualization worktree
through review of #81, #82 and this profile layer, then retire it after merge.
The profile stores one explicit selection. Automatic profile discovery, profile
inheritance and exporting a new profile from CLI arguments can be later slices
if concrete usage needs them.
