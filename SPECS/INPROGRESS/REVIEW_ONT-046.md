# REVIEW REPORT — ONT-046 Linux Compiler Portability

**Date:** 2026-10-28
**Scope:** origin/main..d210a5c
**Reviewer:** Codex /root self-review; hosted/independent review separate

## Verdict

Approve for PR review. No remaining actionable source finding in this review.
FOLLOW-UP is skipped: consumer adoption and a later release remain explicit
delivery steps, not silently added implementation tasks or completed outcomes.

## Correctness and design

- Linux receives the exact compatible Crypto product only where imported. Native
  CryptoKit remains in the macOS branch. The floor version actually builds/tests;
  dependency resolution did not change pre-existing pins. The Apache-2.0
  dependency/source-build boundary is documented.
- FoundationNetworking is conditional and limited to the registry client/tests.
  FileHandle writes retain existing diagnostic strings and exit codes without
  mutable libc globals, unsafe isolation flags or an async CLI conversion.
- All legacy CLI wrappers now use the explicitly configured binary rather than
  an unrelated default artifact. Missing explicit paths are descriptive failures,
  not permission to substitute a stale binary or run nested SwiftPM implicitly.
- The shared gate compares complete generated outputs for all six package
  baselines and preserves all former fixture/provenance/responsibility/motivation
  gates. The missing-tool check exits 127, and all scripts retain fail-fast behavior.
- The new Linux matrix runs stock source on x86_64, including the same TypeScript
  and generated/structural contracts. Local ARM64 container evidence remains
  distinct from that hosted CI; no unexecuted platform claim is presented as a run.

## Scope, concurrency and security

No ontology rule algorithm, frozen package/digest, instance profile or saved report
semantics changed. No runtime plugin execution, canonical mutation, secret or
deployment capability was added. Registry concurrency/transport behavior is
unchanged; this port does not claim new authentication or source-truth guarantees.

The new dependency is pinned and license-attributed. Linux runtime libraries are
required when executing the built CLI; the README does not promise a standalone
binary. SpecGraph unavailable/not-run handling is a consumer boundary, not an
implemented change in this repository. The 0.1.0 tag remains immutable.

## Verification

- Final 159 existing tests pass on native macOS Apple Swift 6.4, Linux Swift 6.0.3
  and Linux Swift 6.3.3. Native format/lint/import and coverage gate passes;
  configured TOTAL line coverage 89.87%, region 79.32%.
- All six generated baselines, existing structural/profile controls and 18
  provenance cases pass against all three compiler binaries. Linux CLI execution
  uses matching containers; the local Bash/Node driver remains on the Mac host.
- TypeScript typecheck/runtime smoke pass. Missing compiler is checked both in
  the shared gate and the real test harness, preserving explicit failure.
- Initial nested-build test failures and the descriptive-error correction are
  retained in the validation report. No failure was waived or marked valid.

## Remaining delivery boundary

Publish the PR and wait for its exact-head Linux/macOS/DocC checks. Independent
review, user-authorized merge/release and actual SpecGraph consumer adoption are
separate from this self-review. No cross-repo edits or new release are claimed.
