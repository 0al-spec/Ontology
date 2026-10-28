# ONT-046 — Validation Report

**Date:** 2026-10-28
**Verdict:** PASS (local portability/contracts); hosted CI and independent review pending

## Changes

- Pinned apple/swift-crypto 4.3.1 (Swift tools 6.0, Apache-2.0) supplies Crypto
  only to the Linux compiler/test targets. macOS retains CryptoKit. SwiftPM
  resolved swift-asn1 1.6.0 transitively; pre-existing dependency pins are unchanged.
  Upstream 5.0.3 requires Swift 6.2 and 4.5.2 requires 6.1; neither raises this
  package's declared 6.0 minimum. Sources were checked against upstream manifests.
- Conditional FoundationNetworking imports cover registry implementation/tests.
  A synchronous Foundation diagnostic writer replaces direct libc stderr access;
  existing messages and CLI success/failure exit codes remain covered by tests.
- Nine legacy CLI test wrappers now honor the existing configured binary path.
  An explicitly missing/non-executable configured compiler throws immediately,
  without falling back to another build or a stale default binary.
- A shared portable gate checks all six complete generated package baselines,
  staged events and the existing instance/responsibility/provenance/motivation
  gates. Both macOS and the new Linux CI jobs invoke it. Missing compiler is an
  explicit exit 127/not-run result, never a validation success.
- Linux CI targets Swift 6.0.3/Ubuntu 22.04 and Swift 6.3.3/Debian Bookworm on
  x86_64. It builds with explicit target-import checks, runs the existing tests,
  TypeScript smoke and shared contracts. No continue-on-error bypass was added.

## Executed local checks

| Environment/check | Observed result |
|---|---|
| Linux aarch64, official swift:6.0 image, Swift 6.0.3 | Build/import check PASS; final 159/159 tests PASS |
| Linux aarch64, swift:6.3.3-bookworm, Swift 6.3.3 | Build/import check PASS; final 159/159 tests PASS |
| macOS arm64, Apple Swift 6.4 | Full quality/coverage PASS; 159/159 tests, format/lint/import checks |
| Shared portable gate on all three compiler binaries | PASS; all six generated directories match tracked bytes |
| Existing provenance negatives/positives | 18/18 PASS on each compiler |
| TypeScript typecheck and runtime smoke | PASS |
| Configured missing compiler in portable gate | Exit 127, explicit validation-not-run message |
| Configured missing compiler in real CLI test harness | Expected nonzero test result and explicit unavailable-path diagnostic; no fallback build |
| OntologyRules and frozen packages/profile artifacts | No diff |

Linux Swift builds/tests actually ran in local Docker containers; each CLI contract
invocation used the matching Linux binary/runtime via a local wrapper. The Bash/
Node smoke driver ran on the Mac host. This is distinct from hosted Linux x86_64
CI, where the entire gate/Node process runs inside the Linux job container.

Configured macOS TOTAL line coverage remains 89.87%, region 79.32%, including the
configured vendor/dependency scope. These are existing regression tests, not new
ontology/motivation truth proofs. Negative fixtures print FAIL as their expected
control result while the enclosing gate succeeds.

## Corrections found by actual Linux execution

The first floor-version run built the CLI but legacy test helpers ignored
ONTOLOGYC_TEST_BINARY_PATH, tried nested builds through the host .build symlink,
and failed. Honoring the configured binary fixes that issue and prevents stale
binary coverage on custom scratch paths. An extra unavailable-binary probe exposed
Linux XCTest's unhelpful NSError rendering; a small typed descriptive test error
now preserves the path/message. All final checks above pass after that correction.

The 6.3.3 first-time Yams fetch was slow, then completed successfully; no source
patch, dependency substitution or partial-result acceptance was used.

## Artifact routing and reproduction

TB5 UUID preflight passed. Docker's image data is already on TB5. macOS outputs
use the checkout's external SwiftPM scratch/cache; Linux versions have separate
linux-6.0 and linux-6.3.3 scratch/cache directories. Local logs under the checkout's
TB5 build root: ont-046-macos-quality.log, ont-046-linux60-final.log,
ont-046-linux633-final.log, ont-046-macos-contracts.log,
ont-046-linux60-contracts.log, ont-046-linux633-contracts.log and
ont-046-configured-missing-binary.log.

Run tools/swift-quality.sh with the supported scratch override on macOS. On Linux
run swift build with explicit target-import checking, then swift test with
ONTOLOGYC_TEST_BINARY_PATH pointing to that scratch binary. Run
tools/portable-contract-smoke.sh with ONTOLOGYC_PORTABLE_BINARY_PATH and the
TypeScript commands in SPECS/ontology. CI uses .build/ci-quality and Node 24.

## Boundaries

README explains source builds and the runtime-image requirement; this is not a
self-contained prebuilt Linux distribution. Compiler absence/failure is separate
from a valid ontology. Consumer unavailable/not-run handling and unrelated-flow
behavior remain the consumer's responsibility: no SpecGraph source was edited.

The immutable 0.1.0 tag, package versions/digests, historical reports, profile
admission rules and truth/causation boundaries are unchanged. No new release tag,
merge, deployment, inference or consumer migration is claimed. Hosted CI evidence
must match the published PR head before merge/release.
