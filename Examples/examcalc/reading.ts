import { relations } from "./generated/refs";

export type Selection = { readonly exam: string; readonly functions: string };
export type Step = Selection & {
  readonly relation: typeof relations.setsFunctionsForExam.alias | typeof relations.appliesFunctionSet.alias;
};

// Two domain sentence frames for the agent's proposed route. Unnamed operands
// come from the scenario; «names» can bind them in the first clause instead.
const setting = /^преподаватель задаёт для экзамена(?: «([^»]+)»)? набор разрешённых функций(?: «([^»]+)»)?$/iu;
const applying = /^калькулятор применяет этот набор$/iu;

export function compileReading(text: string, context: Selection): readonly [Step, Step] {
  const clauses = text.trim().replace(/\.$/u, "").split(/,\s*а\s+/iu);
  if (applying.test(clauses[0])) throw new Error("«этот набор» has no preceding selection");
  const assignment = setting.exec(clauses[0]);
  if (!assignment) throw new Error("Expected the instructor to set functions for an exam");
  if (clauses.length !== 2 || !applying.test(clauses[1])) {
    throw new Error("Expected the calculator to apply «этот набор»");
  }
  const antecedent = { exam: assignment[1] ?? context.exam, functions: assignment[2] ?? context.functions };
  return [
    { relation: relations.setsFunctionsForExam.alias, ...antecedent },
    { relation: relations.appliesFunctionSet.alias, ...antecedent },
  ];
}
