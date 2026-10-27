struct InstanceGraphLinkCheck {
    let index: InstanceGraphIndex
    var issues = [InstanceGraphIssue]()

    mutating func validate() {
        let definitions = index.ontologyIR["relations"] as? [GraphObject] ?? []
        var seen = Set<[String]>()
        for (offset, edge) in index.edges.enumerated() {
            let path = "edges[\(offset)]"
            let relation = graphText(edge, "relation")
            guard let definition = definitions.first(where: { graphText($0, "fqid") == relation }) else {
                issues.append(graphIssue("relation.unknown", path, "Relation is not declared in the pinned ontology."))
                continue
            }
            let from = edge["from"] as? GraphObject ?? [:]
            let to = edge["to"] as? GraphObject ?? [:]
            validateReference(from, path: "\(path).from")
            validateReference(to, path: "\(path).to")
            if graphText(from, "type") != graphText(definition, "domain") || graphText(to, "type") != graphText(definition, "range") {
                issues.append(graphIssue("relation.endpoints", path, "Reference types must match the relation's exact domain/range."))
            }
            if !seen.insert([relation, graphText(from, "nodeId"), graphText(to, "nodeId")]).inserted {
                issues.append(graphIssue("edge.duplicate", path, "Duplicate relation edge is forbidden."))
            }
        }
        validateCardinalities(definitions)
    }

    mutating func validateReference(_ reference: GraphObject, path: String) {
        if graphText(reference, "graphKey") != graphText(index.graph, "graphKey") ||
            graphText(reference, "revisionKey") != graphText(index.graph, "revisionKey") {
            issues.append(graphIssue("ref.scope", path, "Reference belongs to another graph revision."))
        }
        guard let target = index.byID[graphText(reference, "nodeId")] else {
            issues.append(graphIssue("ref.missing", path, "Reference target is absent."))
            return
        }
        if graphText(target, "type") != graphText(reference, "type") {
            issues.append(graphIssue("ref.type", path, "Reference type does not match its target node."))
        }
    }

    mutating func validateCardinalities(_ definitions: [GraphObject]) {
        for definition in definitions {
            let relation = graphText(definition, "fqid")
            let cardinality = definition["cardinality"] as? GraphObject ?? [:]
            let minimum = cardinality["min"] as? Int ?? 0
            let maximum = cardinality["max"] as? Int
            for node in index.nodes where graphText(node, "type") == graphText(definition, "domain") {
                let count = index.links[[graphText(node, "id"), relation]]?.count ?? 0
                if count < minimum || maximum.map({ count > $0 }) == true {
                    issues.append(graphIssue("relation.cardinality", "\(index.path(node)).\(relation)", "Relation cardinality is outside its declared bounds."))
                }
            }
        }
    }
}
