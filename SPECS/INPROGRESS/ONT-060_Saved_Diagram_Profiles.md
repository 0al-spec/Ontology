# ONT-060 — Saved Diagram Profiles

The operator approved saved visualization selections and requested an independent
layer over the current visualization PR. The motivation-core example currently
needs the package path, local dependency path and eight type selectors each run.

## Contract

```sh
ontologyviz --profile motivation-relations.profile.json --out diagrams
```

One versioned JSON file contains `schemaVersion: 1`, a nonempty `package` path,
optional `view`, `direction`, `imports` and `expand` fields. `view` defaults to
full, direction to LR, collections to empty. An optional `$schema` string is an
editor hint. Unknown fields, explicit nulls, wrong types and unsupported versions
fail as configuration errors with exit 2 before output creation.

The profile reuses normal CLI/diagram validation. `--profile` is exclusive with
the positional package, `--view`, `--import` and `--expand`. CLI `--direction` may
override a valid profile direction. `--format`, `--out` and `--dot` are runtime
options. Output remains explicitly required and relative to the invocation's
working directory. The profile stores no executable or output path.

Package/import paths resolve relative to the profile's actual directory, including
when the profile is opened through a symlink. Profile lookup itself is relative
to the invocation directory. Absolute local paths are supported. Loading is
local-only. Every input artifact, including the profile, is protected against
output replacement. No profile auto-discovery or inheritance is introduced.

## Deliverables

- A strict, versioned JSON profile loader and CLI integration.
- A matching JSON Schema and portable motivation-core relations profile.
- Documentation and regression coverage of cross-directory use, parity with
  explicit flags, invalid configuration, precedence/conflicts and profile safety.
- Real SVG/PNG rendering plus the repository's quality/contract/DocC checks.
- A focused PR targeting `feature/ONT-058-relations-view` after FLOW checkpoints.

## Validation

Compare DOT from the profile with the existing motivation-relations fixture and
explicit invocation. Run from another working directory and via a symlink. Check
JSON type/version/key failures, invalid view/direction/selector/import identity,
flag conflicts, output-relative behavior, profile overwrite rejection and actual
SVG/PNG artifacts. Preserve existing direct CLI behavior and compiler baselines.
