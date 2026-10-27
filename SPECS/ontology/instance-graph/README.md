# InstanceGraph v1alpha1 — bounded eventcore-v1 profile

This is an offline structural validation contract for
[event-core 0.1.0](../packages/events-core/README.md). It does not establish source
truth, physical causation, human attribution, duties or legal responsibility.
It does not write a registry, modify source narratives or call a model.

## Envelope and identity

An explicit JSON object contains only apiVersion, kind, profile, graphKey,
revisionKey, ontology, projections, nodes and edges. See the
[generated consumer types](generated/instance-graph.ts),
[JSON Schema](generated/instance-graph.schema.json) and
[complete synthetic example](../fixtures/instance-graphs/synthetic-car.json).

Input must be UTF-8 without a BOM. UTF-16/UTF-32, their BOMs, malformed UTF-8
and raw NUL bytes are rejected before Foundation parsing; ordinary JSON
whitespace is allowed. The key scanner must consume the complete document.

- apiVersion is `ontology.specgraph.io/instance-graph/v1alpha1`, kind is
  `InstanceGraph`, profile is `eventcore-v1`.
- ontology pins id/namespace/version/sourceDigest. The CLI additionally verifies
  the exact normalized IR file SHA256, including formatting/newline:
  `2c596f08073653e8a47df8e46aa1b1b75284717d32148d162d497775ce5a31a0`.
  Updating this artifact requires an explicit new reviewed profile/pin.
- graphKey/revisionKey identifies the supplied input revision. Nodes have a
  local id, exact type and explicit scalar fields object. Lifecycle-bearing
  nodes also require state proposed/reviewed/rejected.
- Each edge has relation, from and to. Both references include graphKey,
  revisionKey, nodeId and exact type. All must resolve inside this input revision;
  imported/cross-revision nodes are not implicitly fetched.
- Unknown/legacy fields, nulls, repeated JSON keys (including escaped aliases),
  duplicate node ids/edges, wrong types/ranges and missing mandatory links fail.
- Integers are finite JS-safe integers. Times/UTF-16 offsets are nonnegative;
  intervals require start <= finish. Source quote offset length must match the
  quote's UTF-16 length; original document bytes/relevance are not verified.

Input is bounded to 10 MiB and JSON depth below 64, with at most 10,000 nodes,
50,000 edges and 1,000 projections. Identifiers use the ASCII pattern in the
generated schema; labels/quotes/proposition keys may contain Unicode.

## Projections, observations and exact change

Projections declare unique projectionKey, schemaKey and a domain: observation,
review or normative. A StateSnapshot references that declared schema/projection
and supplies its complete finite fact set through snapshotContainsFact edges.
RecordedEvent requires direct before/after snapshots from an observation
projection with equal schema/scope/projection and its Episode.scopeKey.

Completeness and the projection domain are declarations made by the exporter.
The validator rejects a declared review/normative projection on a recorded event;
it cannot detect dishonest relabeling of review data as observations or prove
that physical observations are accurate. It does not compare this input against
an earlier revision or guarantee external storage immutability.

In particular, the profile **cannot detect invented empty snapshots** attached
to a source-only candidate through candidateEnrichedByRecord. StateSnapshot has
no provenance link, so externally authored empty snapshots can be structurally
valid even while the candidate's observations remain unknown. The explicit
[limitation fixture](../fixtures/instance-graphs/limitation-unproven-empty-enrichment.json)
is expected to return passed with sourceTruthVerified false. It is a regression
test of this limitation, not a valid way to obtain physical observations.
ONT-047 tracks a future provenance-aware vocabulary/profile. Until then, the
ONT-045 exporter must preserve source-only candidates and never synthesize states.

| Candidate availability | observationSnapshot | Direct observationSuppliesFact |
|---|---|---|
| known | Exactly one | None. |
| unknown | None | None. |
| partial | None | At least one fact. |

