# ONT-047 — Validation Report

**Date:** 2026-10-27
**Verdict:** PASS — local implementation and regression gates; hosted CI and independent review pending
**Profile:** eventcore-provenance-v1 / 1.0.0
**Package:** org.0al.events.core@0.2.0 (draft)

## Delivered

- A separately stored event-core revision: 21 classes, 32 relations, seven manual
  policy declarations and all ten generated IR/SDK files. The staged draft is
  byte-identical to assembled YAML. Existing 0.1.0 YAML/IR/SDK are unchanged.
- Three disjoint snapshot origins (source/direct/operator), explicit confirmation
  under caller-selected external authority, and separate enrichment admission.
- Exact graph-byte binding, profile definition pin, scoped capability grants,
  strict input shape and deterministic reports/consumer contracts.
- Known-snapshot identity and partial proposition/polarity preservation. Candidates
  with unavailable physical states may remain source-only without a record/Delta.
- Old eventcore-v1 remains the explicit default and retains its limitation/report
  contract. No migration, replay reinterpretation or background state generation.

## Executed checks

| Check | Result |
|---|---|
| Actual ontologyc validate-draft and check for 0.2.0 | PASS |
| Fresh package compile against all ten generated baseline files | PASS |
| Fresh profile export against three consumer baseline files | PASS |
| New static fixture/CLI smoke | 18/18 expected outcomes: four passes, fourteen failures |
| Focused SnapshotProvenanceTests | 15/15, including mutation loops and static fixture replay |
| Full RUN_COVERAGE=1 bash tools/swift-quality.sh | PASS, 158 tests total (143 existing + 15 new), format/lint/import checks |
| npm run typecheck / npm run smoke | PASS, old package smoke and new origin/consumer controls |
| Existing tools/instance-graph-smoke.sh | PASS, unchanged v1 export; limitation still passed, missing interval failed |
| Relative Markdown links before archive | 49/49 resolve |

Configured llvm-cov TOTAL line coverage is 89.87%, region 79.37%; this configured
report includes dependency/vendor code. Coverage is not provenance or factual
accuracy evidence. The native Swift build-system deprecation warning is unchanged;
there are no source compiler errors or lint/format failures.

Tests cover source presence without confirmation, absent/ambiguous/orphan origins,
wrong/duplicate confirmation identities, scope/projection/capability refusal,
operator identity/rationale, capture time/clock/digest controls, stale authority
binding, unknown authority fields, malformed encoding/duplicate keys, IR/definition
pin tampering, explicit selection, real CLI exits, known/partial preservation,
resolution bypass, deterministic reports and source-only no-snapshot behavior.

## Pins

- IR SHA-256: e6c932ad8c492d168b63dbe112335c270d88ff758e016f3502031aefe9dea916
- Source digest: sha256:92a3245fc9acd15748fd1fa3cfb8e4fdc8fda429a5fd6cffd7a97bc13f2f359e
- Definition SHA-256: 240d518666905c320df299b5d4d9e08e7c2564b0ca97ca2ab15d0a275dbe2551

The profile descriptor identifies this contract; it does not authenticate a binary
or independently prove that the implementation conforms to the descriptor.
The checked-in negative fixtures and tests are the executable conformance evidence.

## Trust boundary and limitations

The authority input must be selected/protected by the caller independently of the
graph. Grants/confirmations are trusted declarations under this offline contract,
not authenticated signatures. A caller controlling both inputs can assert false
provenance. Sources/artifacts are not fetched, extraction completeness/relevance
is not decided, and physical facts are not established. sourceTruthVerified,
causationVerified, responsibilityVerified and authorityAuthenticationVerified
remain false. Source-only success says no-snapshots, not confirmed provenance.

Exact graph-byte binding is conservative: any change, including whitespace or
roles, requires explicit reconfirmation. Validation never generates approvals.
StateSnapshot completeness remains a declaration accepted by the selected
trusted authority; admission is not evidence of external factual accuracy.
No NormLab code/tests, paid inference, deployment, authority revocation service,
cryptographic identity implementation or responsibility calculation is included.

## Local output routing

TB5 UUID preflight passed. Swift build/test/module caches, temporary reports and
LLVM profiles were routed outside the checkout. Full quality evidence is at
/Volumes/TB5/Developer/Builds/GitHub/Ontology-881ba79a220bd2df/ont-047-quality.log.
Tracked generated IR/SDK/consumer files are intentional source deliverables.

## Next step

Publish the independent ONT-047 PR and obtain hosted CI plus independent review
on the actual head. ONT-045 may keep the source-only export path while a consumer
explicitly selects and implements any provenance-aware admission contract.
