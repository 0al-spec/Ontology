import type { Child } from "./generated/types";
import { ChildSchema } from "./generated/schemas";

const valid: Child = { $type: "consumer:Child", id: "one", serial: "s-1", trace: "evidence" };
// @ts-expect-error A source-bound protocol requires trace.
const missingTrace: Child = { $type: "consumer:Child", id: "one", serial: "s-1" };
// @ts-expect-error The protocol also requires id.
const missingId: Child = { $type: "consumer:Child", serial: "s-1", trace: "evidence" };
// @ts-expect-error Protocol fields have the current SDK's string contract.
const wrongTrace: Child = { ...valid, trace: 42 };
void missingTrace;
void missingId;
void wrongTrace;

const parsed = ChildSchema.parse(valid);
if (parsed.id !== "one" || parsed.trace !== "evidence") throw new Error("Protocol fields were lost");
if (ChildSchema.safeParse({ ...valid, trace: undefined }).success) throw new Error("Missing trace was accepted");
if (ChildSchema.safeParse({ ...valid, id: undefined }).success) throw new Error("Missing identity was accepted");
if (ChildSchema.safeParse({ ...valid, trace: 42 }).success) throw new Error("Invalid trace was accepted");
if ("auditLink" in parsed || "kind" in parsed) throw new Error("Declaration metadata became an instance field");
