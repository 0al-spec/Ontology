import Foundation
import CoreFoundation

private let ontologyPackageSections = [
    "Metadata",
    "Imports",
    "Classes",
    "Relations",
    "Policies",
    "StateMachines",
    "Compatibility"
]

extension OntologyCompiler {
    func isHypercodeOntologyPackageRoot(_ root: JSONObject) -> Bool {
        guard string(root["type"]) == "Package" else { return false }
        let sectionTypes = Set(children(root).compactMap { string($0["type"]) })
        return Set(ontologyPackageSections).isSubset(of: sectionTypes)
    }

    func hypercodeOntologyPackage(_ root: JSONObject, sourcePath: String) throws -> JSONObject {
        let sections = try uniqueChildrenByType(root, path: "nodes[0]")
        for section in ontologyPackageSections where sections[section] == nil {
            throw OntologyCompilerError.invalidArgument(
                "Hypercode ontology package is missing \(section) section in \(sourcePath)"
            )
        }

        let metadata = propertyValues(try requiredNode(sections, "Metadata", sourcePath: sourcePath))
        let approvalStatus = try requiredStringProperty(
            metadata,
            "approval_status",
            path: "Metadata.approval_status"
        )
        guard approvalStatus == "draft" else {
            throw OntologyCompilerError.invalidArgument(
                "Hypercode ontology package Metadata.approval_status must be draft for import-hypercode"
            )
        }
        let spec: JSONObject = [
            "imports": try hypercodeOntologyImports(try requiredNode(sections, "Imports", sourcePath: sourcePath)),
            "classes": try hypercodeOntologyClasses(try requiredNode(sections, "Classes", sourcePath: sourcePath)),
            "protocols": JSONObject(),
            "relations": try hypercodeOntologyRelations(try requiredNode(sections, "Relations", sourcePath: sourcePath)),
            "policies": try hypercodeOntologyPolicies(try requiredNode(sections, "Policies", sourcePath: sourcePath)),
            "stateMachines": try hypercodeOntologyStateMachines(
                try requiredNode(sections, "StateMachines", sourcePath: sourcePath)
            ),
            "compatibility": try hypercodeOntologyCompatibility(
                try requiredNode(sections, "Compatibility", sourcePath: sourcePath)
            )
        ]
        return [
            "apiVersion": apiVersion,
            "kind": kind,
            "metadata": [
                "id": try requiredStringProperty(metadata, "package_id", path: "Metadata.package_id"),
                "namespace": try requiredStringProperty(metadata, "namespace", path: "Metadata.namespace"),
                "version": try requiredStringProperty(metadata, "version", path: "Metadata.version"),
                "publisher": optionalStringProperty(metadata, "publisher") ?? "ontologyc import-hypercode",
                "source": optionalStringProperty(metadata, "source") ?? sourcePath,
                "approvalStatus": approvalStatus
            ],
            "spec": spec
        ]
    }

    private func hypercodeOntologyImports(_ section: JSONObject) throws -> [JSONObject] {
        try requireNonEmptyChildren(section, type: "Import", section: "Imports").map { node in
            let values = propertyValues(node)
            var entry: JSONObject = [
                "id": try requiredStringProperty(values, "import_id", path: "\(nodePath(node)).import_id"),
                "version": try requiredStringProperty(values, "version", path: "\(nodePath(node)).version")
            ]
            if let namespace = optionalStringProperty(values, "namespace") {
                entry["namespace"] = namespace
            }
            return entry
        }
    }

    private func hypercodeOntologyClasses(_ section: JSONObject) throws -> JSONObject {
        var classes = JSONObject()
        for node in try requireNonEmptyChildren(section, type: "Class", section: "Classes") {
            let id = try requiredNodeID(node)
            let values = propertyValues(node)
            var entry: JSONObject = [
                "extends": try requiredStringProperty(values, "extends", path: "\(nodePath(node)).extends"),
                "description": try requiredStringProperty(values, "description", path: "\(nodePath(node)).description")
            ]
            if let implements = values["implements"] {
                entry["implements"] = try csv(implements, path: "\(nodePath(node)).implements")
            }
            if let lifecycle = string(values["lifecycle"]) {
                entry["lifecycle"] = lifecycle
            }
            if bool(values["central"]) == true {
                entry["central"] = true
            }
            try addHypercodeOntologyFields(to: &entry, from: node)
            try put(&classes, key: id, value: entry, kind: "class")
        }
        return classes
    }

