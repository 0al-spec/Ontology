# ONT-036: `ontologyc` Adapter Report Artifact PRD

**Status:** PRD Ready  
**Priority:** P0  
**Phase:** External Ontology Import Plane Follow-Ups  
**Reasoning Effort:** high  
**Dependencies:** ONT-035  
**Branch:** `codex/ont-036-ontologyc-adapter-report`

## TL;DR

Teach `ontologyc validate-specgraph` to emit a typed
`ontologyc_adapter_report` beside its existing SpecGraph validation outputs.
The report gives SpecGraph a deterministic adapter boundary artifact with
package source/version/digest, input/output refs, resolved/gap counts, and
explicit authority flags.

The report is evidence only. It must not become a canonical SpecGraph import
lock, must not claim authority over SpecGraph specs, and must not imply that
`ontologyc` can mutate `specs/nodes/*.yaml`.

## Problem

SpecGraph proposal `0060_external_ontology_import_plane.md` and the merged
SpecGraph adapter/report consumer slice now define the shape SpecGraph can
validate:

```yaml
artifact_kind: ontologyc_adapter_report
schema_version: 1
producer:
  tool: ontologyc
  command: validate-specgraph
package:
  package_id: edu.university.examcalc
  namespace: examcalc
  version: 0.1.0
  source_uri: git+https://github.com/0al-spec/Ontology.git
  source_ref: main
  digest: sha256:...
summary:
  canonical_mutations_allowed: false
authority_boundary:
  report_is_authority: false
```

Today Ontology emits the component outputs:

- `concept-refs.yaml`
- `ontology.lock.yaml`
- `ontology-gaps.yaml`

But it does not emit a single adapter report that binds those outputs to the
normalized IR digest and the non-authoritative boundary. SpecGraph currently
uses a checked-in fixture for that report. ONT-036 replaces that fixture-only
gap with a real Ontology compiler artifact.

## Goals

1. Add deterministic `ontologyc-adapter-report.yaml` output to
   `validate-specgraph`.
2. Keep existing `concept-refs.yaml`, `ontology.lock.yaml`, and
   `ontology-gaps.yaml` output shapes unchanged.
3. Keep current CLI PASS/FAIL stdout behavior backward-compatible.
4. Include source URI/ref fields without making them mandatory for existing
   callers.
5. Encode the authority boundary directly in the report:
   `canonical_mutations_allowed: false`, `tracked_artifacts_written: false`,
   `report_is_authority: false`, and no automatic import-lock or canonical node
   updates.
6. Add tests that validate report shape, counts, digest authority, and
   backward-compatible existing outputs.
7. Update Ontology docs so downstream consumers know the report is review
   evidence, not canonical state.

## Non-Goals

- No supervisor invocation of `ontologyc`.
- No prompt-agent execution or invocation artifact.
- No SpecSpace UI or review action mutation.
- No Platform/Docker packaging.
- No canonical SpecGraph `ontology.lock.yaml` writeback.
- No change to `DomainOntologyPackage` source schema.
- No registry network calls during `validate-specgraph`.

## Source Alignment

| Source | Relevant Contract |
|--------|-------------------|
| SpecGraph proposal `0060_external_ontology_import_plane.md` | External ontology tools emit typed reports/proposals and cannot mutate canonical SpecGraph state directly. |
| SpecGraph `docs/ontologyc_adapter_report_contract.md` | Accepted report kind, fields, summary counts, digest authority, and failure posture. |
| ONT-031 | Ontology owns compiler/package behavior; SpecGraph owns review-first import semantics. |
| ONT-035 | First consumer slice proved fixture-driven import/ref/gap behavior. |

## CLI Contract

Existing command remains valid:

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/examcalc-semantic-validation
```

New optional metadata flags:

```bash
  --source-uri git+https://github.com/0al-spec/Ontology.git \
  --source-ref main
```

If omitted, the report uses:

- `package.source_uri: ""`
- `package.source_ref: ""`

The package digest always comes from normalized IR `sourceDigest`; this is the
only digest authority for the adapter report.

## Report Shape

`validate-specgraph` writes:

```text
<out>/ontologyc-adapter-report.yaml
```

with this stable shape:

```yaml
artifact_kind: ontologyc_adapter_report
schema_version: 1
proposal_id: "0060"
producer:
  tool: ontologyc
  command: validate-specgraph
  command_contract_ref: Ontology:SPECS/ontology/ontologyc.md#validate-specgraph
package:
  package_id: edu.university.examcalc
  namespace: examcalc
  version: 0.1.0
  source_uri: git+https://github.com/0al-spec/Ontology.git
  source_ref: main
  digest: sha256:...
inputs:
  binding_ref: missing-ref-semantic-binding.yaml
  normalized_ir_ref: ontology.normalized.json
outputs:
  concept_refs_ref: concept-refs.yaml
  ontology_lock_ref: ontology.lock.yaml
  ontology_gaps_ref: ontology-gaps.yaml
