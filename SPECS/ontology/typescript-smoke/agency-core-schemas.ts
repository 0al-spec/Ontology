import {
  AGENCY_ATTRIBUTION_LIMITS,
  AGENCY_SOURCE_ATTRIBUTION_PROFILE,
  validateAgencyAttribution,
} from "../packages/agency-core/consumer/source-attribution-v1";
import type {
  AgencyAttributionClaim,
  AgencyAttributionDocument,
  AgencyDiagnosticCode,
  AgencyEnvironment,
  AgencySupportPresence,
  AgencyValidationResult,
} from "../packages/agency-core/consumer/source-attribution-v1";
import {
  AgencyContextSchema, AnticipationHypothesisSchema, AwarenessHypothesisSchema,
  GoalHypothesisSchema, IntentionHypothesisSchema, OperatorAgencySupportSchema,
  OutcomeAttitudeHypothesisSchema, PropositionContentSchema,
  RejectAgencySchema, ReviewAgencySchema, toJsonSchemaFor,
} from "../packages/agency-core/generated/schemas";
import { parseOntologyEntity } from "../packages/agency-core/generated/validators";
import exampleDocument from "../packages/agency-core/examples/source-only-attribution.json";
import exampleIndex from "../packages/agency-core/examples/reference-index.json";
import profileContract from "../packages/agency-core/profiles/agency-source-attribution-v1.json";

let acceptedControls = 0;
let rejectedControls = 0;

function requireValue(condition: boolean, message: string) {
  if (!condition) throw new Error(message);
}

function environment(): AgencyEnvironment {
  return {
    graphKey: "agency-example",
    revisionKey: "revision-1",
    views: [
      { id: "candidate-view", type: "eventcore:InterpretationCandidate", actorRoleIds: ["actor-role"] },
      { id: "record-view", type: "eventcore:Interpretation", actorRoleIds: ["actor-role"] },
      { id: "other-view", type: "eventcore:InterpretationCandidate", actorRoleIds: ["other-role"] },
    ],
    roles: [
      { id: "actor-role", roleName: "actor", entityId: "actor-entity" },
      { id: "other-role", roleName: "actor", entityId: "other-entity" },
    ],
    entities: ["actor-entity", "other-entity", "operator-entity"],
    motivations: [
      { id: "motive-hypothesis", viewId: "candidate-view", actorRoleId: "actor-role", contributionKind: "omission" },
      { id: "unresolved-motive", viewId: "candidate-view", contributionKind: "omission" },
      { id: "record-motive", viewId: "record-view", actorRoleId: "actor-role", contributionKind: "omission" },
    ],
    sourceAssertions: ["source-assertion", "opposing-assertion"],
  };
}

function commonClaim(id: string) {
  return { id, reviewState: "proposed" as const, positiveSupport: [], negativeSupport: [] };
}

function document(): AgencyAttributionDocument {
  return {
    profile: AGENCY_SOURCE_ATTRIBUTION_PROFILE,
    frame: {
      graphKey: "agency-example",
      revisionKey: "revision-1",
      viewId: "candidate-view",
      actorRoleId: "actor-role",
      contributionKind: "omission",
    },
    contents: [{ id: "condition", description: "The reported condition remains possible.", meaningRef: "example:condition" }],
    claims: [
      { ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "motive-hypothesis" }, value: "aware" },
      { ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "maintain" },
      { ...commonClaim("intention"), kind: "intention", goalIds: ["goal"] },
      { ...commonClaim("anticipation"), kind: "anticipation", contentId: "condition", expectation: "possible" },
      { ...commonClaim("attitude"), kind: "attitude", contentId: "condition", attitude: "accepts" },
    ],
  };
}

function succeeds(raw: unknown, index: AgencyEnvironment = environment()) {
  const result = validateAgencyAttribution(raw, index);
  if (!result.success) throw new Error("Envelope unexpectedly rejected: " + JSON.stringify(result.diagnostics));
  acceptedControls += 1;
  return result;
}