Candidates can remain source-only without a record or Delta. Missing before/after
candidate links are also allowed. Review cannot convert unknown data into states.
The [source-only example](../fixtures/instance-graphs/source-only.json) retains
the letter's speaker and has no invented physical snapshots.

Each record belongs to one EventRegistry revision. Registry identity is
(registryKey, revisionKey); recordKey is unique within it. Two interpretation
nodes may use different roles for that single record. They cannot supply their
own before/after state edges or introduce another record with the same local key.
Episode.scopeKey is unique within the graph revision, so one scope cannot alias
two Episode nodes. References and snapshot scopes use that same episode identity.

Delta derives both snapshots through one deltaOfRecord owner. There is at most
one Delta node per record, including identical duplicates. Its Added/Removed
sets must equal exact differences of propositionKey/polarity pairs. Repeated
fact values within a set are rejected. Positive and negative support are distinct
values and can coexist; removal never invents negative support. Explicit equal
complete snapshots, including empty ones, allow an empty Delta. An absent Delta
does not assert that no changes occurred.

## Causal hypotheses and source review

Hypotheses link cause/effect Interpretations, each bound to a registered record.
Records must be distinct and share a registry revision, episode and clockKey.
Cause start must be no later than effect start. Overlapping intervals are allowed
for an omission continuing while the car begins to move.
Order checks run only when both intervals are valid and the clocks match;
invalid intervals or incomparable clocks do not produce secondary order errors.

The synthetic example binds the owner to the omission interpretation and the
car to the movement interpretation. General actors are any Entity. No human
anchor, ownership-based duty or transfer of breach is inferred. Hypothesis
profileRef must be eventcore-v1; review state is not proof of causation.

State membership is checked, but executing commands/reconstructing lifecycle
history is outside this input contract. SourceAssertion preserves sourceRef,
revisionKey, sourceDigest, quote, offsets and optional speakerKey. The validator
does not infer speaker identity, citation relevance or resolve conflicting
accounts. Uncited operator assertions are not converted into sourced facts.

## Commands and reports

Build the compiler using the configured external build/cache location, then:

```sh
ontologyc validate-instances SPECS/ontology/fixtures/instance-graphs/synthetic-car.json --ontology-ir SPECS/ontology/packages/events-core/generated/ontology.normalized.json --out /path/to/report.json
ontologyc export-instance-contract --ontology-ir SPECS/ontology/packages/events-core/generated/ontology.normalized.json --out /path/to/consumer-contract
```

Validation exits 0 for passed, 1 for failed input/profile checks and 2 for CLI
usage errors. The optional deterministic JSON report includes graph/ontology
identity, sorted error code/path/message entries and explicit false flags for
source truth, causation and responsibility verification. IO failure messages can
contain local filesystem context. Invalid shapes stop before reference checks;
invalid references stop before profile checks, avoiding secondary guesses.
graphSHA256 binds the report to exact input bytes, even if an exporter reuses
the same claimed graph/revision identity. It is empty when the graph could not
be read (including an earlier IR pin failure); it is not a signature or storage lock.

The compiler checks exact IR integrity before invoking package-internal rule
specifications. External callers use OntologyCompiler.validateInstanceGraph or
the CLI; the low-level unpinned graph context is not a public library API.

JSON Schema and TypeScript validate consumer shapes, not cross-node integrity,
unique identities, exact Delta, temporal order or source truth. `validate-instances`
is the structural authority for this bounded profile. This is not Lean evidence.

## Reproduction

The Swift quality gate tests rule mutations, exact/empty/opposed Delta controls,
source-only candidates, CLI failures/reports, IR tampering and deterministic
consumer export. TypeScript checks valid shapes and expected compile errors for
missing intervalStart and a StateObservation used as a record snapshot.
`tools/instance-graph-smoke.sh` replays fixtures and compares fresh consumer
contracts to the committed baseline in CI. ONT-044 adds responsibility vocabulary;
ONT-045 owns a separate offline NormLab export/replay pilot.
