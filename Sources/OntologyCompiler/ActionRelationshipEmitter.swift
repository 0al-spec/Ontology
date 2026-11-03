struct ActionRelationshipEmitter {
    private struct Relation {
        let name: String
        let subject: String
        let action: String
        let objects: [String]
    }

    private let relations: [Relation]
    private let classes: [String: JSONObject]
    private let protocolFields: [String: [String]]

    init(ir: JSONObject, compiler: OntologyCompiler) throws {
        relations = try (ir["relations"] as? [JSONObject] ?? []).compactMap { item in
            guard let action = item["action"] as? String else { return nil }
            let name = item["fqid"] as? String ?? ""
            let objects = item["range"].map(compiler.relationRangeRefs) ?? []
            guard !name.isEmpty, let subject = item["domain"] as? String, !objects.isEmpty else {
                throw OntologyCompilerError.invalidArgument("Invalid endpoint in normalized action relationship \(name)")
            }
            return Relation(name: name, subject: subject, action: action, objects: objects)
        }
        classes = (ir["classes"] as? [JSONObject] ?? []).reduce(into: [:]) { result, item in
            if let ref = item["fqid"] as? String { result[ref] = item }
        }
        protocolFields = (ir["protocols"] as? [JSONObject] ?? []).reduce(into: [:]) { result, item in
            if let ref = item["fqid"] as? String { result[ref] = item["requiredFields"] as? [String] ?? [] }
        }
    }

    var typeDeclaration: String {
        guard !relations.isEmpty else { return "" }
        let variants = relations.map { relation in
            """
              | {
                  readonly relation: "\(relation.name)";
                  readonly subject: \(instanceType(relation.subject));
                  readonly action: \(instanceType(relation.action));
                  readonly object: \(relation.objects.map(instanceType).joined(separator: " | "));
                }
            """
        }
        return "\nexport type ActionRelationshipRecord =\n" + variants.joined(separator: "\n") + ";\n" + Self.executionContract
    }

    private static let executionContract = """

    type Records = { [R in ActionRelationshipRecord as R["relation"]]: R };

    export interface Entity {
      readonly id: import("./types").OntologyEntityId;
    }

    type ObjectOf<K extends keyof Records> = Records[K]["object"] & Entity;

    export interface Actor<A, O extends Entity> extends Entity {
      readonly run: (action: A, object: O) => void | Promise<void>;
    }

    export type ActionRelationship<K extends keyof Records = keyof Records> = {
      [Name in K]: {
        readonly relation: Name;
        readonly subject: Records[Name]["subject"] & Actor<Records[Name]["action"], ObjectOf<Name>>;
        readonly action: Records[Name]["action"];
        readonly object: ObjectOf<Name>;
      }
    }[K];

    export function trigger<K extends keyof Records>(relationship: ActionRelationship<K>): void | Promise<void> {
      return relationship.subject.run(relationship.action, relationship.object);
    }

    """

    var schemaImports: String {
        guard !relations.isEmpty else { return "" }
        return "import { z } from \"zod\";\n"
    }

    var localSchemaImports: String {
        endpointRefs.compactMap { classes[$0]?["id"] as? String }.map { ", \($0)Schema" }.joined()
    }

    private var endpointRefs: [String] {
        Set(relations.flatMap { [$0.subject, $0.action] + $0.objects }).sorted()
    }

    var schemaDeclaration: String {
        guard !relations.isEmpty else { return "" }
        let endpoints = endpointRefs.map { "  \"\($0)\": \(instanceSchema($0))," }
        func endpoint(_ ref: String) -> String { "endpoints[\"\(ref)\"]" }
        let variants = relations.map { relation in
            let objects = relation.objects.map(endpoint)
            let object = objects.count == 1 ? objects[0] : "z.union([\(objects.joined(separator: ", "))])"
            return """
              z.object({
                relation: z.literal("\(relation.name)"),
                subject: \(endpoint(relation.subject)),
                action: \(endpoint(relation.action)),
                object: \(object),
              })
            """
        }
        return """

        const endpoints = {
        \(endpoints.joined(separator: "\n"))
        } as const;

        export const ActionRelationshipRecordSchema = z.discriminatedUnion("relation", [
        \(variants.joined(separator: ",\n")),
        ]) satisfies z.ZodType<import("./relations").ActionRelationshipRecord>;

        /** @deprecated Use ActionRelationshipRecordSchema for stored data. */
        export const ActionRelationshipSchema = ActionRelationshipRecordSchema;

        """
    }

    private func instanceType(_ ref: String) -> String {
        guard let name = classes[ref]?["id"] as? String else { return "{ readonly $type: \"\(ref)\"; readonly id?: string }" }
        return "import(\"./types\").\(name)"
    }

    private func instanceSchema(_ ref: String) -> String {
        guard let item = classes[ref], let name = item["id"] as? String else {
            return "z.looseObject({ $type: z.literal(\"\(ref)\"), id: z.string().exactOptional() })"
        }
        let schema = "\(name)Schema"
        // JSON can omit an optional property, but it cannot contain undefined.
        let fields = item["fields"] as? [JSONObject] ?? []
        let optional = fields.filter { $0["required"] as? Bool != true }.compactMap { $0["id"] as? String }
        let overrides = ["id: z.string().exactOptional()"] + optional.map { "\($0): \(schema).shape.\($0).unwrap().exactOptional()" }
        let jsonSchema = "\(schema).extend({ \(overrides.joined(separator: ", ")) })"
        // Generated class interfaces inherit required string fields from local protocols.
        let inherited = (item["implements"] as? [String] ?? []).flatMap { protocolFields[$0] ?? [] }
        guard !inherited.isEmpty else { return jsonSchema }
        let shape = Set(inherited).sorted().map { "\($0): z.string()" }.joined(separator: ", ")
        return "\(jsonSchema).and(z.object({ \(shape) }))"
    }
}
