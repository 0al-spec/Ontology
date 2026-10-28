import Foundation
import OntologyRules

extension OntologyCompiler {
    /// Emits consumer shapes for the pinned graph profile. Cross-node semantic
    /// checks still require validate-instances; this is not a second verifier.
    public func exportInstanceContract(
        ontologyIRPath: OntologySourcePath, outDirectory: OntologyOutputDirectory,
        profile: String = "eventcore-v1"
    ) throws {
        guard let selected = EventCoreProfileSelection(rawValue: profile) else {
            throw OntologyCompilerError.invalidArgument("instanceGraph.profile: unsupported explicit profile")
        }
        let ir = try pinnedEventCoreIR(at: ontologyIRPath, profile: selected)
        try FileManager.default.createDirectory(at: outDirectory.url, withIntermediateDirectories: true)
        try write(json: instanceGraphSchema(ir, profile: selected), to: outDirectory.url.appendingPathComponent("instance-graph.schema.json"))
        let authorityTypes = selected == .provenance ? snapshotAuthorityTypeScript : ""
        try write(text: instanceGraphTypeScript(ir, profile: selected) + authorityTypes, to: outDirectory.url.appendingPathComponent("instance-graph.ts"))
        if selected == .provenance {
            try write(json: snapshotAuthoritySchema(selected), to: outDirectory.url.appendingPathComponent("snapshot-authority.schema.json"))
        }
    }

    func instanceGraphSchema(_ ir: JSONObject, profile: EventCoreProfileSelection = .legacy) -> JSONObject {
        let classes = ir["classes"] as? [JSONObject] ?? []
        let relations = ir["relations"] as? [JSONObject] ?? []
        let projections = closedObject([
            "projectionKey": nonemptyStringSchema, "schemaKey": nonemptyStringSchema,
            "domain": ["enum": ["observation", "review", "normative"]]
        ])
        let pin = closedObject(profile.ontology.mapValues { ["const": $0] })
        var schema = closedObject([
            "apiVersion": ["const": EventCoreInstanceProfile.apiVersion], "kind": ["const": "InstanceGraph"],
            "profile": ["const": profile.rawValue], "graphKey": identifierSchema, "revisionKey": identifierSchema,
            "ontology": pin, "projections": finiteArray(projections, maximum: 1000),
            "nodes": finiteArray(["oneOf": classes.map(instanceNodeSchema)], maximum: 10_000),
            "edges": finiteArray(["oneOf": relations.map(instanceEdgeSchema)], maximum: 50_000)
        ])
        if profile == .provenance {
            var properties = schema["properties"] as? JSONObject ?? [:]
            properties["profilePin"] = closedObject(profile.definitionPin.mapValues { ["const": $0] })
            schema["properties"] = properties
            schema["required"] = properties.keys.sorted()
        }
        schema["$schema"] = "https://json-schema.org/draft/2020-12/schema"
        schema["title"] = "\(profile.rawValue) InstanceGraph (shapes only)"
        schema["description"] = "Pinned IR SHA256 \(profile.irSHA256). Use ontologyc validate-instances for references, sets and profile checks."
        return schema
    }

    var nonemptyStringSchema: JSONObject { ["type": "string", "minLength": 1] }
    var identifierSchema: JSONObject { ["type": "string", "pattern": "^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$"] }

    func closedObject(_ properties: JSONObject, optional: Set<String> = []) -> JSONObject {
        ["type": "object", "properties": properties, "required": properties.keys.filter { !optional.contains($0) }.sorted(), "additionalProperties": false]
    }

    func finiteArray(_ items: JSONObject, maximum: Int) -> JSONObject { ["type": "array", "items": items, "maxItems": maximum] }

