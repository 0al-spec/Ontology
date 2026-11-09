import type { Base } from "./base-generated/types";
import type { $OntologyFoundationInstance, Child, FromT, Parent, T } from "./generated/types";
import { ChildActionSchema, ChildSchema } from "./generated/schemas";
import { ActionRelationshipRecordSchema } from "./generated/validators";

const child: Child = {
  $type: "sample:Child",
  serial: "one",
  related: { target: "canonical:Base", locator: "other" },
};
const parentShape: Parent<string> = child;
const sharedShape: Base<string> = child;
type DomainEntity = $OntologyFoundationInstance<"ontology://ontology.foundation/0.2.0/classes/DomainEntity">;
type FoundationAction = $OntologyFoundationInstance<"ontology://ontology.foundation/0.2.0/classes/Action">;
const foundationBase: DomainEntity = child;
// @ts-expect-error The verified foundation base is DomainEntity, not Action.
const wrongFoundation: FoundationAction = child;
void parentShape;
void sharedShape;
void foundationBase;
void wrongFoundation;
const fromT: FromT = { $type: "sample:FromT" };
const tShape: T<string> = fromT;
void tShape;

// @ts-expect-error inherited required fields cannot be omitted
const missing: Child = { $type: "sample:Child" };
// @ts-expect-error concrete default types retain the exact discriminator
const wrongType: Child = { ...child, $type: "sample:Parent" };
// @ts-expect-error inherited references preserve their original target identity
const wrongReference: Child = { ...child, related: { target: "sample:Parent", locator: "x" } };
void missing;
void wrongType;
void wrongReference;

if (!ChildSchema.safeParse(child).success) throw new Error("Valid child was rejected");
if (ChildSchema.safeParse({ $type: "sample:Child" }).success) throw new Error("Missing inherited fields were accepted");
if (ChildSchema.safeParse({ ...child, related: { target: "sample:Parent", locator: "x" } }).success) {
  throw new Error("Wrong inherited reference target was accepted");
}

const relationship = {
  relation: "sample:acts",
  subject: { $type: "sample:Parent", serial: "one", related: child.related },
  action: { $type: "sample:ChildAction", id: "action", trace: "evidence" },
  object: child,
} as const;
if (ChildActionSchema.safeParse({ $type: "sample:ChildAction" }).success) {
  throw new Error("Class schema accepted an action without the inherited protocol field");
}
if (ChildActionSchema.safeParse({ $type: "sample:ChildAction", trace: "evidence" }).success) {
  throw new Error("Class schema accepted an action without its inherited identity");
}
const parsedAction = ChildActionSchema.parse(relationship.action);
if (parsedAction.trace !== "evidence") throw new Error("Class schema discarded the inherited protocol field");
if (!ActionRelationshipRecordSchema.safeParse(relationship).success) throw new Error("Valid relationship was rejected");
if (ActionRelationshipRecordSchema.safeParse({ ...relationship, action: { $type: "sample:ChildAction" } }).success) {
  throw new Error("Inherited protocol obligation was not checked");
}
if (ActionRelationshipRecordSchema.safeParse({ ...relationship, action: { ...relationship.action, note: undefined } }).success) {
  throw new Error("Inherited optional field accepted undefined in a JSON record");
}
