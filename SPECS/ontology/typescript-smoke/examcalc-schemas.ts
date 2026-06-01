import { ExamSchema, toJsonSchemaFor } from "../packages/examcalc/generated/schemas";

const parsedExam = ExamSchema.parse({
  $type: "examcalc:Exam",
  id: "exam-2026-06-02"
});

const examJsonSchema = toJsonSchemaFor(ExamSchema);

if (parsedExam.$type !== "examcalc:Exam") {
  throw new Error("ExamSchema did not preserve the ontology type discriminator.");
}

if (examJsonSchema.type !== "object") {
  throw new Error("toJsonSchemaFor did not produce an object JSON Schema.");
}
