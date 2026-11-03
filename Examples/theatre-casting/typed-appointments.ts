// Checked against freshly generated files by tools/typescript-smoke.sh.
import { ActionRelationshipSchema } from "./generated/validators";
import type { ActionRelationship } from "./generated/relations";
import type { Appoint, Cancel, Person } from "./generated/types";

const ivan: Person = { $type: "pilot:Person", id: "ivan" };
const anna: Person = { $type: "pilot:Person", id: "anna" };
const appoint: Appoint = { $type: "pilot:Appoint" };
const cancel: Cancel = { $type: "pilot:Cancel" };

const cast = { relation: "pilot:CastAppointment", subject: ivan, action: appoint, object: anna } satisfies ActionRelationship;
const crew = { ...cast, relation: "pilot:CrewAppointment" } satisfies ActionRelationship;
const cancellation = { ...cast, relation: "pilot:CastCancellation", action: cancel } satisfies ActionRelationship;

// @ts-expect-error Cancel belongs to CastCancellation; CastAppointment requires Appoint.
const swapped = { ...cast, action: cancel } satisfies ActionRelationship;

// A consumer can narrow the relationship and obtain its specific action type.
export function readAction(relationship: ActionRelationship): Appoint | Cancel {
  if (relationship.relation === "pilot:CastCancellation") {
    return relationship.action satisfies Cancel;
  }
  return relationship.action satisfies Appoint;
}

// Model the consumer boundary: JSON bytes yield an unknown value until checked.
function parseWireRecord(value: unknown) {
  const wire: unknown = JSON.parse(JSON.stringify(value));
  return ActionRelationshipSchema.safeParse(wire);
}

for (const record of [cast, crew, cancellation]) {
  const parsed = parseWireRecord(record);
  if (!parsed.success) throw parsed.error;
  if (readAction(parsed.data).$type !== record.action.$type) {
    throw new Error("Parsed action differs from the recorded action");
  }
}

function expectFieldError(record: unknown, path: string, expected?: string) {
  const parsed = parseWireRecord(record);
  if (parsed.success) throw new Error(`Expected rejection at ${path}`);
  const found = parsed.error.issues.some(issue =>
    issue.path.join(".") === path &&
    (expected === undefined || (issue.code === "invalid_value" && issue.values.includes(expected)))
  );
  if (!found) throw parsed.error;
}

expectFieldError(swapped, "action.$type", "pilot:Appoint");
expectFieldError({ ...cancellation, action: appoint }, "action.$type", "pilot:Cancel");
expectFieldError({ ...cast, relation: "pilot:UnknownRelation" }, "relation");
expectFieldError({ relation: cast.relation, subject: ivan, object: anna }, "action");
expectFieldError({ ...cast, subject: cancel }, "subject.$type", "pilot:Person");
expectFieldError({ ...cast, object: cancel }, "object.$type", "pilot:Person");
