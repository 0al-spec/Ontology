import { classes, relations } from "./generated/refs";
import { trigger, type Actor, type Entity } from "./generated/relations";
import type {
  AllowedFunctionSet, ApplyAllowedFunctions, Calculator, CalculatorFunction, Exam, Instructor, SetAllowedFunctions,
} from "./generated/types";
import type { Step } from "./reading";

type ExamInstance = Exam & Entity;
type SetInstance = AllowedFunctionSet & Entity;
export type Operation = CalculatorFunction & Entity;
export type FunctionList = SetInstance & { readonly members: readonly Operation[] };

function lookup<T>(table: ReadonlyMap<string, T>, key: unknown, kind: string): T {
  const value = typeof key === "string" ? table.get(key) : undefined;
  if (!value) throw new Error("Unknown " + kind + ": " + String(key));
  return value;
}

export class Classroom {
  private readonly exams = new Map<string, ExamInstance>();
  private readonly sets: ReadonlyMap<string, FunctionList>;
  private readonly applied = new Map<string, SetInstance>();

  constructor(examIds: readonly string[], sets: readonly FunctionList[]) {
    for (const id of examIds) this.exams.set(id, { $type: classes.Exam.alias, id });
    this.sets = new Map(sets.map(set => [set.id, set]));
  }

  private readonly instructor = {
    $type: classes.Instructor.alias, id: "instructor",
    run: (action, exam) => {
      lookup(this.sets, action.functions.locator, "function set");
      this.exams.set(exam.id, { ...exam, allowedFunctions: action.functions });
    },
  } satisfies Instructor & Actor<SetAllowedFunctions, ExamInstance>;

  private calculator: Calculator & Actor<ApplyAllowedFunctions, SetInstance> = {
    $type: classes.Calculator.alias, id: "tablet-calculator",
    run: (action, functions) => {
      const exam = lookup(this.exams, action.exam.locator, "exam");
      if (!exam.allowedFunctions) throw new Error("No set selected for " + exam.id);
      if (exam.allowedFunctions.locator !== functions.id) throw new Error("Different set selected for " + exam.id);
      this.calculator = {
        ...this.calculator,
        activeExam: action.exam,
        activeFunctions: { target: functions.$type, locator: functions.id },
      };
      this.applied.set(exam.id, functions);
    },
  };

  async execute(step: Step): Promise<void> {
    const exam = lookup(this.exams, step.exam, "exam");
    const functions = lookup(this.sets, step.functions, "function set");
    if (step.relation === relations.setsFunctionsForExam.alias) {
      await trigger({ relation: step.relation, subject: this.instructor, object: exam,
        action: { $type: classes.SetAllowedFunctions.alias, functions: { target: functions.$type, locator: functions.id } } });
    } else {
      await trigger({ relation: step.relation, subject: this.calculator, object: functions,
        action: { $type: classes.ApplyAllowedFunctions.alias, exam: { target: exam.$type, locator: exam.id } } });
    }
  }

  observeSets(examId: string): { selected: string | null; applied: string | null } {
    const exam = lookup(this.exams, examId, "exam");
    const selected = exam.allowedFunctions
      ? lookup(this.sets, exam.allowedFunctions.locator, "function set").id
      : null;
    return { selected, applied: this.applied.get(exam.id)?.id ?? null };
  }

  handOutFor(attendingExam: string): { tablet: string; exam: string; functions: string } | null {
    const { id, activeExam, activeFunctions } = this.calculator;
    if (!activeExam || !activeFunctions) return null;
    const exam = lookup(this.exams, activeExam.locator, "exam");
    const functions = lookup(this.sets, activeFunctions.locator, "function set");
    if (exam.id !== attendingExam || exam.allowedFunctions?.locator !== functions.id) return null;
    return { tablet: id, exam: exam.id, functions: functions.id };
  }

  use(examId: string, operation: Operation, calculate: () => number):
    { status: "available"; value: number } | { status: "unavailable" | "unknown" } {
    const exam = lookup(this.exams, examId, "exam");
    const set = this.applied.get(exam.id);
    if (!set || exam.allowedFunctions?.locator !== set.id) return { status: "unknown" };
    const { members } = lookup(this.sets, set.id, "function set");
    if (!members.some(member => member.id === operation.id)) return { status: "unavailable" };
    return { status: "available", value: calculate() };
  }
}
