# ONT-030: TypeScript SDK Smoke Gate

**Status:** PRD Ready  
**Priority:** P0  
**Phase:** SpecGraph Value Loop Closure  
**Reasoning Effort:** medium  
**Dependencies:** ONT-017, ONT-028

## TL;DR

Generated TypeScript artifacts are currently protected by Swift regression tests and
byte-stable baselines, but they are not compiled by TypeScript. ONT-030 adds a minimal
Node/TypeScript smoke gate for the committed examcalc generated SDK before ONT-032 makes
the emitter materially more complex.

## Problem

`SPECS/ontology/typescript-smoke/examcalc-schemas.ts` demonstrates the intended Zod usage,
but nothing runs it. CI only executes Swift quality and DocC workflows. A future emitter
change could generate syntactically invalid TypeScript or incompatible Zod calls while all
Swift tests still pass.

This is a trust-boundary issue for the generated SDK: `ontologyc` claims TypeScript output,
so the repository should validate that output with the target compiler.

## Goal

Add a local and CI TypeScript smoke gate that:

1. Type-checks the committed generated examcalc SDK and smoke fixture with `tsc --noEmit`.
2. Exercises the generated Zod schemas through the existing smoke fixture.
3. Keeps the gate small, deterministic, and separate from Swift package dependencies.

## Scope

### In Scope

- Add a minimal `package.json` and `package-lock.json` under `SPECS/ontology`, plus
  `tsconfig.json` under `SPECS/ontology/typescript-smoke/`.
- Keep the smoke fixture focused on generated schema import, `ExamSchema.parse`, and
  `toJsonSchemaFor(ExamSchema)`.
- Add a repo-level helper script for running the TypeScript smoke gate locally.
- Wire the smoke gate into GitHub Actions.
- Document the local command in README or the ontology compiler docs.

### Out of Scope

- Adding class fields or changing generated TypeScript semantics.
- Publishing npm packages.
- Introducing a monorepo-level JavaScript build.
- Replacing Swift regression baselines.
- Validating every possible consumer bundler/module mode.

## Deliverables

| ID | Deliverable | Path | Acceptance Criteria |
|----|-------------|------|---------------------|
| D1 | TypeScript smoke package | `SPECS/ontology/package.json` | Defines deterministic `typecheck` and smoke commands |
| D2 | TypeScript compiler config | `SPECS/ontology/typescript-smoke/tsconfig.json` | Includes smoke fixture and generated examcalc SDK |
| D3 | Dependency lockfile | `SPECS/ontology/package-lock.json` | Pins `typescript` and `zod` dependency resolution |
| D4 | Local helper | `tools/typescript-smoke.sh` | Runs install/check steps from repo root |
| D5 | CI wiring | `.github/workflows/swift-quality.yml` or dedicated workflow | Runs the TypeScript smoke gate on PRs and main pushes |
| D6 | Documentation | `README.md` or `SPECS/ontology/ontologyc.md` | Documents the local command |

## Functional Requirements

| ID | Requirement | Verification |
|----|-------------|--------------|
| FR-001 | `npm run typecheck` must run `tsc --noEmit` against the smoke fixture and generated examcalc SDK. | Local command and CI |
| FR-002 | The smoke fixture must parse at least one generated class schema. | `npm run smoke` or equivalent |
| FR-003 | The smoke fixture must call `toJsonSchemaFor`. | `npm run smoke` or equivalent |
| FR-004 | CI must fail if generated TypeScript no longer type-checks. | PR workflow |
| FR-005 | Swift quality behavior must remain unchanged except for adding the TypeScript smoke gate. | `bash tools/swift-quality.sh` |
| FR-006 | The gate must not require a global Node package install. | `npm ci` under `SPECS/ontology` |

## Implementation Plan

1. Add `package.json` under `SPECS/ontology` and `tsconfig.json` under
   `SPECS/ontology/typescript-smoke/`.
2. Generate and commit `package-lock.json`.
3. Add `tools/typescript-smoke.sh` that runs `npm ci`, `npm run typecheck`, and the runtime
   smoke command from `SPECS/ontology`.
4. Add a GitHub Actions step after Swift quality checks to run the helper.
5. Document the local command.
6. Run local validation:
   - `bash tools/typescript-smoke.sh`
   - `bash tools/swift-quality.sh`
   - `git diff --check`

## Risks

| Risk | Mitigation |
|------|------------|
| Node dependency setup slows CI | Keep package tiny and lockfile-scoped; add caching later only if timings require it |
| Module-resolution mismatch with future npm packaging | Treat this as a smoke gate, not a full package-publish validation |
| Zod API mismatch | Pin `zod` through `package-lock.json` and keep the generated header on `zod@^4` |

## Acceptance Checklist

- [ ] TypeScript smoke package exists and is lockfile-backed.
- [ ] `tsc --noEmit` compiles the generated examcalc SDK and smoke fixture.
- [ ] Runtime smoke executes `ExamSchema.parse` and `toJsonSchemaFor`.
- [ ] CI runs the smoke gate on PRs and main pushes.
- [ ] Documentation includes the local command.
- [ ] Swift quality gate remains green.