    func instanceNodeSchema(_ definition: JSONObject) -> JSONObject {
        let fields = definition["fields"] as? [JSONObject] ?? []
        var properties = JSONObject()
        var optional = Set<String>()
        for field in fields {
            let key = string(field["id"]) ?? ""
            properties[key] = string(field["type"]) == "integer"
                ? ["type": "integer", "minimum": 0, "maximum": 9_007_199_254_740_991] : nonemptyStringSchema
            if field["required"] as? Bool != true { optional.insert(key) }
        }
        var node: JSONObject = [
            "id": identifierSchema, "type": ["const": string(definition["fqid"]) ?? ""],
            "fields": closedObject(properties, optional: optional)
        ]
        if definition["lifecycle"] != nil { node["state"] = ["enum": ["proposed", "reviewed", "rejected"]] }
        return closedObject(node)
    }

    func instanceRefSchema(_ type: String) -> JSONObject {
        closedObject(["graphKey": identifierSchema, "revisionKey": identifierSchema, "nodeId": identifierSchema, "type": ["const": type]])
    }

    func instanceEdgeSchema(_ relation: JSONObject) -> JSONObject {
        closedObject([
            "relation": ["const": string(relation["fqid"]) ?? ""],
            "from": instanceRefSchema(string(relation["domain"]) ?? ""),
            "to": instanceRefSchema(string(relation["range"]) ?? "")
        ])
    }

    func instanceGraphTypeScript(_ ir: JSONObject, profile: EventCoreProfileSelection = .legacy) -> String {
        let classes = ir["classes"] as? [JSONObject] ?? []
        let relations = ir["relations"] as? [JSONObject] ?? []
        let nodes = classes.map(instanceNodeTypeScript).joined(separator: "\n  | ")
        let edges = relations.map {
            "{ readonly relation: \"\(string($0["fqid"]) ?? "")\"; readonly from: InstanceRef<\"\(string($0["domain"]) ?? "")\">; readonly to: InstanceRef<\"\(string($0["range"]) ?? "")\"> }"
        }.joined(separator: "\n  | ")
        let profilePin = profile == .provenance
            ? "\n  readonly profilePin: { readonly id: \"\(profile.rawValue)\"; readonly version: \"1.0.0\"; readonly definitionSHA256: \"\(profile.definitionPin["definitionSHA256"] ?? "")\" };" : ""
        return """
        // Generated by ontologyc export-instance-contract. Shapes only; use validate-instances for integrity.
        // Pinned normalized IR SHA256: \(profile.irSHA256)
        export interface InstanceRef<T extends string> { readonly graphKey: string; readonly revisionKey: string; readonly nodeId: string; readonly type: T }
        export type InstanceNode = \(nodes);
        export type InstanceEdge = \(edges);
        export interface InstanceGraph {
          readonly apiVersion: "\(EventCoreInstanceProfile.apiVersion)";
          readonly kind: "InstanceGraph";
          readonly profile: "\(profile.rawValue)";\(profilePin)
          readonly graphKey: string;
          readonly revisionKey: string;
          readonly ontology: { readonly id: "org.0al.events.core"; readonly namespace: "eventcore"; readonly version: "\(profile.ontology["version"] ?? "")"; readonly sourceDigest: "\(profile.ontology["sourceDigest"] ?? "")" };
          readonly projections: readonly { readonly schemaKey: string; readonly projectionKey: string; readonly domain: "observation" | "review" | "normative" }[];
          readonly nodes: readonly InstanceNode[];
          readonly edges: readonly InstanceEdge[];
        }

        """
    }

    func instanceNodeTypeScript(_ definition: JSONObject) -> String {
        let fields = (definition["fields"] as? [JSONObject] ?? []).map {
            "readonly \(string($0["id"]) ?? "")\($0["required"] as? Bool == true ? "" : "?"): \(string($0["type"]) == "integer" ? "number" : "string")"
        }.joined(separator: "; ")
        let state = definition["lifecycle"] != nil ? "; readonly state: \"proposed\" | \"reviewed\" | \"rejected\"" : ""
        return "{ readonly id: string; readonly type: \"\(string(definition["fqid"]) ?? "")\"; readonly fields: { \(fields) }\(state) }"
    }
}
