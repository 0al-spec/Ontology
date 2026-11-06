import { classes, relations } from "./generated/refs";
import { trigger, type Actor, type Entity } from "./generated/relations";
import type {
  AllowedFunctionSet, ApplyAllowedFunctions, Calculator, CalculatorFunction, Exam, Instructor, SetAllowedFunctions,
} from "./generated/types";

type ExamInstance = Exam & Entity;
type SetInstance = AllowedFunctionSet & Entity;
export type Operation = CalculatorFunction & Entity;
export type FunctionList = SetInstance & { readonly members: readonly Operation[] };
type Result = { status: "available"; value: number } | { status: "unavailable" | "unknown" };
type IssuedTablet = {
  tablet: string;
  exam: string;
  functions: string;
  sin: (operand: number) => Result;
};

function lookup<T>(table: ReadonlyMap<string, T>, key: unknown, kind: string): T {
  const value = typeof key === "string" ? table.get(key) : undefined;
  if (!value) throw new Error("Unknown " + kind + ": " + String(key));
  return value;
}

export class Classroom {
  private readonly exams = new Map<string, ExamInstance>();
  private readonly sets: ReadonlyMap<string, FunctionList>;

  constructor(examIds: readonly string[], sets: readonly FunctionList[], private readonly calculateSin = Math.sin) {
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
    },
  };

  async setAllowedFunctions(examId: string, setId: string): Promise<void> {
    const exam = lookup(this.exams, examId, "exam");
    const functions = lookup(this.sets, setId, "function set");
    await trigger({ relation: relations.setsFunctionsForExam.alias, subject: this.instructor, object: exam,
      action: { $type: classes.SetAllowedFunctions.alias, functions: { target: functions.$type, locator: functions.id } } });
  }

  async applyAllowedFunctions(examId: string, setId: string): Promise<void> {
    const exam = lookup(this.exams, examId, "exam");
    const functions = lookup(this.sets, setId, "function set");
    await trigger({ relation: relations.appliesFunctionSet.alias, subject: this.calculator, object: functions,
      action: { $type: classes.ApplyAllowedFunctions.alias, exam: { target: exam.$type, locator: exam.id } } });
  }

  observeSets(examId: string): { selected: string | null; active: string | null } {
    const exam = lookup(this.exams, examId, "exam");
    const selected = exam.allowedFunctions
      ? lookup(this.sets, exam.allowedFunctions.locator, "function set").id
      : null;
    return { selected, active: this.activeFunctionsFor(exam.id)?.id ?? null };
  }

  private activeFunctionsFor(examId: string): FunctionList | null {
    const { activeExam, activeFunctions } = this.calculator;
    if (activeExam?.locator !== examId || !activeFunctions) return null;
    return lookup(this.sets, activeFunctions.locator, "function set");
  }

  private readyFunctionsFor(examId: string): FunctionList | null {
    const functions = this.activeFunctionsFor(examId);
    if (!functions || this.exams.get(examId)?.allowedFunctions?.locator !== functions.id) return null;
    return functions;
  }

  handOutFor(attendingExam: string): IssuedTablet | null {
    const functions = this.readyFunctionsFor(attendingExam);
    if (!functions) return null;
    return {
      tablet: this.calculator.id,
      exam: attendingExam,
      functions: functions.id,
      sin: operand => {
        const current = this.readyFunctionsFor(attendingExam);
        if (current?.id !== functions.id) return { status: "unknown" };
        const sine: Operation = { $type: classes.CalculatorFunction.alias, id: "sine" };
        return this.evaluate(current, sine, () => this.calculateSin(operand));
      },
    };
  }

  use(examId: string, operation: Operation, calculate: () => number): Result {
    const exam = lookup(this.exams, examId, "exam");
    const functions = this.readyFunctionsFor(exam.id);
    if (!functions) return { status: "unknown" };
    return this.evaluate(functions, operation, calculate);
  }

  private evaluate(functions: FunctionList, operation: Operation, calculate: () => number): Result {
    if (!functions.members.some(member => member.id === operation.id)) return { status: "unavailable" };
    return { status: "available", value: calculate() };
  }
}
