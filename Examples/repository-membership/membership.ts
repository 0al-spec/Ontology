import { z } from "zod";
import { classes, relations, type Ref } from "./generated/refs";
import { trigger, type Actor, type Entity } from "./generated/relations";
import type { AddRepository, Project, Repository, User } from "./generated/types";
import { ActionRelationshipRecordSchema } from "./generated/validators";

const repository = { $type: classes.Repository.alias, id: "r2" } satisfies Repository & Entity;
const rows = new Map([["row-42", repository]]);
const graphAddress = z.strictObject({ graphKey: z.string(), revisionKey: z.string(), nodeId: z.string() });
const graph = { key: "work", revision: "v1", nodes: new Map([["node-17", repository]]) };

function resolve(ref: Ref<Repository>): Repository | undefined {
  if (typeof ref.locator === "string") return rows.get(ref.locator);
  const address = graphAddress.safeParse(ref.locator);
  if (!address.success || address.data.graphKey !== graph.key || address.data.revisionKey !== graph.revision) {
    return undefined;
  }
  return graph.nodes.get(address.data.nodeId);
}

const project = { $type: classes.Project.alias, id: "p" } satisfies Project & Entity;
const relation = relations.addsRepositoryTo.alias;
const byKey: Ref<Repository> = { target: repository.$type, locator: "row-42" };
const address = { graphKey: graph.key, revisionKey: graph.revision, nodeId: "node-17" };
const byNode: Ref<Repository> = { target: repository.$type, locator: address };

function record(ref: Ref<Repository>) {
  return {
    relation, subject: { $type: classes.User.alias, id: "operator" }, object: project,
    action: { $type: classes.AddRepository.alias, repository: ref },
  } as const;
}

function exercise(known: Ref<Repository>, unknown: Ref<Repository>) {
  const existing = { $type: classes.Repository.alias, id: "r1" } satisfies Repository;
  const members = new Set<Repository>([existing]);
  const user = {
    ...record(known).subject,
    run(action, object) {
      const resolved = resolve(action.repository);
      if (!resolved) throw new Error("Unresolved repository");
      if (object.id !== project.id) throw new Error("Wrong project");
      members.add(resolved);
    },
  } satisfies User & Actor<AddRepository, Project & Entity>;

  function apply(ref: Ref<Repository>) {
    const saved = ActionRelationshipRecordSchema.parse(JSON.parse(JSON.stringify(record(ref))));
    if (saved.relation !== relation) throw new Error("Wrong relationship");
    trigger({ relation, subject: user, action: saved.action, object: project });
  }

  // Try the unknown reference first so even accidental insertion of r2 is visible.
  let rejected = false;
  try { apply(unknown); } catch (error) {
    if (!(error instanceof Error && error.message === "Unresolved repository")) throw error;
    rejected = true;
  }
  if (!rejected || members.size !== 1 || !members.has(existing)) throw new Error("Unknown reference changed membership");
  apply(known);
  if (!members.has(repository) || !members.has(existing)) throw new Error("Expected the same repository instance");
}

const wrongTarget: Ref<Project> = { target: project.$type, locator: byKey.locator };
const wrongAction: AddRepository = {
  $type: classes.AddRepository.alias,
  // @ts-expect-error The generated AddRepository field requires a Repository reference.
  repository: wrongTarget,
};
for (const ref of [wrongTarget, { target: repository.$type }, "row-42"]) {
  const incoming = { ...record(byKey), action: { ...wrongAction, repository: ref } };
  if (ActionRelationshipRecordSchema.safeParse(incoming).success) throw new Error("Malformed reference accepted");
}
exercise(byKey, { ...byKey, locator: "missing-row" });
exercise(byNode, { ...byNode, locator: { ...address, nodeId: "missing-node" } });
exercise(byNode, { ...byNode, locator: { ...address, revisionKey: "missing-revision" } });
console.log("Both locator forms resolved to r2. Unknown references preserved membership.");