    private func addHypercodeOntologyFields(to entry: inout JSONObject, from node: JSONObject) throws {
        let fieldNodes = children(node, type: "Field")
        guard !fieldNodes.isEmpty else { return }
        var fields = JSONObject()
        for field in fieldNodes {
            let fieldId = try requiredNodeID(field)
            let fieldValues = propertyValues(field)
            var fieldEntry: JSONObject = [
                "type": try requiredStringProperty(fieldValues, "type", path: "\(nodePath(field)).type"),
                "required": try requiredBoolProperty(fieldValues, "required", path: "\(nodePath(field)).required")
            ]
            if let description = string(fieldValues["description"]) {
                fieldEntry["description"] = description
            }
            try put(&fields, key: fieldId, value: fieldEntry, kind: "field")
        }
        entry["fields"] = fields
    }

    private func hypercodeOntologyRelations(_ section: JSONObject) throws -> JSONObject {
        var relations = JSONObject()
        for node in try requireNonEmptyChildren(section, type: "Relation", section: "Relations") {
            let id = try requiredNodeID(node)
            let values = propertyValues(node)
            let targets = try csv(
                try requiredProperty(values, "range", path: "\(nodePath(node)).range"),
                path: "\(nodePath(node)).range"
            )
            var entry = try hypercodeOntologyRelationEntry(node: node, values: values, targets: targets)
            if let description = string(values["description"]) {
                entry["description"] = description
            }
            try put(&relations, key: id, value: entry, kind: "relation")
        }
        return relations
    }

    private func hypercodeOntologyRelationEntry(
        node: JSONObject,
        values: JSONObject,
        targets: [String]
    ) throws -> JSONObject {
        [
            "domain": try requiredStringProperty(values, "domain", path: "\(nodePath(node)).domain"),
            "range": targets.count == 1 ? targets[0] : ["oneOf": targets],
            "cardinality": [
                "min": try cardinalityBound(
                    try requiredProperty(values, "card_min", path: "\(nodePath(node)).card_min"),
                    path: "\(nodePath(node)).card_min"
                ),
                "max": try cardinalityBound(
                    try requiredProperty(values, "card_max", path: "\(nodePath(node)).card_max"),
                    path: "\(nodePath(node)).card_max"
                )
            ]
        ]
    }

    private func hypercodeOntologyPolicies(_ section: JSONObject) throws -> JSONObject {
        var policies = JSONObject()
        for node in try requireNonEmptyChildren(section, type: "Policy", section: "Policies") {
            let id = try requiredNodeID(node)
            let values = propertyValues(node)
            try put(&policies, key: id, value: [
                "extends": try requiredStringProperty(values, "extends", path: "\(nodePath(node)).extends"),
                "enforceability": try requiredStringProperty(
                    values,
                    "enforceability",
                    path: "\(nodePath(node)).enforceability"
                ),
                "appliesTo": try csv(
                    try requiredProperty(values, "applies_to", path: "\(nodePath(node)).applies_to"),
                    path: "\(nodePath(node)).applies_to"
                ),
                "text": try requiredStringProperty(values, "text", path: "\(nodePath(node)).text")
            ], kind: "policy")
        }
        return policies
    }

    private func hypercodeOntologyStateMachines(_ section: JSONObject) throws -> JSONObject {
        var machines = JSONObject()
        for node in try requireNonEmptyChildren(section, type: "Machine", section: "StateMachines") {
            let id = try requiredNodeID(node)
            let values = propertyValues(node)
            try put(&machines, key: id, value: [
                "states": try csv(
                    try requiredProperty(values, "states", path: "\(nodePath(node)).states"),
                    path: "\(nodePath(node)).states"
                ),
                "transitions": try hypercodeOntologyTransitions(node)
            ], kind: "state machine")
        }
        return machines
    }

    private func hypercodeOntologyTransitions(_ node: JSONObject) throws -> [JSONObject] {
        try children(node, type: "Transition").map { transition in
            let values = propertyValues(transition)
            var entry: JSONObject = [
                "from": try requiredStringProperty(values, "from", path: "\(nodePath(transition)).from"),
                "to": try requiredStringProperty(values, "to", path: "\(nodePath(transition)).to")
            ]
            if let command = string(values["command"]) {
                entry["command"] = command
            }
            if let event = string(values["event"]) {
                entry["event"] = event
            }
            return entry
        }
    }

    private func hypercodeOntologyCompatibility(_ section: JSONObject) throws -> JSONObject {
        let values = propertyValues(section)
        return [
            "patch": [
                "allowed": try csv(
                    try requiredProperty(values, "patch_allowed", path: "Compatibility.patch_allowed"),
                    path: "Compatibility.patch_allowed"
                )
            ],
            "minor": [
                "allowed": try csv(
                    try requiredProperty(values, "minor_allowed", path: "Compatibility.minor_allowed"),
                    path: "Compatibility.minor_allowed"
                )
            ],
            "major": [
                "requires": try csv(
                    try requiredProperty(values, "major_requires", path: "Compatibility.major_requires"),
                    path: "Compatibility.major_requires"
                )
            ]
        ]
    }

