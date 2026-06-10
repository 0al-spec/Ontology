import { ExamSchema, toJsonSchemaFor } from "../packages/examcalc/generated/schemas";

const parsedExam = ExamSchema.parse({
  $type: "examcalc:Exam",
  id: "exam-2026-06-02",
  title: "Calculus final",
  durationMinutes: 120
});

const examJsonSchema = toJsonSchemaFor(ExamSchema);

if (parsedExam.$type !== "examcalc:Exam") {
  throw new Error("ExamSchema did not preserve the ontology type discriminator.");
}

if (examJsonSchema.type !== "object") {
  throw new Error("toJsonSchemaFor did not produce an object JSON Schema.");
}

if (!examJsonSchema.required?.includes("title")) {
  throw new Error("Exam JSON Schema did not preserve the required title field.");
}

if (parsedExam.durationMinutes !== 120) {
  throw new Error("ExamSchema did not preserve the optional durationMinutes field.");
}