summary:
  status: passed
  resolved_ref_count: 2
  gap_count: 1
  canonical_mutations_allowed: false
  tracked_artifacts_written: false
authority_boundary:
  report_is_authority: false
  digest_authority: normalized_ir_sourceDigest
  ontology_lock_is_canonical: false
  automatic_import_lock_update: false
  automatic_canonical_node_update: false
```

Paths are basename refs by default so the report remains portable across local
machines and CI workspaces.

## Deliverables

| ID | Deliverable | Output Path | Acceptance Criteria |
|----|-------------|-------------|---------------------|
| D1 | Compiler report builder | `Sources/OntologyCompiler/SpecGraphValidation.swift` or focused companion file | Builds deterministic report from binding path, IR path, output names, counts, and source metadata. |
| D2 | Compiler API option | `Sources/OntologyCompiler/OntologyCompiler.swift` | `validateSpecGraph` accepts optional source URI/ref metadata without breaking existing callers. |
| D3 | CLI flags | `Sources/OntologyC/CLIArguments.swift`, `Sources/OntologyC/main.swift` | Optional `--source-uri` and `--source-ref` are accepted for `validate-specgraph`. |
| D4 | Tests | `Tests/OntologyCompilerTests/OntologyCRegressionTests.swift` or focused test file | Tests assert report kind, schema version, package fields, counts, digest, and authority flags. |
| D5 | Docs | `SPECS/ontology/ontologyc.md`, DocC, README as needed | Docs describe the report and its non-authoritative boundary. |
| D6 | Validation report | `SPECS/INPROGRESS/ONT-036_Validation_Report.md` | Records local quality gates and residual risks. |

## Functional Requirements

| ID | Requirement | Acceptance Criteria | Verification |
|----|-------------|---------------------|--------------|
| FR-001 | `validate-specgraph` MUST write `ontologyc-adapter-report.yaml`. | File exists after command success. | Regression test |
| FR-002 | Report MUST bind package identity to normalized IR. | Package id, namespace, version, and digest equal IR fields. | Regression test |
| FR-003 | Digest authority MUST be `normalized_ir_sourceDigest`. | `authority_boundary.digest_authority` has the required value. | Regression test |
| FR-004 | Report MUST preserve no canonical mutation boundary. | Summary and authority flags are all false where required. | Regression test |
| FR-005 | Summary counts MUST match emitted outputs. | Resolved count equals `concept-refs.yaml` entries; gap count equals `ontology-gaps.yaml` entries. | Regression test |
| FR-006 | Existing outputs MUST remain backward-compatible. | Baseline assertions for existing files still pass. | Existing regression tests |
| FR-007 | Existing callers MUST remain valid. | Old command form succeeds without new flags. | CLI/regression test |

## Implementation Roadmap

### Phase 1 - Report Builder

- Add an internal report builder using existing `JSONObject`/`writeYAML` helpers.
- Use `URL(fileURLWithPath:).lastPathComponent` for portable input/output refs.
- Read package id, namespace, version, and `sourceDigest` from normalized IR.

### Phase 2 - API And CLI

- Add optional source metadata to `validateSpecGraph`.
- Extend `validate-specgraph` allowed CLI options with `--source-uri` and
  `--source-ref`.
- Keep stdout unchanged:
  `ontologyc validate-specgraph: PASS <binding> resolved=<n> gaps=<n>`.

### Phase 3 - Tests And Docs

- Extend regression coverage to assert the adapter report.
- Update compiler docs and the `ontologyc` contract.
- Record validation commands in `ONT-036_Validation_Report.md`.

## Risks

| Risk | Mitigation |
|------|------------|
| Downstream treats report as canonical lock | Hard-code authority flags to false and document that canonical SpecGraph lock updates remain separate governance actions. |
| Local paths leak into reports | Use basename refs, not absolute paths. |
| New flags break existing callers | Make `--source-uri` and `--source-ref` optional and keep old command tests. |
| SpecGraph contract drift | Align field names with the merged SpecGraph adapter/report contract and keep tests strict. |

## Validation

Expected checks:

```bash
swift test
bash tools/swift-quality.sh
bash tools/typescript-smoke.sh
git diff --check
```

When checking the concrete report manually:

```bash
swift run ontologyc validate-specgraph \
  SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml \
  --ontology-ir SPECS/ontology/packages/examcalc/generated/ontology.normalized.json \
  --out /tmp/examcalc-semantic-validation \
  --source-uri git+https://github.com/0al-spec/Ontology.git \
  --source-ref main

test -f /tmp/examcalc-semantic-validation/ontologyc-adapter-report.yaml
```

## Success Criteria

- `ontologyc` emits the adapter report deterministically.
- SpecGraph can replace the fixture-only report with a report generated by
  Ontology tooling.
- Existing semantic validation behavior remains unchanged for current callers.
- The trust boundary is explicit in code, tests, and docs.
