// Checked against freshly generated files by tools/typescript-smoke.sh.
import { ActionRelationshipRecordSchema } from "./generated/validators";
import { trigger, type ActionRelationship, type ActionRelationshipRecord, type Actor, type Entity } from "./generated/relations";
import type { Appoint, Cancel, Person } from "./generated/types";

const ivanRef = { $type: "pilot:Person", id: "ivan" } satisfies Person;
const anna = { $type: "pilot:Person", id: "anna" } satisfies Person;
const appoint: Appoint = { $type: "pilot:Appoint" };
const cancel: Cancel = { $type: "pilot:Cancel" };

const cast = { relation: "pilot:CastAppointment", subject: ivanRef, action: appoint, object: anna } satisfies ActionRelationshipRecord;
const crew = { ...cast, relation: "pilot:CrewAppointment" } satisfies ActionRelationshipRecord;
const cancellation = { ...cast, relation: "pilot:CastCancellation", action: cancel } satisfies ActionRelationshipRecord;

// @ts-expect-error Cancel belongs to CastCancellation; CastAppointment requires Appoint.
const swapped = { ...cast, action: cancel } satisfies ActionRelationshipRecord;

// A consumer can narrow the relationship and obtain its specific action type.
export function readAction(relationship: ActionRelationshipRecord): Appoint | Cancel {
  if (relationship.relation === "pilot:CastCancellation") {
    return relationship.action satisfies Cancel;
  }
  return relationship.action satisfies Appoint;
}

// Model the consumer boundary: JSON bytes yield an unknown value until checked.
function parseWireRecord(value: unknown) {
  const wire: unknown = JSON.parse(JSON.stringify(value));
  return ActionRelationshipRecordSchema.safeParse(wire);
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
expectFieldError({ relation: cast.relation, subject: ivanRef, object: anna }, "action");
expectFieldError({ ...cast, subject: cancel }, "subject.$type", "pilot:Person");
expectFieldError({ ...cast, object: cancel }, "object.$type", "pilot:Person");

type IdentifiedPerson = Person & Entity;

const casting: { performer?: string } = {};
const calls: IdentifiedPerson[] = [];
const ivan = {
  ...ivanRef,
  run(action, object) {
    calls.push(this);
    if (action !== appoint || object !== anna) throw new Error("Unexpected appointment operands");
    casting.performer = object.id;
  },
} satisfies Person & Actor<Appoint, IdentifiedPerson>;

const assignment = { ...cast, subject: ivan } satisfies ActionRelationship<"pilot:CastAppointment">;
const saved = parseWireRecord(assignment);
if (!saved.success) throw saved.error;
if ("run" in saved.data.subject || casting.performer !== undefined || calls.at(0) !== undefined) {
  throw new Error("Reading the appointment must produce only its record");
}
trigger(assignment);
if (casting.performer !== anna.id || calls.length !== 1 || calls[0] !== ivan) {
  throw new Error("Expected Ivan to appoint Anna exactly once");
}

const completion = Promise.resolve();
if (trigger({ ...assignment, subject: { ...ivan, run: () => completion } }) !== completion) {
  throw new Error("An asynchronous actor's completion must reach the caller");
}

function rejectedExecutions(record: ActionRelationshipRecord, cancelOnly: IdentifiedPerson & Actor<Cancel, IdentifiedPerson>) {
  // @ts-expect-error An identified Person without run cannot perform this action.
  trigger({ ...assignment, subject: anna });
  // @ts-expect-error The subject must be capable of Appoint even though Cancel exists in the package.
  trigger({ ...assignment, subject: cancelOnly });
  // @ts-expect-error The named relationship binds Appoint.
  trigger({ ...assignment, action: cancel });
  // @ts-expect-error Stored records carry data and cannot be triggered.
  trigger(record);
  // @ts-expect-error Executing the action requires a particular object.
  trigger({ ...assignment, object: { $type: "pilot:Person" } });
}