function rejects(raw: unknown, code: AgencyDiagnosticCode, index: AgencyEnvironment = environment()) {
  const result = validateAgencyAttribution(raw, index);
  if (result.success) throw new Error("Envelope unexpectedly accepted; expected " + code);
  requireValue(result.diagnostics.some(diagnostic => diagnostic.code === code),
    "Expected diagnostic " + code + "; received " + JSON.stringify(result.diagnostics));
  requireValue(result.diagnostics.length <= AGENCY_ATTRIBUTION_LIMITS.diagnostics, "Diagnostic output must remain bounded.");
  rejectedControls += 1;
}

function changed(change: (value: AgencyAttributionDocument) => void): AgencyAttributionDocument {
  const value = document();
  change(value);
  return value;
}

// Invalid probes deliberately enter through unknown, as real external envelopes do.
function withClaims(claims: unknown[]): unknown {
  return { ...document(), claims };
}

function presence(result: Extract<AgencyValidationResult, { success: true }>, id: string): AgencySupportPresence | undefined {
  return result.supportPresence.find(value => value.claimId === id)?.presence;
}

// Generated SDK checks the package's object declarations. The narrower consumer
// below additionally checks enums, strict envelope shape and indexed references.
const objectSamples = [
  [PropositionContentSchema, { $type: "agencycore:PropositionContent", contentKey: "condition", description: "An unasserted condition." }],
  [AgencyContextSchema, { $type: "agencycore:AgencyContext", contextKey: "context", contributionKind: "omission" }],
  [AwarenessHypothesisSchema, { $type: "agencycore:AwarenessHypothesis", hypothesisKey: "awareness", value: "unaware" }],
  [GoalHypothesisSchema, { $type: "agencycore:GoalHypothesis", hypothesisKey: "goal", direction: "maintain" }],
  [IntentionHypothesisSchema, { $type: "agencycore:IntentionHypothesis", hypothesisKey: "intention" }],
  [AnticipationHypothesisSchema, { $type: "agencycore:AnticipationHypothesis", hypothesisKey: "anticipation", expectation: "possible" }],
  [OutcomeAttitudeHypothesisSchema, { $type: "agencycore:OutcomeAttitudeHypothesis", hypothesisKey: "attitude", attitude: "accepts" }],
  [OperatorAgencySupportSchema, { $type: "agencycore:OperatorAgencySupport", supportKey: "support", rationale: "Uncited operator attribution." }],
] as const;
for (const [schema, sample] of objectSamples) {
  requireValue(schema.safeParse(sample).success, "Declared agency object must parse: " + sample.$type);
  for (const key of Object.keys(sample)) {
    const missing = Object.fromEntries(Object.entries(sample).filter(([name]) => name !== key));
    requireValue(!schema.safeParse(missing).success, "Required agency field disappeared: " + sample.$type + "." + key);
  }
}
for (const [schema, sample] of [
  [ReviewAgencySchema, { $type: "agencycore:ReviewAgency" }],
  [RejectAgencySchema, { $type: "agencycore:RejectAgency" }],
] as const) requireValue(schema.safeParse(sample).success, "Review command shape must parse.");
requireValue(!PropositionContentSchema.safeParse({ ...objectSamples[0][1], description: 1 }).success,
  "Proposition content description must reject a number.");
requireValue(!AgencyContextSchema.safeParse({ ...objectSamples[1][1], perspectiveAt: "later" }).success,
  "Perspective timestamp must reject a string.");
requireValue(parseOntologyEntity(PropositionContentSchema.parse(objectSamples[0][1])).$type === "agencycore:PropositionContent",
  "Generic SDK dispatch must retain the content discriminator.");
for (const field of ["truthState", "beforeSnapshot", "afterSnapshot", "delta", "legalIntent"]) {
  requireValue(!Object.hasOwn(toJsonSchemaFor(PropositionContentSchema).properties ?? {}, field),
    "Unasserted content must not declare physical or factual authority fields.");
}
requireValue(AwarenessHypothesisSchema.safeParse({ ...objectSamples[2][1], value: "unknown-label" }).success,
  "Generic generated primitive checks must not be mistaken for the bounded consumer's enum admission.");

