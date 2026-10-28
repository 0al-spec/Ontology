import { z } from "zod";

/** A bounded reference envelope, not an event graph admission profile. */
export const AGENCY_SOURCE_ATTRIBUTION_PROFILE = "agency-source-attribution/v1" as const;

export const AGENCY_ATTRIBUTION_LIMITS = {
  identifierLength: 256,
  textLength: 4096,
  claims: 32,
  contents: 32,
  supportsPerPolarity: 32,
  goalsPerIntention: 32,
  environmentEntriesPerKind: 4096,
  rolesPerView: 64,
  diagnostics: 128,
} as const;

const identifier = z.string().min(1).max(AGENCY_ATTRIBUTION_LIMITS.identifierLength)
  .refine(value => value.length <= AGENCY_ATTRIBUTION_LIMITS.identifierLength && !/\s/u.test(value),
    "An identifier must not contain whitespace.");
const text = z.string().min(1).max(AGENCY_ATTRIBUTION_LIMITS.textLength)
  .refine(value => value.length <= AGENCY_ATTRIBUTION_LIMITS.textLength && value.trim().length > 0,
    "Text must not be blank.");

// Gate length before parsing elements, so an oversized array does not cause an
// unbounded number of nested validation operations or diagnostics.
function boundedArray<T extends z.ZodType>(element: T, maximum: number) {
  return z.unknown().superRefine((value, context) => {
    if (!Array.isArray(value)) {
      context.addIssue({ code: "custom", message: "Expected an array." });
    } else if (value.length > maximum) {
      context.addIssue({ code: "custom", message: `Array exceeds its limit of ${maximum}.` });
    }
  }).pipe(z.array(element).max(maximum));
}

const timeSchema = z.strictObject({
  clockKey: identifier,
  at: z.number().int().refine(Number.isSafeInteger, "Timestamp must be a safe integer."),
});
const viewSchema = z.strictObject({
  id: identifier,
  type: z.enum(["eventcore:Interpretation", "eventcore:InterpretationCandidate"]),
  actorRoleIds: boundedArray(identifier, AGENCY_ATTRIBUTION_LIMITS.rolesPerView),
});
const roleSchema = z.strictObject({
  id: identifier,
  roleName: identifier,
  entityId: identifier,
});
const motivationSchema = z.strictObject({
  id: identifier,
  viewId: identifier,
  actorRoleId: identifier.optional(),
  contributionKind: z.enum(["action", "omission"]),
});

const environmentSchema = z.strictObject({
  graphKey: identifier,
  revisionKey: identifier,
  views: boundedArray(viewSchema, AGENCY_ATTRIBUTION_LIMITS.environmentEntriesPerKind),
  roles: boundedArray(roleSchema, AGENCY_ATTRIBUTION_LIMITS.environmentEntriesPerKind),
  entities: boundedArray(identifier, AGENCY_ATTRIBUTION_LIMITS.environmentEntriesPerKind),
  motivations: boundedArray(motivationSchema, AGENCY_ATTRIBUTION_LIMITS.environmentEntriesPerKind),
  sourceAssertions: boundedArray(identifier, AGENCY_ATTRIBUTION_LIMITS.environmentEntriesPerKind),
});

/**
 * Caller-provided reference index. Validating its shape and internal references
 * does not authenticate its origin or independently inspect an event graph,
 * source assertion, physical observation or psychological applicability.
 */
export type AgencyEnvironment = z.infer<typeof environmentSchema>;

