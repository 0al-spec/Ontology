# ONT-035: SpecGraph Proposal 0060 Minimal Consumer Slice PRD

**Status:** PRD Ready
**Priority:** P1
**Phase:** SpecGraph Value Loop Closure
**Reasoning Effort:** high
**Dependencies:** ONT-031, ONT-033

## TL;DR

Implement the first narrow SpecGraph-side consumer slice for proposal 0060. The slice must
prove that SpecGraph can consume an Ontology-produced examcalc IR or local registry
materialization, resolve at least one known ontology ref, and surface one missing ref as an
explicit ontology gap rather than inventing a local pseudo-concept.

This is cross-repository work. Ontology remains the producer/compiler authority. SpecGraph
owns the consumer artifacts, derived indexes, and review-first boundary.

## Problem

Ontology now has validated packages, generated normalized IR, deterministic local registry
transport, and SpecGraph validation contracts. SpecGraph has proposal
`0060_external_ontology_import_plane.md`, but no minimal runtime slice proving that a graph
consumer can import a package, pin version/digest metadata, resolve concept refs, and emit
gaps without copying `DomainOntologyPackage` semantics.

Without this slice, the integration remains mostly documentary: Ontology can produce
artifacts, but SpecGraph has no checked consumer evidence.

## Goals

1. Add a minimal SpecGraph-side policy and fixture set for external ontology imports.
2. Consume Ontology-generated examcalc normalized IR or a registry-materialized copy, not
   the source package YAML.
3. Resolve at least one known `examcalc:*` reference from the imported IR.
4. Emit an explicit `OntologyGap`-style derived artifact for one unresolved `examcalc:*`
   reference.
5. Record package id, namespace, version, source URI, and digest/lock metadata.
6. Keep all outputs derived and review-first: no canonical `specs/nodes/*.yaml` mutation.
7. Link Ontology documentation to the SpecGraph consumer slice after the SpecGraph PR
   exists.

## Non-Goals

- No hosted ontology registry.
- No supervisor invocation of `ontologyc`.
- No prompt-agent execution.
- No Agent Passport enforcement.
- No SpecSpace UI.
- No copy of `DomainOntologyPackage` schema into SpecGraph.
- No automatic update to a canonical SpecGraph `ontology.lock.yaml`.
- No reuse of SpecGraph `specs/nodes/SG-SPEC-0060.yaml`, which currently represents a
  different bounded spec.

## Source Alignment

| Source | Relevant Contract |
|--------|-------------------|
| Ontology ONT-031 | SpecGraph must consume imported ontology packages through lock/ref/gap artifacts and must not define pseudo-concepts locally. |
| Ontology ONT-033 | Local `file://` registry transport can be used for deterministic CI materialization. |
| SpecGraph proposal `0060_external_ontology_import_plane.md` | Runtime follow-up surfaces include ontology import policy, package index, gap index, governance evidence index, binding preview, and prompt invocation index. |
| `SPECS/ontology/packages/examcalc/generated/ontology.normalized.json` | Stable Ontology-produced IR for known `examcalc:*` refs. |
| `SPECS/ontology/core-contracts.md` | Normative `OntologyImport`, `ConceptRef`, `SemanticBinding`, `OntologyGap`, and lockfile boundary. |

## Deliverables

### D1. SpecGraph Policy Artifact

Add `tools/ontology_import_policy.json` in SpecGraph. It should define:

- accepted artifact kinds for package index, gap index, binding preview, and governance
  evidence index;
- required package ref fields: package id, namespace, version, source URI, digest;
- derived-output posture: `canonical_mutations_allowed: false`;
- requirement that missing refs become ontology gaps;
- requirement that imported package semantics are read from normalized IR or registry
  materialization, not re-modeled in SpecGraph.

### D2. SpecGraph Fixture

Add a minimal fixture under SpecGraph tests, using examcalc:

- imported package metadata for `edu.university.examcalc@0.1.0`;
- digest matching Ontology generated metadata;
- one binding with known refs such as `examcalc:Exam` and `examcalc:requires_policy`;
- one unresolved ref such as `examcalc:CASFunction`.

The fixture may include a checked-in copy of Ontology-generated normalized IR as a
registry/materialization fixture. It must not include or reinterpret Ontology source YAML.

### D3. SpecGraph Derived Index Builder

Add a narrow builder, preferably in `tools/` and optionally exposed through `make`, that:

- loads the policy and fixture;
- reads normalized IR refs;
- emits a package index containing imported package metadata and lock/digest fields;
- emits a binding preview containing resolved refs and unresolved refs;
- emits a gap index with one explicit unresolved concept gap;
- marks every derived output with `canonical_mutations_allowed: false`.

### D4. SpecGraph Tests

Add focused tests proving:

- known examcalc refs resolve from imported IR;
- unresolved refs produce a gap entry;
- package metadata includes id, namespace, version, source URI, and digest;
- generated surfaces are derived and do not allow canonical mutation;
- proposal runtime registry for `0060` has validation/observation markers for the slice.

### D5. Ontology Link-Back

Update Ontology docs after the SpecGraph PR exists:

- mention the SpecGraph consumer slice in the SpecGraph validation or bridge section;
- include the SpecGraph PR or file paths as external evidence;
- keep wording clear that Ontology still owns the package/compiler boundary.

## Acceptance Criteria

- [ ] SpecGraph-side work consumes Ontology-generated IR or registry materialization
      instead of duplicating Ontology package semantics.
- [ ] A minimal requirement or binding fixture resolves at least one known examcalc concept
      or relation.
- [ ] A missing concept produces an explicit gap artifact instead of a local
      pseudo-concept.
- [ ] The slice records imported ontology version and digest/lock metadata.
- [ ] Ontology docs link to the SpecGraph-side consumer slice once it exists.
- [ ] SpecGraph tests validate the consumer slice without requiring a live HTTP registry.
- [ ] Ontology quality gate records the cross-repo validation evidence.

## Execution Plan

1. Create a dedicated SpecGraph branch from its current default branch without disturbing any
   unrelated local SpecGraph branch.
2. Implement D1-D4 in SpecGraph and open a SpecGraph PR.
3. Update Ontology docs with a link-back to the SpecGraph PR or merged files.
4. Run Ontology gates and record a validation report that names both Ontology and SpecGraph
   checks.
5. Archive ONT-035 under Flow after the link-back and validation evidence exist.

## Risks

| Risk | Mitigation |
|------|------------|
| SpecGraph current branch is unrelated work | Use a separate branch or worktree from the SpecGraph default branch. |
| Fixture accidentally copies package semantics | Consume generated IR only; do not parse or copy `domain-ontology-package.yaml`. |
| Gap artifact looks canonical | Mark derived surfaces `canonical_mutations_allowed: false` and avoid writes to `specs/nodes/*.yaml`. |
| Proposal 0060 ID collision with `SG-SPEC-0060.yaml` | Reference the proposal markdown, not the existing unrelated spec node. |

## Validation

Expected checks:

```bash
# SpecGraph
python3 -m pytest tests/test_ontology_import_policy.py
make proposal-tracking-gate
make test

# Ontology
bash tools/swift-quality.sh
bash tools/typescript-smoke.sh
test -f README.md
test -f SPECS/Workplan.md
```

## Potential Next Step

After this slice lands, the next useful step is to decide whether SpecGraph should call
`ontologyc validate-specgraph` directly in a later adapter/report contract, or continue with
pure fixture-driven derived indexes until the registry and package cache story is more
stable.