// A source-only view needs no record, snapshot, actual effect or Delta. The
// caller's index is a declared reference environment, not an admission receipt.
const index = environment();
const input = document();
const before = JSON.stringify({ index, input });
const checked = succeeds(input, index);
requireValue(JSON.stringify({ index, input }) === before, "Validation must not mutate its caller's inputs.");
requireValue(checked.checked.frame.viewId === "candidate-view", "A candidate must retain its own scope.");
requireValue(checked.checked.claims.length === 5, "Checking must not add or remove claims.");
requireValue(!Object.hasOwn(checked.checked.frame, "perspectiveTime")
  && !Object.hasOwn(checked.checked.frame, "reportTime"), "Absent times must remain absent.");
requireValue(checked.supportPresence.every(value => value.presence === "unknown"),
  "No support means unknown support, even for an explicitly aware claim.");
requireValue(Object.keys(checked.authority).length === 5 && Object.values(checked.authority).every(value => value === false),
  "Schema/reference checks must confer no factual, mental, causal, legal or physical authority.");

// Independent support collections: the same source may appear on both signs.
// Distinct source and operator support may coexist; operator author is not Actor.
for (const [positive, negative, expected] of [
  [false, false, "unknown"], [true, false, "supported"],
  [false, true, "opposed"], [true, true, "contested"],
] as const) {
  const goal: AgencyAttributionClaim = {
    ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
    positiveSupport: positive ? [
      { kind: "source", id: "source-assertion" },
      { kind: "operator", authorId: "operator-entity", rationale: "A separately attributed operator reading." },
    ] : [],
    negativeSupport: negative ? [{ kind: "source", id: "source-assertion" }] : [],
  };
  const result = succeeds(withClaims([goal]));
  requireValue(presence(result, "goal") === expected, "Support polarity must remain independent: " + expected);
  requireValue(result.checked.claims.length === 1 && result.checked.claims[0].kind === "goal",
    "Goal support must not generate anticipation, awareness, attitude or intention.");
}
for (const reviewState of ["proposed", "reviewed", "rejected"] as const) {
  const goal: AgencyAttributionClaim = {
    ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "avoid", reviewState,
    positiveSupport: [{ kind: "source", id: "source-assertion" }],
  };
  const result = succeeds(withClaims([goal]));
  requireValue(presence(result, "goal") === "supported" && result.checked.claims[0].reviewState === reviewState,
    "Review must neither establish truth nor erase or invert declared support.");
}

for (const value of ["aware", "partly_aware", "unaware", "not_applicable"] as const) {
  const claim: AgencyAttributionClaim = {
    ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "motive-hypothesis" }, value,
  };
  const result = succeeds(withClaims([claim]));
  const retained = result.checked.claims[0];
  requireValue(retained.kind === "awareness" && retained.value === value && presence(result, "awareness") === "unknown",
    "Actor awareness/applicability values must remain distinct from analyst support uncertainty.");
}
rejects(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "motive-hypothesis" }, value: "unknown",
}]), "INVALID_DOCUMENT_SCHEMA");
const noClaims = succeeds(withClaims([]));
requireValue(noClaims.checked.claims.length === 0 && noClaims.supportPresence.length === 0,
  "Absent claims must not become unaware or not_applicable claims.");
const explicitNotAnticipated = succeeds(withClaims([{
  ...commonClaim("anticipation"), kind: "anticipation", contentId: "condition", expectation: "not_anticipated",
}]));
const retainedAnticipation = explicitNotAnticipated.checked.claims[0];
requireValue(retainedAnticipation.kind === "anticipation" && retainedAnticipation.expectation === "not_anticipated"
  && presence(explicitNotAnticipated, "anticipation") === "unknown",
  "Explicit non-anticipation is a retained subject claim, not a result of missing support.");

// The psychological applicability of an arbitrary indexed Entity is not inferred.
const arbitraryEntityIndex = environment();
arbitraryEntityIndex.entities[0] = "natural-phenomenon";
arbitraryEntityIndex.roles[0].entityId = "natural-phenomenon";
requireValue(succeeds(document(), arbitraryEntityIndex).checked.claims[0].kind === "awareness",
  "Entity labels must not create a psychological applicability classification.");

const unresolved = changed(value => {
  delete value.frame.actorRoleId;
  value.claims = [{
    ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "unresolved-motive" }, value: "unaware",
  }];
});
requireValue(!Object.hasOwn(succeeds(unresolved).checked.frame, "actorRoleId"),
  "Unresolved Actor must remain unresolved even when an awareness hypothesis is supplied.");
