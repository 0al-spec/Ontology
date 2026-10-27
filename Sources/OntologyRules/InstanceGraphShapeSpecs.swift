import Foundation

struct InstanceGraphShapeCheck {
    let context: InstanceGraphValidationContext
    var issues = [InstanceGraphIssue]()

    mutating func validate() {
        let graph = context.graph
        object(graph, keys: ["apiVersion", "kind", "profile", "graphKey", "revisionKey", "ontology", "projections", "nodes", "edges"], path: "graph")
        equal(graph, key: "apiVersion", expected: EventCoreInstanceProfile.apiVersion, path: "graph")
        equal(graph, key: "kind", expected: "InstanceGraph", path: "graph")
        equal(graph, key: "profile", expected: EventCoreInstanceProfile.name, path: "graph")
        identifier(graph["graphKey"], path: "graph.graphKey")
        identifier(graph["revisionKey"], path: "graph.revisionKey")
        let pin = graph["ontology"] as? GraphObject ?? [:]
        object(pin, keys: Set(EventCoreInstanceProfile.ontology.keys), path: "graph.ontology")
        for (key, value) in EventCoreInstanceProfile.ontology {
            equal(pin, key: key, expected: value, path: "graph.ontology")
            equal(context.ontologyIR, key: key, expected: value, path: "ontologyIR")
        }
        validateProjections(array(graph["projections"], path: "graph.projections", maximum: 1000))
        validateNodes(array(graph["nodes"], path: "graph.nodes", maximum: 10_000))
        validateEdges(array(graph["edges"], path: "graph.edges", maximum: 50_000))
    }

    mutating func object(_ value: GraphObject, keys: Set<String>, path: String) {
        for key in value.keys.sorted() where !keys.contains(key) {
            issues.append(graphIssue("unknownKey", "\(path).\(key)", "Unknown or legacy field is forbidden."))
        }
    }

    mutating func equal(_ object: GraphObject, key: String, expected: String, path: String) {
        if object[key] as? String != expected {
            issues.append(graphIssue("literal", "\(path).\(key)", "Expected \(expected)."))
        }
    }

    mutating func identifier(_ value: Any?, path: String) {
        guard let text = value as? String,
              text.range(of: "^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$", options: .regularExpression) != nil else {
            issues.append(graphIssue("identifier", path, "Expected a non-empty local ASCII identifier (maximum 128 characters)."))
            return
        }
    }

    mutating func array(_ value: Any?, path: String, maximum: Int) -> [GraphObject] {
        guard let items = value as? [Any], items.count <= maximum,
              let objects = items as? [GraphObject] else {
            issues.append(graphIssue("collection", path, "Expected an explicit finite array of objects, at most \(maximum)."))
            return []
        }
        return objects
    }

    mutating func validateProjections(_ projections: [GraphObject]) {
        var seen = Set<String>()
        for (offset, projection) in projections.enumerated() {
            let path = "projections[\(offset)]"
            object(projection, keys: ["projectionKey", "schemaKey", "domain"], path: path)
            for key in ["projectionKey", "schemaKey"] { nonempty(projection[key], path: "\(path).\(key)") }
            if !["observation", "review", "normative"].contains(graphText(projection, "domain")) {
                issues.append(graphIssue("projection.domain", path, "Expected observation, review or normative domain."))
            }
            if !seen.insert(graphText(projection, "projectionKey")).inserted {
                issues.append(graphIssue("projection.duplicate", path, "Projection key must be unique."))
            }
        }
    }

    mutating func validateNodes(_ nodes: [GraphObject]) {
        let classes = context.ontologyIR["classes"] as? [GraphObject] ?? []
        var seen = Set<String>()
        for (offset, node) in nodes.enumerated() {
            let path = "nodes[\(offset)]"
            object(node, keys: ["id", "type", "fields", "state"], path: path)
            identifier(node["id"], path: "\(path).id")
            if !seen.insert(graphText(node, "id")).inserted {
                issues.append(graphIssue("node.duplicate", path, "Node id must be unique within this graph revision."))
            }
            guard let definition = classes.first(where: { graphText($0, "fqid") == graphText(node, "type") }) else {
                issues.append(graphIssue("node.type", path, "Node type is not declared in the pinned ontology."))
                continue
            }
            validateFields(node["fields"], definition: definition, path: "\(path).fields")
            validateState(node, definition: definition, path: path)
        }
    }

    mutating func validateFields(_ value: Any?, definition: GraphObject, path: String) {
        guard let fields = value as? GraphObject else {
            issues.append(graphIssue("fields.object", path, "An explicit scalar field object is required."))
            return
        }
        let definitions = definition["fields"] as? [GraphObject] ?? []
        object(fields, keys: Set(definitions.map { graphText($0, "id") }), path: path)
        for field in definitions {
            let key = graphText(field, "id")
            if let value = fields[key] {
                if !validScalar(value, type: graphText(field, "type")) {
                    issues.append(graphIssue("field.type", "\(path).\(key)", "Expected \(graphText(field, "type")); integers must be safe and booleans are not numbers."))
                }
            } else if field["required"] as? Bool == true {
                issues.append(graphIssue("field.required", "\(path).\(key)", "Required field is missing."))
            }
        }
    }

    func validScalar(_ value: Any, type: String) -> Bool {
        switch type {
        case "string": (value as? String)?.isEmpty == false
        case "integer": graphInteger(value) != nil
        default: false // This pinned package has only string/integer data fields.
        }
    }

    mutating func validateState(_ node: GraphObject, definition: GraphObject, path: String) {
        let lifecycle = graphText(definition, "lifecycle")
        if lifecycle.isEmpty {
            if node["state"] != nil { issues.append(graphIssue("state.forbidden", path, "This class has no lifecycle state.")) }
        } else if !["proposed", "reviewed", "rejected"].contains(graphText(node, "state")) {
            issues.append(graphIssue("state.invalid", path, "ProposalReview requires proposed, reviewed or rejected state."))
        }
    }

    mutating func validateEdges(_ edges: [GraphObject]) {
        for (offset, edge) in edges.enumerated() {
            let path = "edges[\(offset)]"
            object(edge, keys: ["relation", "from", "to"], path: path)
            nonempty(edge["relation"], path: "\(path).relation")
            for end in ["from", "to"] {
                guard let ref = edge[end] as? GraphObject else {
                    issues.append(graphIssue("ref.object", "\(path).\(end)", "A typed snapshot-local reference is required."))
                    continue
                }
                object(ref, keys: ["graphKey", "revisionKey", "nodeId", "type"], path: "\(path).\(end)")
                for key in ["graphKey", "revisionKey", "nodeId", "type"] { identifier(ref[key], path: "\(path).\(end).\(key)") }
            }
        }
    }

    mutating func nonempty(_ value: Any?, path: String) {
        if (value as? String)?.isEmpty != false {
            issues.append(graphIssue("string", path, "A non-empty string is required."))
        }
    }
}
