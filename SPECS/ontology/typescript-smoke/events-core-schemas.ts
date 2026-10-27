import {
  CausalHypothesisSchema,
  DeltaSchema,
  EntitySchema,
  EventRegistrySchema,
  RecordedEventSchema,
  SourceAssertionSchema,
  StateObservationSchema,
  StateSnapshotSchema,
  toJsonSchemaFor,
} from "../packages/events-core/generated/schemas";
import { parseOntologyEntity } from "../packages/events-core/generated/validators";

function requireValue(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

function rejects(
  schema: { safeParse(value: unknown): { success: boolean } },
  value: unknown,
  message: string,
) {
  requireValue(!schema.safeParse(value).success, message);
}

const entity = EntitySchema.parse({
  $type: "eventcore:Entity",
  id: "storm",
  label: "Hurricane",
});
requireValue(entity.label === "Hurricane", "Arbitrary Entity label was lost.");

const registry = EventRegistrySchema.parse({
  $type: "eventcore:EventRegistry",
  registryKey: "synthetic-example",
  revisionKey: "revision-1",
});
requireValue(registry.revisionKey === "revision-1", "Registry revision was lost.");
rejects(EventRegistrySchema, { $type: "eventcore:EventRegistry", registryKey: "r" },
  "Registry revisionKey must be required.");

const record = RecordedEventSchema.parse({
  $type: "eventcore:RecordedEvent",
  recordKey: "movement",
  intervalStart: 0,
  intervalFinish: 5,
  clockKey: "ticks",
});
rejects(RecordedEventSchema, { ...record, intervalStart: "zero" },
  "RecordedEvent intervalStart must reject a string.");
rejects(RecordedEventSchema, {
  $type: "eventcore:RecordedEvent",
  recordKey: "movement",
  intervalFinish: 5,
  clockKey: "ticks",
}, "RecordedEvent intervalStart must be required.");

const snapshot = StateSnapshotSchema.parse({
  $type: "eventcore:StateSnapshot",
  schemaKey: "synthetic-location/v1",
  scopeKey: "episode-1",
  projectionKey: "location",
});
requireValue(snapshot.projectionKey === "location", "Snapshot projection was lost.");
rejects(StateSnapshotSchema, { ...snapshot, scopeKey: 1 },
  "Snapshot scopeKey must reject a number.");
const snapshotJsonSchema = toJsonSchemaFor(StateSnapshotSchema);
requireValue(!Object.hasOwn(snapshotJsonSchema.properties ?? {}, "complete"),
  "Snapshot must not reintroduce a redundant complete flag.");

const observation = StateObservationSchema.parse({
  $type: "eventcore:StateObservation",
  availability: "unknown",
});
requireValue(observation.availability === "unknown", "Unknown availability was lost.");
rejects(StateObservationSchema, { ...observation, availability: false },
  "Availability must reject a boolean rather than coerce it.");

const assertion = SourceAssertionSchema.parse({
  $type: "eventcore:SourceAssertion",
  sourceRef: "synthetic-letter",
  revisionKey: "revision-1",
  sourceDigest: "synthetic-digest",
  quote: "I parked.",
  startOffset: 0,
  endOffset: 9,
  speakerKey: "letter_1",
});
requireValue(assertion.speakerKey === "letter_1", "Source speaker must be preserved.");
rejects(SourceAssertionSchema, { ...assertion, endOffset: "nine" },
  "Source quote offsets must reject string values.");

const hypothesis = CausalHypothesisSchema.parse({
  $type: "eventcore:CausalHypothesis",
  profileRef: "bounded-r3",
});
requireValue(hypothesis.profileRef === "bounded-r3", "Causal profile was lost.");
const hypothesisJsonSchema = toJsonSchemaFor(CausalHypothesisSchema);
requireValue(!Object.hasOwn(hypothesisJsonSchema.properties ?? {}, "reviewStatus"),
  "Hypothesis review must use lifecycle metadata, not a free-form status field.");

const delta = DeltaSchema.parse({ $type: "eventcore:Delta", id: "delta-1" });
requireValue(parseOntologyEntity(delta).$type === "eventcore:Delta",
  "Generic entity parsing must dispatch the Delta discriminator.");
rejects(DeltaSchema, { $type: "eventcore:RecordedEvent" },
  "DeltaSchema must reject another entity discriminator.");

// These are object-shape checks. Relations (including registry membership,
// record snapshots, Delta ownership and hypothesis views) are not object fields.
// No graph-integrity, availability-enum, exact-diff or causality claim is made.
