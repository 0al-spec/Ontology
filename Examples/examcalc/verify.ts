import intent from "./intent.json";
import { classes } from "./generated/refs";
import { relationDefinitions } from "./generated/relations";
import type { SetAllowedFunctions } from "./generated/types";
import { SetAllowedFunctionsSchema } from "./generated/schemas";
import { Classroom, type FunctionList, type Operation } from "./calculator";
import { compileReading } from "./reading";
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
  const read = (exam: string, functions: string) => compileReading(intent.agreedReading, { exam, functions });
  const arithmetic = read("arithmetic", "basic"), trigonometry = read("trigonometry", "scientific");
  checkSine(room, "arithmetic", null, null, "unknown");
  // Assign both exams before applying either selection.
  await room.execute(arithmetic[0]);
  checkSine(room, "arithmetic", "basic", null, "unknown");
  await room.execute(trigonometry[0]);
  await room.execute(arithmetic[1]);
  checkSine(room, "arithmetic", "basic", "basic", "unavailable");
  await room.execute(trigonometry[1]);
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
    await rejects(() => room.execute({ ...arithmetic[1], functions: wrong }), "Different set selected");
  }
  assert(room.handOutFor("trigonometry")?.functions === "scientific", "Failed apply switched the tablet");
  assert(room.use("arithmetic", sine, () => 0).status === "unavailable", "Failed apply changed arithmetic");
  await rejects(() => room.execute({ ...arithmetic[0], functions: "missing" }), "Unknown function set");
  await room.execute(arithmetic[1]); // The previous selection survived a failed assignment.
  await rejects(() => room.execute(read("unassigned", "none")[1]), "No set selected");
  assert(room.use("unassigned", sine, () => 0).status === "unknown", "Missing assignment became a denial");
  for (const step of read("empty", "none")) await room.execute(step);
  assert(room.use("empty", sine, () => 0).status === "unavailable", "Empty set became unknown");

  const change = read("arithmetic", "arithmetic-plus");
  checkSine(room, "trigonometry", "scientific", "scientific", "available");
  await room.execute(change[0]);
  checkSine(room, "arithmetic", "arithmetic-plus", "basic", "unknown");
  checkSine(room, "trigonometry", "scientific", "scientific", "available");
  await room.execute(change[1]);
  checkSine(room, "arithmetic", "arithmetic-plus", "arithmetic-plus", "available");
  checkSine(room, "trigonometry", "scientific", "scientific", "available");

  const context = { exam: "unused", functions: "unused" };
  const named = compileReading("Преподаватель задаёт для экзамена «arithmetic» набор разрешённых функций «basic», а калькулятор применяет этот набор.", context);
  assert(named.every(step => step.exam === "arithmetic" && step.functions === "basic"), "Antecedent binding lost");
  await rejects(() => compileReading("Калькулятор применяет этот набор.", context), "no preceding selection");
  await rejects(() => compileReading("Экзамен требует профиль.", context), "Expected the instructor");
  await rejects(() => compileReading(intent.agreedReading.replace("калькулятор применяет", "экзамен применяет"), context), "Expected the calculator");
  await verifyHandoffs(sets);
  console.log("Examcalc: exam outcomes, handoff, missing/empty input and sentence controls passed.");
}

void verify();