    private func uniqueChildrenByType(_ node: JSONObject, path: String) throws -> [String: JSONObject] {
        var byType = [String: JSONObject]()
        for child in children(node) {
            guard let type = string(child["type"]), !type.isEmpty else {
                throw OntologyCompilerError.invalidArgument("Hypercode node at \(path) has a child without type")
            }
            if byType[type] != nil {
                throw OntologyCompilerError.invalidArgument("Hypercode ontology package has duplicate \(type) section")
            }
            byType[type] = child
        }
        return byType
    }

    private func requiredNode(_ nodes: [String: JSONObject], _ type: String, sourcePath: String) throws -> JSONObject {
        guard let node = nodes[type] else {
            throw OntologyCompilerError.invalidArgument(
                "Hypercode ontology package is missing \(type) section in \(sourcePath)"
            )
        }
        return node
    }

    private func requireNonEmptyChildren(
        _ node: JSONObject,
        type: String,
        section: String
    ) throws -> [JSONObject] {
        let nodes = children(node, type: type)
        guard !nodes.isEmpty else {
            throw OntologyCompilerError.invalidArgument(
                "Hypercode ontology package \(section) must contain at least one \(type)"
            )
        }
        return nodes
    }

    private func children(_ node: JSONObject, type: String? = nil) -> [JSONObject] {
        guard let rawChildren = node["children"] as? [Any] else { return [] }
        return rawChildren.compactMap { child in
            guard let object = child as? JSONObject else { return nil }
            if let type {
                return string(object["type"]) == type ? object : nil
            }
            return object
        }
    }

    private func propertyValues(_ node: JSONObject) -> JSONObject {
        guard let properties = node["properties"] as? JSONObject else { return [:] }
        var values = JSONObject()
        for (key, entry) in properties {
            if let object = entry as? JSONObject, let value = object["value"] {
                values[key] = value
            }
        }
        return values
    }

    private func requiredNodeID(_ node: JSONObject) throws -> String {
        guard let id = string(node["id"]), !id.isEmpty else {
            throw OntologyCompilerError.invalidArgument("Hypercode \(nodePath(node)) is missing id")
        }
        return id
    }

    private func nodePath(_ node: JSONObject) -> String {
        let type = string(node["type"]) ?? "node"
        if let id = string(node["id"]) {
            return "\(type)#\(id)"
        }
        return type
    }

    private func requiredProperty(_ values: JSONObject, _ key: String, path: String) throws -> Any {
        guard let value = values[key] else {
            throw OntologyCompilerError.invalidArgument("Hypercode ontology package missing property \(path)")
        }
        return value
    }

    private func requiredStringProperty(_ values: JSONObject, _ key: String, path: String) throws -> String {
        let value = try requiredProperty(values, key, path: path)
        guard let text = string(value), !text.isEmpty else {
            throw OntologyCompilerError.invalidArgument("Hypercode ontology package property \(path) must be a string")
        }
        return text
    }

    private func optionalStringProperty(_ values: JSONObject, _ key: String) -> String? {
        guard let text = string(values[key]), !text.isEmpty else { return nil }
        return text
    }

    private func requiredBoolProperty(_ values: JSONObject, _ key: String, path: String) throws -> Bool {
        let value = try requiredProperty(values, key, path: path)
        guard let boolean = bool(value) else {
            throw OntologyCompilerError.invalidArgument("Hypercode ontology package property \(path) must be a bool")
        }
        return boolean
    }

    private func bool(_ value: Any?) -> Bool? {
        value as? Bool
    }

    private func csv(_ value: Any, path: String) throws -> [String] {
        guard let text = string(value) else {
            throw OntologyCompilerError.invalidArgument("Hypercode ontology package property \(path) must be a comma list")
        }
        let values = text.split(
            separator: ",",
            omittingEmptySubsequences: false
        ).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard !values.isEmpty, values.allSatisfy({ !$0.isEmpty }) else {
            throw OntologyCompilerError.invalidArgument("Hypercode ontology package property \(path) must not be empty")
        }
        return values
    }

    private func cardinalityBound(_ value: Any, path: String) throws -> Any {
        if let int = value as? Int {
            return int
        }
        if let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() {
            return number.intValue
        }
        if let text = string(value), !text.isEmpty {
            return text
        }
        throw OntologyCompilerError.invalidArgument("Hypercode ontology package property \(path) must be int or string")
    }

    private func put(_ collection: inout JSONObject, key: String, value: Any, kind: String) throws {
        guard collection[key] == nil else {
            throw OntologyCompilerError.invalidArgument("malformed package: duplicate \(kind) '\(key)'")
        }
        collection[key] = value
    }
}
