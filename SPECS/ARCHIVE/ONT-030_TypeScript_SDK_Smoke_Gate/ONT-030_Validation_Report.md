# ONT-030 Validation Report

**Task:** ONT-030 TypeScript SDK Smoke Gate  
**Date:** 2026-06-11  
**Verdict:** PASS

## Summary

ONT-030 adds a TypeScript smoke package for the committed examcalc generated SDK, a local
helper script, CI workflow wiring, and documentation. The smoke gate compiles generated
TypeScript with `tsc --noEmit` and runs the Zod fixture through `tsx`.

## Changed Areas

| Area | Result |
|------|--------|
| TypeScript smoke package | PASS |
| TypeScript compiler config | PASS |
| Local helper script | PASS |
| Swift Quality workflow wiring | PASS |
| Node24 action guard update | PASS |
| README / CI cache policy docs | PASS |

## Validation Commands

```bash
bash tools/typescript-smoke.sh
```

Result: PASS. `npm ci` installed the smoke dependencies, `tsc --noEmit` completed without
errors, and `tsx examcalc-schemas.ts` executed the Zod parse / JSON Schema smoke fixture.

```bash
bash tools/check-github-actions-node24.sh
```

Result: PASS. The workflow guard accepts the maintained `actions/setup-node@v6` reference.

```bash
git diff --check
```

Result: PASS. No whitespace or patch-format issues.

```bash
bash tools/swift-quality.sh
```

Result: PASS. SwiftFormat reported 0 files requiring formatting, SwiftLint reported 0
violations, the Swift build completed, and 79 Swift tests passed.

## Implementation Notes

- The first local `tsc --noEmit` run failed because generated TypeScript files live outside
  the fixture directory and could not resolve `zod` from a sibling `typescript-smoke/node_modules`.
- The fix is to keep the lockfile-backed smoke package at `SPECS/ontology`, so generated
  SDK imports resolve `zod` through normal Node ancestor lookup.
- The smoke package uses a lockfile-backed `npm ci` flow and does not require global Node
  packages.

## Residual Risk

- The gate is a smoke test, not full npm package publishing validation.
- Runtime smoke currently exercises generated schemas only; broader relation/registry
  runtime checks should be added when those generated artifacts become consumer-facing.
