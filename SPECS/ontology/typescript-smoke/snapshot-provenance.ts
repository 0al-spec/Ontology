import {
  SourceSnapshotOriginSchema,
  DirectObservationOriginSchema,
  OperatorSnapshotOriginSchema,
} from "../packages/events-core/versions/0.2.0/generated/schemas";
import type { InstanceGraph, InstanceNode, SnapshotProvenanceAuthority } from "../instance-graph/provenance/generated/instance-graph";

function requireValue(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}
const source = { $type: "eventcore:SourceSnapshotOrigin", originKey: "s1", extractionMethod: "reviewed-extraction-v1" };
const direct = { $type: "eventcore:DirectObservationOrigin", originKey: "d1", observerKey: "observer", artifactRef: "fixture:frame", artifactDigest: "sha256:example", observedAt: 0, clockKey: "ticks" };
const operator = { $type: "eventcore:OperatorSnapshotOrigin", originKey: "o1", operatorKey: "operator", rationale: "Explicit operator-supplied state." };
for (const [schema, value] of [
  [SourceSnapshotOriginSchema, source], [DirectObservationOriginSchema, direct], [OperatorSnapshotOriginSchema, operator],
] as const) {
  requireValue(schema.safeParse(value).success, "Declared origin shape must parse.");
  for (const key of Object.keys(value)) {
    const missing = Object.fromEntries(Object.entries(value).filter(([name]) => name !== key));
    requireValue(!schema.safeParse(missing).success, "Required origin field disappeared: " + key);
  }
}
requireValue(!OperatorSnapshotOriginSchema.safeParse(source).success, "Source and operator origin discriminators must remain distinct.");
requireValue(!DirectObservationOriginSchema.safeParse({ ...direct, observedAt: "zero" }).success, "Capture time must reject a string.");
requireValue(!OperatorSnapshotOriginSchema.safeParse({ ...operator, rationale: false }).success, "Operator rationale must reject a boolean.");

// @ts-expect-error Direct capture requires an observer identity.
const missingObserver: InstanceNode = { id: "d", type: "eventcore:DirectObservationOrigin", fields: { originKey: "d", artifactRef: "f", artifactDigest: "h", observedAt: 0, clockKey: "ticks" } };
// @ts-expect-error Operator supply requires an explicit rationale.
const missingRationale: InstanceNode = { id: "o", type: "eventcore:OperatorSnapshotOrigin", fields: { originKey: "o", operatorKey: "person" } };
// @ts-expect-error The new graph profile cannot silently advertise the legacy ontology revision.
const oldVersion: InstanceGraph["ontology"]["version"] = "0.1.0";
// @ts-expect-error Source review is not an admitted snapshot capability.
const inventedCapability: SnapshotProvenanceAuthority["grants"][number]["capabilities"][number] = "review-source";
// @ts-expect-error Confirmation binds both the snapshot and its actual typed origin.
const missingOrigin: SnapshotProvenanceAuthority["confirmations"][number] = { snapshotId: "s", authorityKey: "a", rationale: "r" };
void missingObserver; void missingRationale; void oldVersion; void inventedCapability; void missingOrigin;

// Object/type shapes only. Cross-input graph hashes, authority scope, reference
// identity and origin/enrichment admission require validate-instances. Neither
// generated objects nor the profile establish factual truth or authenticity.
