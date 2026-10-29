import {
  EncoderSchema,
  ImageDocumentSchema,
  ImageStateSchema,
  ReencodeSchema,
  SizeGoalSchema,
} from "../packages/image-encoding-pilot/generated/schemas";

type ObjectSchema = { safeParse(value: unknown): { success: boolean } };
let positives = 0;
let negatives = 0;

function accepts(schema: ObjectSchema, value: unknown, label: string) {
  if (!schema.safeParse(value).success) throw new Error("Expected primitive object acceptance: " + label);
  positives += 1;
}

function rejects(schema: ObjectSchema, value: unknown, label: string) {
  if (schema.safeParse(value).success) throw new Error("Expected primitive object rejection: " + label);
  negatives += 1;
}

const document = { $type: "imagepilot:ImageDocument", entityKey: "selected-image" };
const encoder = { $type: "imagepilot:Encoder", quality: 85 };
const action = {
  $type: "imagepilot:Reencode", identityMode: "in_place", dimensions: "preserve", actionKind: "jpeg_reencode",
};
const state = {
  $type: "imagepilot:ImageState", entityKey: "selected-image", byteLength: 123456,
  width: 64, height: 64, contentSHA256: "a".repeat(64),
};
const goal = {
  $type: "imagepilot:SizeGoal", basis: "reduction", comparison: "at_least", targetBytes: 200000, missingInput: "unknown",
};

for (const [schema, fixture, requiredField, wrongType] of [
  [ImageDocumentSchema, document, "entityKey", 7],
  [EncoderSchema, encoder, "quality", "85"],
  [ReencodeSchema, action, "identityMode", false],
  [ImageStateSchema, state, "byteLength", "123456"],
  [SizeGoalSchema, goal, "targetBytes", "200000"],
] as const) {
  accepts(schema, fixture, fixture.$type);
  const missing = Object.fromEntries(Object.entries(fixture).filter(([key]) => key !== requiredField));
  rejects(schema, missing, fixture.$type + " missing " + requiredField);
  rejects(schema, { ...fixture, [requiredField]: wrongType }, fixture.$type + " wrong type for " + requiredField);
}
rejects(EncoderSchema, { ...encoder, quality: 85.5 }, "Encoder quality must be an integer");

// Generic generated string fields intentionally do not enforce domain enums.
// Their acceptance here is not acceptance by the separate runtime profile.
accepts(ReencodeSchema, { ...action, identityMode: "unresolved-mode" }, "Identity mode remains a primitive string");
accepts(SizeGoalSchema, { ...goal, comparison: "unresolved-comparison" }, "Comparison remains a primitive string");

// These fabricated fixtures check object shapes only. They do not establish
// measurement/digest truth, relation consistency, enum validity, codec behavior,
// goal arithmetic, visual acceptance or implementation correspondence.
console.log(`Image encoding primitive SDK schemas: PASS (${positives} positive, ${negatives} negative); domain behavior unchecked.`);
