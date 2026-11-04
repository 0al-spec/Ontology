import intent from "./intent.json";
import { Classroom, type FunctionList } from "./calculator";
import { compileReading } from "./reading";

async function verifyFirstStudentPress(sets: readonly FunctionList[]) {
  if (intent.firstStudentPress.operation !== "sine") throw new Error("Unsupported student operation");
  let calls = 0;
  const studentRoom = new Classroom(intent.firstStudentPress.examples.map(example => example.exam), sets,
    operand => { calls++; return Math.sin(operand); });
  for (const example of intent.firstStudentPress.examples) {
    for (const step of compileReading(intent.agreedReading, example)) await studentRoom.execute(step);
    const tablet = studentRoom.handOutFor(example.exam);
    if (!tablet) throw new Error("Expected handoff for " + example.exam);
    calls = 0;
    const result = tablet.sin(intent.firstStudentPress.argument);
    if (result.status !== example.expected || calls !== example.calls
      || (result.status === "available" ? result.value : null) !== example.value) {
      throw new Error("First student press failed: " + JSON.stringify({ example, result, calls }));
    }
    console.log(JSON.stringify({ criterion: intent.firstStudentPress.id, exam: example.exam, result, calls }));
  }

  const defaultRoom = new Classroom(["trigonometry"], sets);
  for (const step of compileReading(intent.agreedReading, { exam: "trigonometry", functions: "scientific" })) {
    await defaultRoom.execute(step);
  }
  const defaultResult = defaultRoom.handOutFor("trigonometry")?.sin(Math.PI / 2);
  if (defaultResult?.status !== "available" || defaultResult.value !== 1) {
    throw new Error("Default sine must use the supplied operand: " + JSON.stringify(defaultResult));
  }
}

export async function verifyHandoffs(sets: readonly FunctionList[]) {
  await verifyFirstStudentPress(sets);

  let staleCalls = 0;
  const room = new Classroom(["arithmetic", "trigonometry"], sets,
    operand => { staleCalls++; return Math.sin(operand); });
  const steps = (exam: string, functions: string) => compileReading(intent.agreedReading, { exam, functions });
  const example = intent.tabletHandoff.sharedSetExample;
  const arithmetic = steps("arithmetic", "basic");
  const trigonometry = steps("trigonometry", "scientific");
  const shared = steps(example.activeExam, example.functions);
  const revised = steps("trigonometry", "basic-copy");

  function expectHandoff(moment: string, attendingExam: string, expectedSet: string | null) {
    const actual = room.handOutFor(attendingExam);
    const matches = expectedSet === null
      ? actual === null
      : actual?.tablet === "tablet-calculator" && actual.exam === attendingExam && actual.functions === expectedSet;
    if (!matches) throw new Error(moment + ": expected " + expectedSet + ", got " + JSON.stringify(actual));
    console.log(JSON.stringify({ criterion: intent.tabletHandoff.id, moment, attendingExam, handoff: actual }));
  }

  expectHandoff("Before preparation", "arithmetic", null);
  await room.execute(arithmetic[0]);
  expectHandoff("Selected only", "arithmetic", null);
  await room.execute(trigonometry[0]);
  await room.execute(trigonometry[1]);
  expectHandoff("Other exam active", "arithmetic", null);
  await room.execute(arithmetic[1]);
  expectHandoff("Matching exam and set", "arithmetic", "basic");
  const issued = room.handOutFor("arithmetic");
  if (!issued) throw new Error("Expected arithmetic tablet");

  // Activate basic for trigonometry. The earlier application of basic for
  // arithmetic still exists in the per-exam history.
  await room.execute(shared[0]);
  await room.execute(shared[1]);
  const stale = issued.sin(0);
  if (stale.status !== "unknown" || staleCalls !== 0) throw new Error("Issued tablet accepted another exam with the same set");
  if (issued.exam !== "arithmetic" || issued.functions !== "basic") throw new Error("Handoff snapshot changed");
  for (const { attendingExam, expectedHandoff } of example.visits) {
    expectHandoff("Shared set active for " + example.activeExam, attendingExam, expectedHandoff);
  }

  // basic-copy has the same members but a different identity from basic.
  const sharedTablet = room.handOutFor("trigonometry");
  if (!sharedTablet) throw new Error("Expected trigonometry tablet");
  await room.execute(revised[0]);
  expectHandoff("Superseded set still active", "trigonometry", null);
  const superseded = sharedTablet.sin(0);
  if (superseded.status !== "unknown" || staleCalls !== 0) throw new Error("Issued tablet accepted a superseded selection");
  await room.execute(revised[1]);
  expectHandoff("Revised selection activated", "trigonometry", "basic-copy");
  const changed = sharedTablet.sin(0);
  if (changed.status !== "unknown" || staleCalls !== 0) throw new Error("Issued tablet accepted a different active set");
}
