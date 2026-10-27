import {
  AttributionContextSchema,
  CertificateReferenceSchema,
  CitedSupportSchema,
  ConditionSchema,
  DeadlineSchema,
  GroundAssessmentSchema,
  OperatorSupportSchema,
  ProfileConsequenceCandidateSchema,
  ResponsibilityAssessmentSchema,
  ResponsibleRelationSchema,
  ResponseCandidateSchema,
  toJsonSchemaFor,
} from "../packages/responsibility-core/generated/schemas";
import { parseOntologyEntity } from "../packages/responsibility-core/generated/validators";

function requireValue(value: boolean, message: string) {
  if (!value) throw new Error(message);
}
function rejects(schema: { safeParse(value: unknown): { success: boolean } }, value: unknown, message: string) {
  requireValue(!schema.safeParse(value).success, message);
}

const relation = ResponsibleRelationSchema.parse({ $type: "respcore:ResponsibleRelation", relationKey: "claimed-duty" });
requireValue(relation.relationKey === "claimed-duty", "Relation identity was lost.");
rejects(ResponsibleRelationSchema, { $type: "respcore:ResponsibleRelation" }, "Relation key must be required.");

const context = AttributionContextSchema.parse({ $type: "respcore:AttributionContext", contextKey: "omission-view" });
requireValue(context.contextKey === "omission-view", "Context identity was lost.");
const condition = ConditionSchema.parse({ $type: "respcore:Condition", conditionKey: "normlab-r3:performed", meaningRef: "pinned-mapping" });
requireValue(condition.conditionKey === "normlab-r3:performed", "Condition identity was lost.");
rejects(ConditionSchema, { $type: "respcore:Condition", conditionKey: "normlab-r3:performed" }, "Condition meaning reference must be required.");

const uncited = OperatorSupportSchema.parse({ $type: "respcore:OperatorSupport", supportKey: "operator-1", rationale: "Explicit uncited assertion." });
requireValue(parseOntologyEntity(uncited).$type === "respcore:OperatorSupport", "Uncited assertion type must remain explicit.");
rejects(OperatorSupportSchema, { $type: "respcore:OperatorSupport", supportKey: "operator-1" }, "Uncited rationale must be required.");
rejects(OperatorSupportSchema, { ...uncited, rationale: false }, "Uncited rationale must be a string.");
const cited = CitedSupportSchema.parse({ $type: "respcore:CitedSupport", supportKey: "quoted-1" });
rejects(OperatorSupportSchema, cited, "A CitedSupport discriminator must not parse as OperatorSupport.");

const deadline = DeadlineSchema.parse({ $type: "respcore:Deadline", deadlineKey: "deadline-1", dueAt: 10, clockKey: "ticks" });
rejects(DeadlineSchema, { ...deadline, dueAt: "ten" }, "Deadline instant must reject strings.");
const ground = GroundAssessmentSchema.parse({ $type: "respcore:GroundAssessment", groundKey: "performance" });
requireValue(ground.groundKey === "performance", "Ground identity was lost.");
const groundJson = toJsonSchemaFor(GroundAssessmentSchema);
requireValue(!Object.hasOwn(groundJson.properties ?? {}, "truthState"), "Do not duplicate support-derived state.");

ResponsibilityAssessmentSchema.parse({ $type: "respcore:ResponsibilityAssessment", assessmentKey: "a1", mode: "omission" });
rejects(ResponsibilityAssessmentSchema, { $type: "respcore:ResponsibilityAssessment", assessmentKey: "a1" }, "Assessment mode is required.");
const certificate = CertificateReferenceSchema.parse({ $type: "respcore:CertificateReference", certificateKey: "c1", artifactRef: "external-certificate", artifactDigest: "synthetic-digest" });
rejects(CertificateReferenceSchema, { ...certificate, artifactDigest: 1 }, "Certificate artifact digest must be a string.");
ProfileConsequenceCandidateSchema.parse({ $type: "respcore:ProfileConsequenceCandidate", consequenceKey: "marker", symbolRef: "breachRecorded" });
ResponseCandidateSchema.parse({ $type: "respcore:ResponseCandidate", responseKey: "proposed-response" });

// These are object-shape checks, not responsibility graph admission. Relation
// cardinalities, enum strings, nonempty text, scope/meaning/polarity, human proof,
// source relevance and certificate execution remain consumer-owned.