rejects(changed(value => { delete value.frame.actorRoleId; }), "MOTIVATION_SCOPE_MISMATCH");
rejects(changed(value => {
  value.claims = [{
    ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "unresolved-motive" }, value: "aware",
  }];
}), "MOTIVATION_SCOPE_MISMATCH");

const timed = changed(value => {
  value.frame.perspectiveTime = { clockKey: "actor-clock", at: 200 };
  value.frame.reportTime = { clockKey: "source-clock", at: 3 };
});
const timedResult = succeeds(timed);
requireValue(timedResult.checked.frame.perspectiveTime?.at === 200
  && timedResult.checked.frame.reportTime?.at === 3
  && timedResult.checked.frame.perspectiveTime?.clockKey === "actor-clock"
  && timedResult.checked.frame.reportTime?.clockKey === "source-clock",
"Separate time domains must remain separate, with no comparison, conversion or equality default.");
const onlyReport = changed(value => { value.frame.reportTime = { clockKey: "source-clock", at: 3 }; });
requireValue(!Object.hasOwn(succeeds(onlyReport).checked.frame, "perspectiveTime"),
  "Report time must not synthesize the time of Actor's perspective.");
rejects(changed(value => { value.frame.perspectiveTime = { clockKey: "clock", at: 1.5 }; }), "INVALID_DOCUMENT_SCHEMA");
rejects(changed(value => { value.frame.reportTime = { clockKey: "clock", at: Number.MAX_SAFE_INTEGER + 1 }; }), "INVALID_DOCUMENT_SCHEMA");
for (const field of ["perspectiveTime", "reportTime"] as const) {
  rejects({ ...document(), frame: { ...document().frame, [field]: { clockKey: "clock" } } }, "INVALID_DOCUMENT_SCHEMA");
  rejects({ ...document(), frame: { ...document().frame, [field]: { at: 3 } } }, "INVALID_DOCUMENT_SCHEMA");
}

// Exact graph/revision/view/role bindings are required. Sharing an Actor or a
// physical record would not make a different Interpretation the selected view.
rejects(changed(value => { value.frame.graphKey = "another-graph"; }), "GRAPH_MISMATCH");
rejects(changed(value => { value.frame.revisionKey = "revision-2"; }), "REVISION_MISMATCH");
rejects(changed(value => { value.frame.viewId = "absent-view"; }), "UNKNOWN_VIEW");
rejects(changed(value => { value.frame.actorRoleId = "absent-role"; }), "UNKNOWN_ROLE");
rejects(changed(value => { value.frame.actorRoleId = "other-role"; }), "ACTOR_ROLE_NOT_REACHED");
rejects(changed(value => { value.frame.viewId = "record-view"; }), "MOTIVATION_SCOPE_MISMATCH");
const wrongRoleName = environment();
wrongRoleName.roles[0].roleName = "instrument";
rejects(document(), "ACTOR_ROLE_NOT_ACTOR", wrongRoleName);
const missingEntity = environment();
missingEntity.roles[0].entityId = "absent-entity";
rejects(document(), "UNKNOWN_ENTITY", missingEntity);
const missingViewRole = environment();
missingViewRole.views[0].actorRoleIds.push("absent-role");
rejects(document(), "UNKNOWN_ROLE", missingViewRole);
const missingMotivationView = environment();
missingMotivationView.motivations[0].viewId = "absent-view";
rejects(document(), "UNKNOWN_VIEW", missingMotivationView);
const wrongContributionKind = environment();
wrongContributionKind.motivations[0].contributionKind = "action";
rejects(document(), "MOTIVATION_SCOPE_MISMATCH", wrongContributionKind);

