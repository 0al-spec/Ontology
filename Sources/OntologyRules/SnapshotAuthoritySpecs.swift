import Foundation

/// The caller must select this document from trusted storage, independently of
/// the graph. Hash binding prevents stale confirmations, not dishonest callers.
struct SnapshotAuthorityCheck {
    let context: InstanceGraphValidationContext
    let document: GraphObject
    var issues = [InstanceGraphIssue]()
    let capabilities: Set<String> = ["confirm-source", "confirm-observation", "supply-operator-state", "enrich-candidate"]

    mutating func validate() {
        object(document, keys: ["apiVersion", "kind", "profilePin", "graphKey", "revisionKey", "graphSHA256", "grants", "confirmations", "enrichments"], path: "authority")
        equal(document, "apiVersion", "ontology.specgraph.io/snapshot-authority/v1alpha1", path: "authority")
        equal(document, "kind", "SnapshotProvenanceAuthority", path: "authority")
        equal(document, "graphKey", graphText(context.graph, "graphKey"), path: "authority")
        equal(document, "revisionKey", graphText(context.graph, "revisionKey"), path: "authority")
        if context.graphSHA256.isEmpty || graphText(document, "graphSHA256") != context.graphSHA256 {
            issue("binding", "authority.graphSHA256", "Authority confirmations must bind the exact graph bytes; changed graphs need explicit reconfirmation.")
        }
        let pin = document["profilePin"] as? GraphObject ?? [:]
        object(pin, keys: Set(context.profile.definitionPin.keys), path: "authority.profilePin")
        for (key, value) in context.profile.definitionPin { equal(pin, key, value, path: "authority.profilePin") }
        var grants = Set<String>()
        for (offset, grant) in array(document["grants"], path: "authority.grants").enumerated() {
            let path = "authority.grants[\(offset)]"
            object(grant, keys: ["authorityKey", "capabilities", "scopeKeys", "projectionKeys"], path: path)
            nonempty(grant["authorityKey"], path: "\(path).authorityKey")
            if !grants.insert(graphText(grant, "authorityKey")).inserted { issue("duplicate", path, "Duplicate authority key is forbidden.") }
            let values = strings(grant["capabilities"], path: "\(path).capabilities")
            if !Set(values).isSubset(of: capabilities) { issue("capability", path, "Unknown authority capability.") }
            _ = strings(grant["scopeKeys"], path: "\(path).scopeKeys")
            _ = strings(grant["projectionKeys"], path: "\(path).projectionKeys")
        }
        validateEntries("confirmations", keys: ["snapshotId", "originId", "authorityKey", "rationale"], identity: ["snapshotId"])
        validateEntries("enrichments", keys: ["candidateId", "recordId", "authorityKey", "rationale"], identity: ["candidateId", "recordId"])
    }

    mutating func validateEntries(_ collection: String, keys: Set<String>, identity: [String]) {
        var seen = Set<[String]>()
        for (offset, entry) in array(document[collection], path: "authority.\(collection)").enumerated() {
            let path = "authority.\(collection)[\(offset)]"
            object(entry, keys: keys, path: path)
            for key in keys { nonempty(entry[key], path: "\(path).\(key)") }
            if !seen.insert(identity.map { graphText(entry, $0) }).inserted { issue("duplicate", path, "Duplicate confirmation identity is forbidden.") }
        }
    }

    mutating func object(_ value: GraphObject, keys: Set<String>, path: String) {
        for key in value.keys.sorted() where !keys.contains(key) { issue("shape", "\(path).\(key)", "Unknown authority field is forbidden.") }
    }

    mutating func equal(_ object: GraphObject, _ key: String, _ expected: String, path: String) {
        if object[key] as? String != expected { issue("literal", "\(path).\(key)", "Expected \(expected).") }
    }

    mutating func nonempty(_ value: Any?, path: String) {
        if (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty != false {
            issue("shape", path, "An explicit nonblank string is required.")
        }
    }

    mutating func strings(_ value: Any?, path: String) -> [String] {
        guard let values = value as? [String], !values.isEmpty, values.count <= 1000,
              Set(values).count == values.count,
              values.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0 != "*" }) else {
            issue("shape", path, "Expected unique explicit strings, at most 1000; no wildcards or empty grants.")
            return []
        }
        return values
    }

    mutating func array(_ value: Any?, path: String) -> [GraphObject] {
        guard let items = value as? [GraphObject], items.count <= 10_000 else {
            issue("shape", path, "Expected an explicit finite array of authority objects, at most 10000.")
            return []
        }
        return items
    }

    mutating func issue(_ suffix: String, _ path: String, _ message: String) {
        issues.append(graphIssue("provenance.authority.\(suffix)", path, message))
    }
}
