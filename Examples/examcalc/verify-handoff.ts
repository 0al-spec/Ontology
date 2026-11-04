import intent from "./intent.json";
import { Classroom, type FunctionList } from "./calculator";
import { compileReading } from "./reading";

export async function verifyHandoffs(sets: readonly FunctionList[]) {
  const room = new Classroom(["arithmetic", "trigonometry"], sets);
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

  // Activate basic for trigonometry. The earlier application of basic for
  // arithmetic still exists in the per-exam history.
  await room.execute(shared[0]);
  await room.execute(shared[1]);
  for (const { attendingExam, expectedHandoff } of example.visits) {
    expectHandoff("Shared set active for " + example.activeExam, attendingExam, expectedHandoff);
  }

  // basic-copy has the same members but a different identity from basic.
  await room.execute(revised[0]);
  expectHandoff("Superseded set still active", "trigonometry", null);
  await room.execute(revised[1]);
  expectHandoff("Revised selection activated", "trigonometry", "basic-copy");
}
