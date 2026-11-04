import intent from "./intent.json";
import { classes } from "./generated/refs";
import { relationDefinitions } from "./generated/relations";
import type { SetAllowedFunctions } from "./generated/types";
import { SetAllowedFunctionsSchema } from "./generated/schemas";
import { Classroom, type FunctionList, type Operation } from "./calculator";
import { compileReading } from "./reading";

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
  const room = new Classroom(["arithmetic", "trigonometry", "empty", "unassigned"], [
    list("basic", add), list("scientific", add, sine), list("basic-copy", add), list("none"),
  ]);
  const read = (exam: string, functions: string) => compileReading(intent.agreedReading, { exam, functions });
  const arithmetic = read("arithmetic", "basic"), trigonometry = read("trigonometry", "scientific");
  // Assign BOTH exams before applying either selection. A single "last set" cannot satisfy this.
  for (const step of [arithmetic[0], trigonometry[0], arithmetic[1], trigonometry[1]]) await room.execute(step);
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
  assert(room.use("arithmetic", sine, () => 0).status === "unavailable", "Failed apply changed arithmetic");
  await rejects(() => room.execute({ ...arithmetic[0], functions: "missing" }), "Unknown function set");
  await room.execute(arithmetic[1]); // The previous selection survived a failed assignment.
  await rejects(() => room.execute(read("unassigned", "none")[1]), "No set selected");
  assert(room.use("unassigned", sine, () => 0).status === "unknown", "Missing assignment became a denial");
  for (const step of read("empty", "none")) await room.execute(step);
  assert(room.use("empty", sine, () => 0).status === "unavailable", "Empty set became unknown");

  const context = { exam: "unused", functions: "unused" };
  const named = compileReading("Преподаватель задаёт для экзамена «arithmetic» набор разрешённых функций «basic», а калькулятор применяет этот набор.", context);
  assert(named.every(step => step.exam === "arithmetic" && step.functions === "basic"), "Antecedent binding lost");
  await rejects(() => compileReading("Калькулятор применяет этот набор.", context), "no preceding selection");
  await rejects(() => compileReading("Экзамен требует профиль.", context), "Expected the instructor");
  await rejects(() => compileReading(intent.agreedReading.replace("калькулятор применяет", "экзамен применяет"), context), "Expected the calculator");
  console.log("Examcalc: two exam outcomes, same-set identity, missing/empty input and sentence controls passed.");
}

void verify();
