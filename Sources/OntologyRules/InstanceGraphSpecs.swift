import CoreFoundation
import Foundation
import SpecificationCore

/// JSON objects used by the bounded, non-executable instance graph profile.
package typealias InstanceGraphObject = [String: Any]
typealias GraphObject = InstanceGraphObject

/// Pins the exact reviewed vocabulary and its deterministic normalized artifact.
package enum EventCoreInstanceProfile {
    package static let name = "eventcore-v1"
    package static let apiVersion = "ontology.specgraph.io/instance-graph/v1alpha1"
    package static let irSHA256 = "2c596f08073653e8a47df8e46aa1b1b75284717d32148d162d497775ce5a31a0"
    package static let sourceDigest = "sha256:be771a8caa40e1ac23cb11fdb2f12a6ef7f8e166b12ef46f9d7d022a23944424"
    package static let ontology = [
        "id": "org.0al.events.core", "namespace": "eventcore", "version": "0.1.0",
        "sourceDigest": sourceDigest
    ]
}

/// One stable structural diagnostic, not a verdict about factual truth.
package struct InstanceGraphIssue: Equatable, Sendable {
    package let code: String
    package let path: String
    package let message: String
}

/// Package-internal input after the compiler has checked exact IR integrity.
/// Consumers must use OntologyCompiler.validateInstanceGraph or the CLI.
package struct InstanceGraphValidationContext {
    package let graph: InstanceGraphObject
    package let ontologyIR: InstanceGraphObject

    package init(graph: InstanceGraphObject, ontologyIR: InstanceGraphObject) {
        self.graph = graph
        self.ontologyIR = ontologyIR
    }
}

/// Checks shape, reference integrity, then the explicitly selected event profile.
package struct InstanceGraphValidationSpec: DecisionSpec {
    package init() {}

    package func decide(_ context: InstanceGraphValidationContext) -> [InstanceGraphIssue]? {
        var shape = InstanceGraphShapeCheck(context: context)
        shape.validate()
        guard shape.issues.isEmpty else { return sorted(shape.issues) }
        let index = InstanceGraphIndex(context: context)
        var links = InstanceGraphLinkCheck(index: index)
        links.validate()
        guard links.issues.isEmpty else { return sorted(links.issues) }
        var profile = EventCoreGraphCheck(index: index)
        profile.validate()
        return sorted(profile.issues)
    }

    private func sorted(_ issues: [InstanceGraphIssue]) -> [InstanceGraphIssue] {
        issues.sorted { [$0.path, $0.code, $0.message].lexicographicallyPrecedes([$1.path, $1.code, $1.message]) }
    }
}

func graphText(_ object: GraphObject, _ key: String) -> String {
    object[key] as? String ?? ""
}

func graphFields(_ node: GraphObject) -> GraphObject {
    node["fields"] as? GraphObject ?? [:]
}

func graphInteger(_ value: Any?) -> Double? {
    guard let number = value as? NSNumber,
          CFGetTypeID(number) != CFBooleanGetTypeID() else { return nil }
    let value = number.doubleValue
    return value.isFinite && abs(value) <= 9_007_199_254_740_991 && value.rounded() == value ? value : nil
}

func graphIssue(_ code: String, _ path: String, _ message: String) -> InstanceGraphIssue {
    InstanceGraphIssue(code: "instanceGraph.\(code)", path: path, message: message)
}

struct InstanceGraphIndex {
    let graph: GraphObject
    let ontologyIR: GraphObject
    let nodes: [GraphObject]
    let edges: [GraphObject]
    let byID: [String: GraphObject]
    let links: [[String]: [String]]

    init(context: InstanceGraphValidationContext) {
        graph = context.graph
        ontologyIR = context.ontologyIR
        nodes = graph["nodes"] as? [GraphObject] ?? []
        edges = graph["edges"] as? [GraphObject] ?? []
        byID = Dictionary(uniqueKeysWithValues: nodes.map { (graphText($0, "id"), $0) })
        var collected = [[String]: [String]]()
        for edge in edges {
            let from = edge["from"] as? GraphObject ?? [:]
            let to = edge["to"] as? GraphObject ?? [:]
            collected[[graphText(from, "nodeId"), graphText(edge, "relation")], default: []].append(graphText(to, "nodeId"))
        }
        links = collected
    }

    func nodes(of type: String) -> [GraphObject] {
        nodes.filter { graphText($0, "type") == "eventcore:\(type)" }
    }

    func targets(_ node: GraphObject, _ relation: String) -> [GraphObject] {
        (links[[graphText(node, "id"), "eventcore:\(relation)"]] ?? []).compactMap { byID[$0] }
    }

    func target(_ node: GraphObject, _ relation: String) -> GraphObject {
        targets(node, relation).first ?? [:]
    }

    func path(_ node: GraphObject) -> String { "nodes[\(graphText(node, "id"))]" }
}
