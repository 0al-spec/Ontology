# ONT-086 validation

**Verdict:** PASS locally; hosted CI and independent review remain separate.

- `tools/swift-quality.sh` with `RUN_COVERAGE=1` passed: SwiftFormat and
  SwiftLint reported no violations; 277 Swift tests passed. The aggregate
  report measured 89.73% line coverage, including vendor sources. SwiftPM
  scratch and cache were on the external build volume.
- `tools/typescript-smoke.sh <new ontologyc>` passed with TypeScript 6.0.3,
  tsx 4.22.4 and Zod 4.4.3. The new consumer checks local and imported
  ancestry, a type named `T`, exact discriminators, inherited required and
  optional fields, inherited `Ref` identity, and an action relationship
  with an inherited protocol and optional field. Negative controls reject
  missing fields, the wrong type or reference, and invalid JSON records.
- `tools/generate_foundation_models.py --check` and four catalog tests passed;
  the versioned foundation model sources and published catalogs are unchanged.
- Focused compiler tests cover multiple inheritance levels, distinct alias
  scopes across transitive imports, wrong/missing source versions, cycles and
  incompatible field overrides. The normalized source IR remains unchanged.
- Named `OntologyRules` specifications cover cycle identity and inherited-field
  compatibility. A cyclic package currently still passes `ontologyc check`
  but fails `compile` with `class.inheritance.cycle`; see the review follow-up.

An unavailable non-foundation ancestor is a visible warning and leaves the
emitted instance projection incomplete. Imported protocol obligations remain
unverified and are reported. Foundation declaration metadata is not added as
instance fields. Generic `Parent<string>` is a structural supertype and does
not establish that an arbitrary discriminator is a known descendant.

The worktree is retained through review at
`.worktrees/ont-sg-ss/Ontology-imported-typed-references`; build artifacts are
external. No release, consumer pin update or deployment was performed.