const supportSchema = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("source"), id: identifier }),
  z.strictObject({ kind: z.literal("operator"), authorId: identifier, rationale: text }),
]);
const claimFields = {
  id: identifier,
  reviewState: z.enum(["proposed", "reviewed", "rejected"]),
  positiveSupport: boundedArray(supportSchema, AGENCY_ATTRIBUTION_LIMITS.supportsPerPolarity),
  negativeSupport: boundedArray(supportSchema, AGENCY_ATTRIBUTION_LIMITS.supportsPerPolarity),
};
const claimSchema = z.discriminatedUnion("kind", [
  z.strictObject({
    ...claimFields,
    kind: z.literal("awareness"),
    target: z.strictObject({ kind: z.enum(["motivation", "content"]), id: identifier }),
    value: z.enum(["aware", "partly_aware", "unaware", "not_applicable"]),
  }),
  z.strictObject({
    ...claimFields,
    kind: z.literal("goal"),
    contentId: identifier,
    direction: z.enum(["seek", "avoid", "maintain"]),
  }),
  z.strictObject({
    ...claimFields,
    kind: z.literal("intention"),
    goalIds: boundedArray(identifier, AGENCY_ATTRIBUTION_LIMITS.goalsPerIntention),
  }),
  z.strictObject({
    ...claimFields,
    kind: z.literal("anticipation"),
    contentId: identifier,
    expectation: z.enum(["possible", "expected", "certain", "not_anticipated"]),
  }),
  z.strictObject({
    ...claimFields,
    kind: z.literal("attitude"),
    contentId: identifier,
    attitude: z.enum(["desires", "accepts", "opposes", "indifferent"]),
  }),
]);

const documentSchema = z.strictObject({
  profile: z.literal(AGENCY_SOURCE_ATTRIBUTION_PROFILE),
  frame: z.strictObject({
    graphKey: identifier,
    revisionKey: identifier,
    viewId: identifier,
    actorRoleId: identifier.optional(),
    contributionKind: z.enum(["action", "omission"]),
    perspectiveTime: timeSchema.optional(),
    reportTime: timeSchema.optional(),
  }),
  // Content is an unasserted proposition, never a supplied physical state,
  // polarity-bearing eventcore:Fact, observed consequence or exact Delta.
  contents: boundedArray(z.strictObject({
    id: identifier,
    description: text,
    meaningRef: identifier.optional(),
  }), AGENCY_ATTRIBUTION_LIMITS.contents),
  claims: boundedArray(claimSchema, AGENCY_ATTRIBUTION_LIMITS.claims),
});

export type AgencyAttributionDocument = z.infer<typeof documentSchema>;
export type AgencyAttributionClaim = z.infer<typeof claimSchema>;
export type AgencySupportPresence = "unknown" | "supported" | "opposed" | "contested";

export type AgencyDiagnosticCode =
  | "INVALID_DOCUMENT_SCHEMA" | "INVALID_ENVIRONMENT_SCHEMA"
  | "DUPLICATE_ID" | "DUPLICATE_REFERENCE"
  | "GRAPH_MISMATCH" | "REVISION_MISMATCH"
  | "UNKNOWN_VIEW" | "UNKNOWN_ROLE" | "UNKNOWN_ENTITY"
  | "ACTOR_ROLE_NOT_REACHED" | "ACTOR_ROLE_NOT_ACTOR"
  | "UNKNOWN_MOTIVATION" | "MOTIVATION_SCOPE_MISMATCH"
  | "UNKNOWN_CONTENT" | "UNKNOWN_CLAIM" | "GOAL_REFERENCE_KIND_MISMATCH"
  | "UNKNOWN_SOURCE_ASSERTION" | "UNKNOWN_SUPPORT_AUTHOR";

export interface AgencyDiagnostic {
  code: AgencyDiagnosticCode;
  path: string;
  message: string;
}

export type AgencyValidationResult = {
  success: false;
  diagnostics: AgencyDiagnostic[];
} | {
  success: true;
  /** Checked means schema/reference checks against the supplied index only. */
  checked: AgencyAttributionDocument;
  supportPresence: { claimId: string; presence: AgencySupportPresence }[];
  authority: {
    readonly sourceTruthVerified: false;
    readonly mentalStateTruthVerified: false;
    readonly causationVerified: false;
    readonly legalClassificationPerformed: false;
    readonly physicalEnrichmentPerformed: false;
  };
};

function schemaDiagnostics(
  code: "INVALID_DOCUMENT_SCHEMA" | "INVALID_ENVIRONMENT_SCHEMA",
  prefix: string,
  error: z.ZodError,
): AgencyDiagnostic[] {
  return error.issues.slice(0, AGENCY_ATTRIBUTION_LIMITS.diagnostics).map(issue => ({
    code,
    path: [prefix, ...issue.path.map(String)].join(".").slice(0, 1024),
    message: issue.message.slice(0, 512),
  }));
}

