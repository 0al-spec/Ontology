import type { InstanceGraph, InstanceNode, InstanceEdge } from "../instance-graph/generated/instance-graph";

const candidate: InstanceNode = {
  id: "source-candidate",
  type: "eventcore:EventCandidate",
  fields: { candidateKey: "reported" },
};
const known: InstanceNode = {
  id: "known",
  type: "eventcore:StateObservation",
  fields: { availability: "known" },
};
const edge: InstanceEdge = {
  relation: "eventcore:candidateBeforeObservation",
  from: { graphKey: "example", revisionKey: "r1", nodeId: candidate.id, type: "eventcore:EventCandidate" },
  to: { graphKey: "example", revisionKey: "r1", nodeId: known.id, type: "eventcore:StateObservation" },
};

// @ts-expect-error Mandatory intervalStart cannot disappear from a record's fields.
const missingInterval: InstanceNode = { id: "r", type: "eventcore:RecordedEvent", fields: { recordKey: "r", intervalFinish: 1, clockKey: "ticks" } };

// @ts-expect-error Direct record snapshots cannot be unknown StateObservations.
const relation: InstanceEdge = {
  relation: "eventcore:recordBeforeSnapshot",
  from: { graphKey: "example", revisionKey: "r1", nodeId: "r", type: "eventcore:RecordedEvent" },
  to: { graphKey: "example", revisionKey: "r1", nodeId: "unknown", type: "eventcore:StateObservation" },
};

// This envelope is shape-typed only; validate-instances rejects the missing
// candidate episode and the known observation without a snapshot.
const shapeOnly: Pick<InstanceGraph, "nodes" | "edges"> = { nodes: [candidate, known], edges: [edge] };
void shapeOnly;
void relation;
void missingInterval;
