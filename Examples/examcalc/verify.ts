import intent from "./intent.json";
import { classes } from "./generated/refs";
import { relationDefinitions } from "./generated/relations";
import type { SetAllowedFunctions } from "./generated/types";
import { SetAllowedFunctionsSchema } from "./generated/schemas";
import { Classroom, type FunctionList, type Operation } from "./calculator";
import { verifyHandoffs } from "./verify-handoff";

function assert(condition: unknown, message: string): asserts condition {
  if (!condition) throw new Error(message);
}
async function rejects(run: () => unknown, reason: string) {
  try { await run(); } catch (error) {
    if (error instanceof Error && error.message.includes(reason)) return;
    throw error;
  }
  throw new Error("Expected rejection: " + reason);
}

const add = { $type: classes.CalculatorFunction.alias, id: "add" } satisfies Operation;
const sine = { $type: classes.CalculatorFunction.alias, id: "sine" } satisfies Operation;
const operations = new Map([add, sine].map(op => [op.id, op]));
function list(id: string, ...members: Operation[]): FunctionList {
  return { $type: classes.AllowedFunctionSet.alias, id, members };
}

function checkSine(room: Classroom, exam: string, selected: string | null, applied: string | null,
  expected: "available" | "unavailable" | "unknown") {
  const sets = room.observeSets(exam);
  let calls = 0;
  const result = room.use(exam, sine, () => { calls++; return Math.sin(0); });
  const observation = JSON.stringify({ exam, ...sets, sine: result, calls });
  assert(sets.selected === selected && sets.applied === applied && result.status === expected, observation);
  assert(calls === (expected === "available" ? 1 : 0), observation);
  if (result.status === "available") assert(result.value === 0, observation);
  console.log(observation);
}

async function verify() {
  const wrongType: SetAllowedFunctions = {
    $type: classes.SetAllowedFunctions.alias,
    // @ts-expect-error The selection must point to a function set, not an exam.
    functions: { target: classes.Exam.alias, locator: "arithmetic" },
  };
  assert(!SetAllowedFunctionsSchema.safeParse(wrongType).success, "An exam was accepted as a function set");
  const membership = relationDefinitions.find(relation => relation.id === "includesFunction");
  assert(membership?.domain === classes.AllowedFunctionSet.alias && membership.range === classes.CalculatorFunction.alias
    && !("action" in membership), "Set membership must link a set to a function without an action");
  const sets = [
    list("basic", add), list("scientific", add, sine), list("basic-copy", add), list("none"),
    list("arithmetic-plus", add, sine),
  ];
  const room = new Classroom(["arithmetic", "trigonometry", "empty", "unassigned"], sets);
  checkSine(room, "arithmetic", null, null, "unknown");
  // Assign both exams before applying either selection.
  await room.setAllowedFunctions("arithmetic", "basic");
  checkSine(room, "arithmetic", "basic", null, "unknown");
  await room.setAllowedFunctions("trigonometry", "scientific");
  await room.applyAllowedFunctions("arithmetic", "basic");
  checkSine(room, "arithmetic", "basic", "basic", "unavailable");
  await room.applyAllowedFunctions("trigonometry", "scientific");
  for (const { exam, operation, expected } of intent.examples) {
    const fn = operations.get(operation);
    assert(fn, "Unimplemented example operation: " + operation);
    let calls = 0;
    const result = room.use(exam, fn, () => { calls++; return fn.id === "sine" ? Math.sin(0) : 2 + 3; });
    assert(result.status === expected, exam + "/" + operation + ": " + result.status + " != " + expected);
    assert(calls === (expected === "available" ? 1 : 0), "Unexpected invocation count");
    if (result.status === "available") assert(result.value === (fn.id === "sine" ? 0 : 5), "Wrong result");
  }
  for (const wrong of ["scientific", "basic-copy"]) {
    await rejects(() => room.applyAllowedFunctions("arithmetic", wrong), "Different set selected");
  }
  assert(room.handOutFor("trigonometry")?.functions === "scientific", "Failed apply switched the tablet");
  assert(room.use("arithmetic", sine, () => 0).status === "unavailable", "Failed apply changed arithmetic");
  await rejects(() => room.setAllowedFunctions("arithmetic", "missing"), "Unknown function set");
  await room.applyAllowedFunctions("arithmetic", "basic"); // The previous selection survived a failed assignment.
  await rejects(() => room.applyAllowedFunctions("unassigned", "none"), "No set selected");
  assert(room.use("unassigned", sine, () => 0).status === "unknown", "Missing assignment became a denial");
  await room.setAllowedFunctions("empty", "none");
  await room.applyAllowedFunctions("empty", "none");
  assert(room.use("empty", sine, () => 0).status === "unavailable", "Empty set became unknown");

  checkSine(room, "trigonometry", "scientific", "scientific", "available");
  await room.setAllowedFunctions("arithmetic", "arithmetic-plus");
  checkSine(room, "arithmetic", "arithmetic-plus", "basic", "unknown");
  checkSine(room, "trigonometry", "scientific", "scientific", "available");
  await room.applyAllowedFunctions("arithmetic", "arithmetic-plus");
  checkSine(room, "arithmetic", "arithmetic-plus", "arithmetic-plus", "available");
  checkSine(room, "trigonometry", "scientific", "scientific", "available");

  const namedExam = "Матан, а также геометрия";
  const namedRoom = new Classroom([namedExam], [list("Всё", add), list("Все", add)]);
  await namedRoom.setAllowedFunctions(namedExam, "Всё");
  await rejects(() => namedRoom.applyAllowedFunctions(namedExam, "Все"), "Different set selected");
  await namedRoom.applyAllowedFunctions(namedExam, "Всё");
  assert(namedRoom.handOutFor(namedExam)?.functions === "Всё", "Exam and set identifiers must be preserved");
  await verifyHandoffs(sets);
  console.log("Examcalc: exam outcomes, handoff and missing/empty selections passed.");
}

void verify();