/**
 * Check only a bounded reference envelope against a caller-supplied index.
 * No default values, inference, time comparison, actor resolution, mental-state
 * diagnosis, physical enrichment, authentication or factual verification occurs.
 * Both support polarities and review workflow remain independent of truth.
 */
export function validateAgencyAttribution(
  raw: unknown,
  environment: AgencyEnvironment,
): AgencyValidationResult {
  const parsedEnvironment = environmentSchema.safeParse(environment);
  if (!parsedEnvironment.success) {
    return { success: false, diagnostics: schemaDiagnostics(
      "INVALID_ENVIRONMENT_SCHEMA", "environment", parsedEnvironment.error) };
  }
  const parsedDocument = documentSchema.safeParse(raw);
  if (!parsedDocument.success) {
    return { success: false, diagnostics: schemaDiagnostics(
      "INVALID_DOCUMENT_SCHEMA", "document", parsedDocument.error) };
  }
  const index = parsedEnvironment.data;
  const document = parsedDocument.data;
  const diagnostics: AgencyDiagnostic[] = [];
  const add = (code: AgencyDiagnosticCode, path: string, message: string) => {
    if (diagnostics.length < AGENCY_ATTRIBUTION_LIMITS.diagnostics) {
      diagnostics.push({ code, path, message });
    }
  };
  const allIds = new Set<string>();
  const register = (id: string, path: string) => {
    if (allIds.has(id)) add("DUPLICATE_ID", path, "Node IDs must be unique across the supplied index and envelope.");
    allIds.add(id);
  };
  const uniqueReferences = (ids: string[], path: string) => {
    const seen = new Set<string>();
    ids.forEach((id, position) => {
      if (seen.has(id)) add("DUPLICATE_REFERENCE", `${path}.${position}`, "A reference is repeated in the same collection.");
      seen.add(id);
    });
  };

  index.views.forEach((value, position) => register(value.id, `environment.views.${position}.id`));
  index.roles.forEach((value, position) => register(value.id, `environment.roles.${position}.id`));
  index.entities.forEach((id, position) => register(id, `environment.entities.${position}`));
  index.motivations.forEach((value, position) => register(value.id, `environment.motivations.${position}.id`));
  index.sourceAssertions.forEach((id, position) => register(id, `environment.sourceAssertions.${position}`));
  document.contents.forEach((value, position) => register(value.id, `document.contents.${position}.id`));
  document.claims.forEach((value, position) => register(value.id, `document.claims.${position}.id`));

  const views = new Map(index.views.map(value => [value.id, value]));
  const roles = new Map(index.roles.map(value => [value.id, value]));
  const entities = new Set(index.entities);
  const motivations = new Map(index.motivations.map(value => [value.id, value]));
  const sourceAssertions = new Set(index.sourceAssertions);
  const contents = new Set(document.contents.map(value => value.id));
  const claims = new Map(document.claims.map(value => [value.id, value]));

  index.roles.forEach((role, position) => {
    if (!entities.has(role.entityId)) {
      add("UNKNOWN_ENTITY", `environment.roles.${position}.entityId`, "Role Entity is absent from the supplied index.");
    }
  });
  index.views.forEach((view, position) => {
    uniqueReferences(view.actorRoleIds, `environment.views.${position}.actorRoleIds`);
    view.actorRoleIds.forEach((id, rolePosition) => {
      if (!roles.has(id)) {
        add("UNKNOWN_ROLE", `environment.views.${position}.actorRoleIds.${rolePosition}`,
          "View role is absent from the supplied index.");
      }
    });
  });

  const checkScope = (viewId: string, actorRoleId: string | undefined, path: string) => {
    const view = views.get(viewId);
    if (!view) add("UNKNOWN_VIEW", `${path}.viewId`, "Selected view is absent from the supplied index.");
    if (actorRoleId === undefined) return;
    const role = roles.get(actorRoleId);
    if (!role) add("UNKNOWN_ROLE", `${path}.actorRoleId`, "Selected actor role is absent from the supplied index.");
    if (view && !view.actorRoleIds.includes(actorRoleId)) {
      add("ACTOR_ROLE_NOT_REACHED", `${path}.actorRoleId`, "Selected actor role is not reached from the selected view.");
    }
    if (role && role.roleName !== "actor") {
      add("ACTOR_ROLE_NOT_ACTOR", `${path}.actorRoleId`, "Selected role must be named actor.");
    }
  };
  index.motivations.forEach((motivation, position) => {
    checkScope(motivation.viewId, motivation.actorRoleId, `environment.motivations.${position}`);
  });
  if (document.frame.graphKey !== index.graphKey) {
    add("GRAPH_MISMATCH", "document.frame.graphKey", "Envelope graphKey must exactly match the supplied index.");
  }
  if (document.frame.revisionKey !== index.revisionKey) {
    add("REVISION_MISMATCH", "document.frame.revisionKey", "Envelope revisionKey must exactly match the supplied index.");
  }
  checkScope(document.frame.viewId, document.frame.actorRoleId, "document.frame");

  const checkContent = (id: string, path: string) => {
    if (!contents.has(id)) add("UNKNOWN_CONTENT", path, "Proposition content is absent from this envelope.");
  };
  document.claims.forEach((claim, position) => {
    const path = `document.claims.${position}`;
    for (const polarity of ["positiveSupport", "negativeSupport"] as const) {
      const supportKeys: string[] = [];
      claim[polarity].forEach((support, supportPosition) => {
        const supportPath = `${path}.${polarity}.${supportPosition}`;
        if (support.kind === "source") {
          supportKeys.push(JSON.stringify(["source", support.id]));
          if (!sourceAssertions.has(support.id)) {
            add("UNKNOWN_SOURCE_ASSERTION", `${supportPath}.id`, "Source assertion is absent from the supplied index.");
          }
        } else {
          supportKeys.push(JSON.stringify(["operator", support.authorId, support.rationale]));
          if (!entities.has(support.authorId)) {
            add("UNKNOWN_SUPPORT_AUTHOR", `${supportPath}.authorId`, "Operator support author must be an indexed Entity.");
          }
        }
      });
      // The same source may support and oppose a claim; uniqueness is local to
      // one sign only. Neither collection cancels or creates the other.
      uniqueReferences(supportKeys, `${path}.${polarity}`);
    }
    switch (claim.kind) {
      case "awareness": {
        if (claim.target.kind === "content") {
          checkContent(claim.target.id, `${path}.target.id`);
        } else {
          const motivation = motivations.get(claim.target.id);
          if (!motivation) {
            add("UNKNOWN_MOTIVATION", `${path}.target.id`, "Motivation hypothesis is absent from the supplied index.");
          } else if (motivation.viewId !== document.frame.viewId
            || motivation.actorRoleId !== document.frame.actorRoleId
            || motivation.contributionKind !== document.frame.contributionKind) {
            add("MOTIVATION_SCOPE_MISMATCH", `${path}.target.id`,
              "Motivation must have the exact selected view, actor role (including absence) and contribution kind.");
          }
        }
        break;
      }
      case "goal":
      case "anticipation":
      case "attitude":
        checkContent(claim.contentId, `${path}.contentId`);
        break;
      case "intention":
        uniqueReferences(claim.goalIds, `${path}.goalIds`);
        claim.goalIds.forEach((id, goalPosition) => {
          const goal = claims.get(id);
          if (!goal) {
            add("UNKNOWN_CLAIM", `${path}.goalIds.${goalPosition}`, "Referenced goal claim is absent from this envelope.");
          } else if (goal.kind !== "goal") {
            add("GOAL_REFERENCE_KIND_MISMATCH", `${path}.goalIds.${goalPosition}`, "An intention may reference only goal claims.");
          }
        });
        break;
    }
  });

  if (diagnostics.length > 0) return { success: false, diagnostics };
  return {
    success: true,
    checked: document,
    supportPresence: document.claims.map(claim => ({
      claimId: claim.id,
      presence: claim.positiveSupport.length > 0
        ? (claim.negativeSupport.length > 0 ? "contested" : "supported")
        : (claim.negativeSupport.length > 0 ? "opposed" : "unknown"),
    })),
    authority: {
      sourceTruthVerified: false,
      mentalStateTruthVerified: false,
      causationVerified: false,
      legalClassificationPerformed: false,
      physicalEnrichmentPerformed: false,
    },
  };
}
