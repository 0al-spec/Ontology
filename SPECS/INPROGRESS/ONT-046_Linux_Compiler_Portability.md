# ONT-046 — Linux Compiler Portability

**Date:** 2026-10-28
**Status:** Planned
**Origin:** SpecGraph static-report publication runs on Linux, while Ontology
0.1.0 documents only macOS source builds. The user explicitly requests support.

## Deliverables

1. Preserve Swift 6.0 source compatibility and current macOS minimum. Add an
   exact compatible swift-crypto dependency only to the Linux targets that need
   SHA-256; keep native CryptoKit on macOS. Inspect upstream tools floor/license
   and resolve Package.resolved normally without upgrading unrelated packages.
2. Conditional FoundationNetworking imports for the registry client and its
   tests. Replace direct libc stderr references with a small synchronous
   Foundation diagnostic writer, preserving messages/exit codes without unsafe
   concurrency annotations or an async CLI redesign.
3. Linux CI at the Swift 6.0.3 floor and a current 6.3.x toolchain. Build with
   explicit dependency-import checking and run the existing compiler/rule tests.
   Use a shared cross-platform gate for generated baselines, draft packages and
   instance/provenance/responsibility/motivation contracts; keep TypeScript checks.
4. Public documentation for Linux source builds and SpecGraph integration:
   missing compiler means unavailable/not-run, never passed. Keep absence scoped
   to dependent validation; this task does not edit consumers or unrelated flows.

## Acceptance

- Stock repository builds/tests on real Linux without reviewer patches. Record
  toolchain, architecture and exact source; CI is separate from local Docker.
- Generated baselines remain byte-identical on both platforms, including frozen
  events/provenance contracts and current draft packages. Do not change digests,
  profiles, reports, source-truth/causation flags or ontology semantics.
- Negative CLI inputs still return failure; an explicitly missing compiler in
  the shared gate fails clearly rather than yielding validation success.
- macOS full quality/coverage and Linux tests/contracts pass. Build/cache/temp
  outputs remain on verified TB5 locally, with separate platform/toolchain paths.
- Publish the branch and PR for review. No merge, new release tag, consumer
  migration, deployment, paid inference or new runtime profile is implied.

## Verification sequence

Inspect compatible dependency manifests, implement the smallest port, resolve
dependencies, then build/test native macOS and actual Linux containers. Add and
run the shared package/fixture gate and TypeScript checks. Run Linux/macOS hosted
CI on the published PR head. Archive evidence and a self-review through FLOW;
keep any unsupported platform boundary explicit.
