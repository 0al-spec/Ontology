// Checked against freshly generated files by tools/typescript-smoke.sh.
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
