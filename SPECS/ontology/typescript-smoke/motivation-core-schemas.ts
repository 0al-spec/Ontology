import {
  MotiveSchema, MotivationHypothesisSchema, OperatorMotivationSupportSchema,
  ReviewMotivationSchema, RejectMotivationSchema, toJsonSchemaFor,
} from "../packages/motivation-core/generated/schemas";
import { parseOntologyEntity } from "../packages/motivation-core/generated/validators";
import type { Motive, MotivationHypothesis } from "../packages/motivation-core/generated/types";

function requireValue(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}
const motive = { $type: "motivcore:Motive", motiveKey: "external-influence", description: "An external influence prompted the chosen actor." };
const hypothesis = { $type: "motivcore:MotivationHypothesis", hypothesisKey: "reported-contribution", contributionKind: "action" };
const support = { $type: "motivcore:OperatorMotivationSupport", supportKey: "operator-note", rationale: "Explicit uncited interpretation." };
for (const [schema, value] of [
  [MotiveSchema, motive], [MotivationHypothesisSchema, hypothesis], [OperatorMotivationSupportSchema, support],
] as const) {
  requireValue(schema.safeParse(value).success, "Declared motivation object must parse.");
  for (const key of Object.keys(value)) {
    const missing = Object.fromEntries(Object.entries(value).filter(([name]) => name !== key));
    requireValue(!schema.safeParse(missing).success, "Required motivation field disappeared: " + key);
  }
}
requireValue(MotiveSchema.safeParse({ ...motive, label: "Physical prompting reason" }).success, "Label must remain optional.");
requireValue(!MotiveSchema.safeParse({ ...motive, description: 1 }).success, "Reason description must reject a number.");
requireValue(!MotivationHypothesisSchema.safeParse({ ...hypothesis, contributionKind: false }).success, "Contribution kind must reject a boolean.");
requireValue(!OperatorMotivationSupportSchema.safeParse(motive).success, "Reason content is distinct from operator evidence.");
requireValue(MotivationHypothesisSchema.safeParse({ ...hypothesis, contributionKind: "omission" }).success, "Omission object shape must parse.");
requireValue(parseOntologyEntity(MotiveSchema.parse(motive)).$type === "motivcore:Motive", "Generic dispatch must retain motive identity.");
for (const [schema, value] of [
  [ReviewMotivationSchema, { $type: "motivcore:ReviewMotivation" }],
  [RejectMotivationSchema, { $type: "motivcore:RejectMotivation" }],
] as const) {
  requireValue(schema.safeParse(value).success, "Workflow command discriminator must parse.");
}
const schema = toJsonSchemaFor(MotivationHypothesisSchema);
for (const field of ["truthState", "actorId", "eventId", "beforeSnapshot", "afterSnapshot", "delta"]) {
  requireValue(!Object.hasOwn(schema.properties ?? {}, field), "Do not duplicate derived scope/state fields: " + field);
}
// The generated object schema checks primitive shape, not contribution enums.
requireValue(MotivationHypothesisSchema.safeParse({ ...hypothesis, contributionKind: "unresolved-label" }).success,
  "This smoke must not imply that the generic compiler implements motivation enum admission.");
// @ts-expect-error A reason requires its description.
const missingReason: Motive = { $type: "motivcore:Motive", motiveKey: "reason" };
// @ts-expect-error An attribution requires an explicitly interpreted contribution kind.
const missingKind: MotivationHypothesis = { $type: "motivcore:MotivationHypothesis", hypothesisKey: "h" };
void missingReason; void missingKind;

// Object checks only. Role ownership, source meaning, broad Entity attribution,
// scope/timing and actual consequence availability remain manual draft policies.
