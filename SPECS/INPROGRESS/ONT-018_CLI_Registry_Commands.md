# PRD: ONT-018 - CLI Registry Commands (publish, pull, compat-check)

**Status:** PRD Ready  
**Priority:** P2  
**Phase:** Registry and Distribution  
**Reasoning Effort:** high  
**Dependencies:** ONT-010, ONT-014  

## TL;DR

`ontologyc` currently operates only on local files. This task adds three commands that make
the toolchain registry-aware: `publish` pushes a compiled ontology package to a semver
registry, `pull` downloads a published package by ID and version, and `compat-check`
compares a local package against a registry version without requiring a manual `diff`
round-trip.

## Objective

Enable ontology authors to distribute their packages through a registry, pin transitive
imports to exact published versions, and verify backward compatibility against a live
registry entry — all from the CLI without writing custom HTTP scripts.

## Background

The `diff` command already generates a compatibility report between two local YAML files.
The `imports` section in a package already lists `id` and `version` for dependencies.
What is missing is a transport layer: no command can push a package to a server or resolve
an import reference to a downloadable artifact. This task adds that layer as three focused
commands, intentionally thin so that the registry protocol can be swapped later.

ONT-014 (CLI argument hardening) is a dependency because the new commands adopt the same
flag-order-independent argument parsing contract that task establishes.

## Scope

### In Scope

- **`ontologyc publish <package.yaml> --registry <url> [--token <token>]`**:
  - Runs `check` on the package; aborts on errors.
  - Compiles the package to a temp directory and reads the normalized IR.
  - HTTP-PUTs the compiled IR JSON to `<registry>/ontologies/<id>/<version>`.
  - Reads `--token` from the flag or the `ONTOLOGYC_TOKEN` environment variable.
  - Prints `ontologyc publish: PASS <id>@<version>` on success.
  - Exits non-zero on HTTP 4xx/5xx with the response body as the error message.

- **`ontologyc pull <ontology-id>@<version> --registry <url> --out <directory>`**:
  - HTTP-GETs `<registry>/ontologies/<id>/<version>` (content-type: `application/json`).
  - Writes the downloaded IR to `<directory>/<id>-<version>.normalized.json`.
  - Verifies the `sourceDigest` field in the downloaded IR matches the SHA-256 of the body.
  - Prints `ontologyc pull: PASS <id>@<version>` on success.

- **`ontologyc compat-check <package.yaml> --against <ontology-id>@<version> --registry <url>`**:
  - Pulls the specified registry version to a temp file.
  - Runs the existing `diffPackages` logic (from `CompatibilityDiff.swift`) treating the
    registry version as `from` and the local package as `to`.
  - Prints a concise summary and exits non-zero if any breaking changes are detected.
  - Optionally writes a full report with `--out <report.yaml>`.

- **`RegistryClient.swift`** in `OntologyCompiler`: thin HTTP wrapper around
  `URLSession.shared` with timeout, retry (up to 3 attempts, exponential back-off), and
  structured error types.

- **Usage string** in `main.swift` updated to document the three new commands.

- **Tests**: unit tests for argument parsing (via ONT-014 harness); integration tests
  against a local stub server for `publish` and `pull` round-trips; compat-check test
  using a pre-written IR fixture.

### Out of Scope

- Registry server implementation.
- Package signing or content-addressable storage.
- Dependency resolution / transitive `imports` auto-pull.
- Semver range matching (`^1.0`, `~2.3`) — exact version only.
- Authentication schemes beyond a bearer token.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Registry HTTP client | `Sources/OntologyCompiler/RegistryClient.swift` | GET and PUT with auth header, retries, and structured errors |
| D2 | Compiler methods | `Sources/OntologyCompiler/OntologyCompiler.swift` | `publishPackage`, `pullPackage`, `compatCheckPackage` methods |
| D3 | CLI commands | `Sources/OntologyC/main.swift` | Three new `case` branches; usage string updated |
| D4 | Unit tests | `Tests/OntologyCompilerTests/RegistryClientTests.swift` | Stub-server round-trips for publish and pull; compat-check break detection |
| D5 | Argument tests | `Tests/OntologyCompilerTests/` | Flag-order-independence and `--help` for each new command (via ONT-014 harness) |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|----|-------------|---------------------|--------------|
| FR-001 | `publish` MUST run `check` before uploading; packages with errors MUST NOT be published. | Error diagnostics printed; exit 1; no HTTP request made. | Unit test |
| FR-002 | `publish` MUST read the bearer token from `--token` or `ONTOLOGYC_TOKEN`; `--token` takes precedence. | Token present in `Authorization: Bearer …` header. | Unit test |
| FR-003 | `pull` MUST verify the `sourceDigest` of the downloaded IR. | Tampered body produces `E_REGISTRY_DIGEST_MISMATCH` error. | Unit test |
| FR-004 | `compat-check` MUST exit non-zero when the diff contains breaking changes. | Breaking removal of a class → exit 1. | Unit test |
| FR-005 | `compat-check` MUST exit zero when the diff is fully compatible. | Adding a new class with no removals → exit 0. | Unit test |
| FR-006 | All three commands MUST retry up to 3 times with exponential back-off on transient HTTP errors (5xx, timeout). | 3 attempts logged; succeeds on third. | Unit test with stub |
| FR-007 | `pull` output file name MUST follow `<id>-<version>.normalized.json` (dots in id replaced by dashes). | `io.specgraph.examcalc-1.0.0.normalized.json`. | Unit test |
| FR-008 | Existing commands (`check`, `compile`, `validate-specgraph`, `diff`) MUST be unaffected. | All regression hashes pass. | Regression suite |

## Implementation Roadmap

### Phase 1 — HTTP Client

1. Implement `RegistryClient.swift` with `get(url:token:)` and `put(url:body:token:)`,
   returning `Result<Data, RegistryError>`.
2. Add retry logic (3 attempts, back-off: 1s, 2s, 4s) for 5xx and connection-timeout errors.
3. Add `RegistryError` enum: `.httpError(Int, String)`, `.digestMismatch`, `.networkError(Error)`.

### Phase 2 — Compiler Methods

4. Add `publishPackage(path:registry:token:)` to `OntologyCompiler`.
5. Add `pullPackage(ref:registry:outDirectory:)` to `OntologyCompiler`.
6. Add `compatCheckPackage(path:against:registry:outPath:)` to `OntologyCompiler` — reuses
   existing `diffPackages` logic with a temp-dir pull step prepended.

### Phase 3 — CLI Integration

7. Add three `case` branches in `main.swift` following the ONT-014 flag-parsing convention.
8. Update the usage string.

### Phase 4 — Tests

9. Write `RegistryClientTests` using a `URLProtocol` stub to simulate the registry.
10. Write argument-parsing tests for each new command.
11. Confirm regression suite passes end-to-end.