rejects(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "absent-motive" }, value: "aware",
}]), "UNKNOWN_MOTIVATION");
rejects(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "record-motive" }, value: "aware",
}]), "MOTIVATION_SCOPE_MISMATCH");
const differentActorMotivation = environment();
differentActorMotivation.views[0].actorRoleIds.push("other-role");
differentActorMotivation.motivations.push({ id: "other-actor-motive", viewId: "candidate-view", actorRoleId: "other-role", contributionKind: "omission" });
rejects(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "motivation", id: "other-actor-motive" }, value: "aware",
}]), "MOTIVATION_SCOPE_MISMATCH", differentActorMotivation);
succeeds(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "content", id: "condition" }, value: "partly_aware",
}]));
rejects(withClaims([{
  ...commonClaim("awareness"), kind: "awareness", target: { kind: "content", id: "absent-content" }, value: "aware",
}]), "UNKNOWN_CONTENT");

for (const claim of [
  { ...commonClaim("goal"), kind: "goal", contentId: "absent-content", direction: "seek" },
  { ...commonClaim("anticipation"), kind: "anticipation", contentId: "absent-content", expectation: "certain" },
  { ...commonClaim("attitude"), kind: "attitude", contentId: "absent-content", attitude: "desires" },
] satisfies AgencyAttributionClaim[]) rejects(withClaims([claim]), "UNKNOWN_CONTENT");
rejects(withClaims([{ ...commonClaim("intention"), kind: "intention", goalIds: ["absent-goal"] }]), "UNKNOWN_CLAIM");
rejects(withClaims([{ ...commonClaim("intention"), kind: "intention", goalIds: ["intention"] }]), "GOAL_REFERENCE_KIND_MISMATCH");
rejects(changed(value => {
  value.claims[2] = { ...commonClaim("intention"), kind: "intention", goalIds: ["anticipation"] };
}), "GOAL_REFERENCE_KIND_MISMATCH");
const bareIntention = succeeds(withClaims([{ ...commonClaim("intention"), kind: "intention", goalIds: [] }]));
requireValue(bareIntention.checked.claims.length === 1 && bareIntention.checked.contents.length === 1,
  "Atomic intention needs no inferred goal or claimed achievement; unused proposition content remains unasserted.");

rejects(withClaims([{
  ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
  positiveSupport: [{ kind: "source", id: "absent-source" }],
}]), "UNKNOWN_SOURCE_ASSERTION");
rejects(withClaims([{
  ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
  negativeSupport: [{ kind: "operator", authorId: "absent-author", rationale: "Explicitly uncited." }],
}]), "UNKNOWN_SUPPORT_AUTHOR");

rejects(changed(value => { value.contents.push({ ...value.contents[0] }); }), "DUPLICATE_ID");
rejects(changed(value => { value.claims.push({ ...value.claims[0] }); }), "DUPLICATE_ID");
rejects(changed(value => { value.contents[0].id = "actor-entity"; }), "DUPLICATE_ID");
const duplicateEnvironmentIds = environment();
duplicateEnvironmentIds.sourceAssertions.push("actor-entity");
rejects(document(), "DUPLICATE_ID", duplicateEnvironmentIds);
const duplicateRoleReferences = environment();
duplicateRoleReferences.views[0].actorRoleIds.push("actor-role");
rejects(document(), "DUPLICATE_REFERENCE", duplicateRoleReferences);
rejects(changed(value => {
  value.claims[2] = { ...commonClaim("intention"), kind: "intention", goalIds: ["goal", "goal"] };
}), "DUPLICATE_REFERENCE");
rejects(withClaims([{
  ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
  positiveSupport: [{ kind: "source", id: "source-assertion" }, { kind: "source", id: "source-assertion" }],
}]), "DUPLICATE_REFERENCE");

