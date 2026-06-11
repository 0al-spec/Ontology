# ONT-033: File And Git Registry Transport

**Status:** PRD Ready
**Priority:** P1
**Phase:** SpecGraph Value Loop Closure
**Reasoning Effort:** high
**Dependencies:** ONT-018, ONT-026, ONT-031

## TL;DR

Add a local filesystem registry transport to the existing `publish`, `pull`, and
`compat-check` flows by accepting `file://` registry URLs. A registry directory can then be
committed to git and reviewed like any other artifact store, without introducing an HTTP
registry server yet.

This closes the first registry dogfooding loop while preserving the current HTTP registry
contract and the trusted publication governance gate.

## Problem

`ontologyc` already has registry-oriented commands, but they only speak HTTP. That leaves
the registry value loop difficult to use before a reference server exists:

- `publish` needs an endpoint even for local review workflows.
- `pull` cannot resolve a package from a checked-in artifact directory.
- `compat-check` cannot compare against a locally published package through the same
  package reference model.
- SpecGraph integration planning needs a concrete, reviewable registry backing store before
  a production service exists.

The project needs a deterministic local transport that exercises the same compiler,
governance, and compatibility logic without widening the task into a server implementation.

## Goals

1. Support `file://` registry URLs for `publish`, `pull`, and `compat-check`.
2. Keep HTTP registry behavior unchanged.
3. Store published packages in a deterministic directory layout suitable for git review.
4. Preserve the existing trusted publication governance gate before any local write.
5. Add CLI/regression coverage for local publish -> pull -> compat-check.
6. Document how to use a git repository as the local registry backing store.

## Non-Goals

- No HTTP registry server implementation.
- No `git://`, GitHub API, push, commit, clone, or remote sync automation.
- No transitive dependency resolution from `imports`.
- No semver range resolution; exact `<id>@<version>` remains the only package reference.
- No cryptographic signatures or content-addressable registry layout.
- No new `--channel` option for `pull` or `compat-check` in this slice.

## CLI Contract

Existing commands continue to use `--registry <url>`, but `<url>` may now be either HTTP(S)
or `file://`:

```bash
swift run ontologyc publish SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --registry file:///tmp/ontology-registry \
  --channel candidate

swift run ontologyc pull edu.university.examcalc@0.1.0 \
  --registry file:///tmp/ontology-registry \
  --out /tmp/pulled-ontology

swift run ontologyc compat-check SPECS/ontology/packages/examcalc/domain-ontology-package.yaml \
  --against edu.university.examcalc@0.1.0 \
  --registry file:///tmp/ontology-registry \
  --out /tmp/compatibility-report.yaml
```

`file://` is intentionally required instead of accepting raw paths. That keeps CLI parsing
unambiguous and avoids weakening the existing `--registry <url>` contract.

## Local Registry Layout

Publishing `<id>@<version>` writes:

```text
<registry-root>/
  ontologies/
    <id>/
      <version>/
        ontology.normalized.json
        registry-entry.yaml
  channels/
    <channel>/
      <id>/
        <version>.yaml
```

Rules:

- `ontology.normalized.json` is the same deterministic IR body the HTTP transport uploads.
- `registry-entry.yaml` is deterministic metadata for review:
  - `apiVersion`
  - `kind: OntologyRegistryEntry`
  - `metadata.id`
  - `metadata.version`
  - `metadata.channel`
  - `metadata.sourceDigest`
  - `spec.artifact`
- The channel index file points at the canonical artifact path and has deterministic keys.
- Publishing the same package/channel again must produce byte-stable files.
- `pull` reads `ontologies/<id>/<version>/ontology.normalized.json`.
- `compat-check` reads through the same local transport as `pull`.

## Design Notes

- Add a registry location abstraction that keeps HTTP and filesystem handling separate.
- Keep the public CLI shape small: existing commands still take `--registry`.
- Governance validation remains inside `publishPackage` before the transport writes data.
- Local registry write failures should surface as compiler/IO errors and exit non-zero.
- The local registry is "git-backed" by convention: users place the registry root inside a
  git repository and review the changed files. `ontologyc` should not run git commands.

## Deliverables

| ID | Deliverable | Path |
|----|-------------|------|
| D1 | Registry location abstraction for HTTP and file transports | `Sources/OntologyCompiler/CompilerArgumentTypes.swift` |
| D2 | Local registry file transport | `Sources/OntologyCompiler/` |
| D3 | Publish/pull/compat-check integration | `Sources/OntologyCompiler/OntologyCompiler.swift`, `Sources/OntologyC/CLIArguments.swift`, `Sources/OntologyC/main.swift` |
| D4 | Local registry tests | `Tests/OntologyCompilerTests/` |
| D5 | CLI regression coverage | `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift` |
| D6 | Documentation | `README.md`, `SPECS/ontology/ontologyc.md` |
| D7 | Validation report | `SPECS/INPROGRESS/ONT-033_Validation_Report.md` |

## Acceptance Criteria

- [ ] `RegistryBaseURL` or successor location type accepts `https://...` and `file://...`.
- [ ] Existing HTTP registry client tests still pass unchanged in behavior.
- [ ] `ontologyc publish ... --registry file://...` writes deterministic IR and registry metadata.
- [ ] `ontologyc pull <id>@<version> --registry file://...` resolves the same package reference and writes the expected pulled IR filename.
- [ ] `ontologyc compat-check ... --registry file://...` compares against the locally published IR.
- [ ] Trusted local publication still rejects before writing when governance evidence is missing or invalid.
- [ ] Documentation shows a git-backed registry workflow without implying that `ontologyc` runs git.
- [ ] Full Swift quality gate and TypeScript smoke gate pass.

## Validation Plan

- `swift test --filter CompilerArgumentTypesTests`
- `swift test --filter RegistryClientTests`
- `swift test --filter RegistryPublishGovernanceGateTests`
- `swift test --filter OntologyCRegressionTests`
- Local CLI round trip:
  - `swift run ontologyc publish ... --registry file:///tmp/...`
  - `swift run ontologyc pull ... --registry file:///tmp/... --out /tmp/...`
  - `swift run ontologyc compat-check ... --registry file:///tmp/... --out /tmp/...`
- `bash tools/typescript-smoke.sh`
- `bash tools/swift-quality.sh`
- `git diff --check`

## Risks

| Risk | Mitigation |
|------|------------|
| File transport accidentally changes HTTP behavior | Keep HTTP client tests and route by URL scheme only. |
| Local registry layout becomes hard to review | Use deterministic paths and metadata without timestamps. |
| Channel semantics become ambiguous | Keep `pull` exact-ref based and use channels as metadata/index only. |
| The task grows into registry server work | Explicitly exclude HTTP server and git automation. |

## Potential Next Step

After ONT-033, run ONT-034 to make staged induction artifacts machine-validated before
final `DomainOntologyPackage` YAML assembly.