// Strict objects prevent physical observations, workflow authority, per-claim
// scope overrides and executable/legal labels from entering this envelope.
for (const field of ["beforeSnapshot", "afterSnapshot", "delta", "causalHypothesis", "authority", "truthState"]) {
  rejects({ ...document(), [field]: {} }, "INVALID_DOCUMENT_SCHEMA");
  rejects({ ...document(), frame: { ...document().frame, [field]: {} } }, "INVALID_DOCUMENT_SCHEMA");
  rejects({ ...document(), contents: [{ ...document().contents[0], [field]: {} }] }, "INVALID_DOCUMENT_SCHEMA");
  rejects(withClaims([{ ...document().claims[0], [field]: {} }]), "INVALID_DOCUMENT_SCHEMA");
}
rejects({ ...document(), profile: "eventcore-provenance-v1" }, "INVALID_DOCUMENT_SCHEMA");
rejects({ ...document(), contents: [{ ...document().contents[0], $type: "eventcore:StateSnapshot" }] }, "INVALID_DOCUMENT_SCHEMA");
rejects(withClaims([{ ...document().claims[0], actorRoleId: "other-role" }]), "INVALID_DOCUMENT_SCHEMA");
rejects(withClaims([{ ...document().claims[0], kind: "legal_intent" }]), "INVALID_DOCUMENT_SCHEMA");
rejects(withClaims([{
  ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
  positiveSupport: [{ kind: "source", id: "source-assertion", authenticated: true }],
}]), "INVALID_DOCUMENT_SCHEMA");
const forgedEnvironment = { ...environment(), sourceTruthVerified: true };
rejects(document(), "INVALID_ENVIRONMENT_SCHEMA", forgedEnvironment);

for (const field of ["positiveSupport", "negativeSupport", "reviewState"] as const) {
  const incomplete = Object.fromEntries(Object.entries(document().claims[0]).filter(([key]) => key !== field));
  rejects({ ...document(), claims: [incomplete] }, "INVALID_DOCUMENT_SCHEMA");
}
rejects({ ...document(), claims: Array.from({ length: 33 }, (_, index) => ({
  ...commonClaim("goal-" + index), kind: "goal", contentId: "condition", direction: "seek",
})) }, "INVALID_DOCUMENT_SCHEMA");
const maximumClaims = succeeds(withClaims(Array.from({ length: 32 }, (_, index) => ({
  ...commonClaim("goal-" + index), kind: "goal", contentId: "condition", direction: "seek",
}))));
requireValue(maximumClaims.checked.claims.length === 32, "The documented 32-claim boundary must be inclusive.");
rejects({ ...document(), contents: Array.from({ length: 33 }, (_, index) => ({
  id: "content-" + index, description: "Unasserted condition.",
})) }, "INVALID_DOCUMENT_SCHEMA");
rejects(withClaims([{
  ...commonClaim("goal"), kind: "goal", contentId: "condition", direction: "seek",
  positiveSupport: Array.from({ length: 33 }, () => ({ kind: "source", id: "source-assertion" })),
}]), "INVALID_DOCUMENT_SCHEMA");
rejects({ ...document(), contents: [{ id: "condition", description: "x".repeat(4097) }] }, "INVALID_DOCUMENT_SCHEMA");
rejects(changed(value => { value.frame.graphKey = "g".repeat(257); }), "INVALID_DOCUMENT_SCHEMA");
rejects(changed(value => { value.frame.viewId = "candidate-view\n"; }), "INVALID_DOCUMENT_SCHEMA");
const oversizedEnvironment = environment();
oversizedEnvironment.entities = Array.from({ length: 4097 }, (_, index) => "entity-" + index);
rejects(document(), "INVALID_ENVIRONMENT_SCHEMA", oversizedEnvironment);

// Runtime envelope checks above do not prove source meaning, event graph
// admission, psychological applicability or any assertion's factual truth.

// Exercise committed neutral examples and every profile-declared enum through
// the public consumer, not merely comparisons between duplicate constants.
succeeds(exampleDocument, exampleIndex as AgencyEnvironment);
for (const value of profileContract.values.awareness)
  succeeds(withClaims([{ ...commonClaim("profile-awareness"), kind: "awareness", target: { kind: "motivation", id: "motive-hypothesis" }, value }]));
for (const direction of profileContract.values.goal)
  succeeds(withClaims([{ ...commonClaim("profile-goal"), kind: "goal", contentId: "condition", direction }]));
for (const expectation of profileContract.values.anticipation)
  succeeds(withClaims([{ ...commonClaim("profile-anticipation"), kind: "anticipation", contentId: "condition", expectation }]));
for (const attitude of profileContract.values.attitude)
  succeeds(withClaims([{ ...commonClaim("profile-attitude"), kind: "attitude", contentId: "condition", attitude }]));
console.log(`Agency reference envelope: PASS (${acceptedControls} positive / ${rejectedControls} negative controls; no truth or normative classification).`);
