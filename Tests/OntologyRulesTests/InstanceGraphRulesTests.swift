import Foundation
@testable import OntologyRules
import XCTest

final class InstanceGraphRulesTests: XCTestCase {
    typealias Object = [String: Any]

    var root: URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }

    func fixture(_ name: String = "synthetic-car") throws -> Object {
        try load("SPECS/ontology/fixtures/instance-graphs/\(name).json")
    }

    func load(_ path: String) throws -> Object {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: root.appendingPathComponent(path))) as? Object)
    }

    func issues(_ graph: Object) throws -> [InstanceGraphIssue] {
        let ir = try load("SPECS/ontology/packages/events-core/generated/ontology.normalized.json")
        return try XCTUnwrap(InstanceGraphValidationSpec().decide(.init(graph: graph, ontologyIR: ir)))
    }

    func change(_ graph: inout Object, node id: String, _ update: (inout Object) -> Void) throws {
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        let offset = try XCTUnwrap(nodes.firstIndex { $0["id"] as? String == id })
        update(&nodes[offset])
        graph["nodes"] = nodes
    }

    func field(_ graph: inout Object, node: String, key: String, value: Any?) throws {
        try change(&graph, node: node) {
            var fields = $0["fields"] as? Object ?? [:]
            fields[key] = value
            $0["fields"] = fields
        }
    }

    func remove(_ graph: inout Object, relation: String, from: String? = nil) throws {
        let edges = try XCTUnwrap(graph["edges"] as? [Object])
        graph["edges"] = edges.filter { edge in
            let source = (edge["from"] as? Object)?["nodeId"] as? String
            return edge["relation"] as? String != "eventcore:\(relation)" || (from != nil && source != from)
        }
    }

    func append(_ graph: inout Object, relation: String, from: String, to: String) throws {
        let nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        func ref(_ id: String) throws -> Object {
            let node = try XCTUnwrap(nodes.first { $0["id"] as? String == id })
            return ["graphKey": graph["graphKey"] ?? "", "revisionKey": graph["revisionKey"] ?? "", "nodeId": id, "type": node["type"] ?? ""]
        }
        var edges = try XCTUnwrap(graph["edges"] as? [Object])
        edges.append(["relation": "eventcore:\(relation)", "from": try ref(from), "to": try ref(to)])
        graph["edges"] = edges
    }

    func assertCode(_ graph: Object, _ suffix: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let result = try issues(graph)
        XCTAssertTrue(result.contains { $0.code == "instanceGraph.\(suffix)" }, "\(result)", file: file, line: line)
    }

    func testValidOverlappingChainAndSourceOnlyCandidates() throws {
        XCTAssertEqual(try issues(fixture()), [])
        XCTAssertEqual(try issues(fixture("source-only")), [])
    }

    func testRequiredTypesUnknownKeysAndSafeIntegers() throws {
        for value: Any in [true, 1.5, 9_007_199_254_740_992.0, NSNull()] {
            var graph = try fixture()
            try field(&graph, node: "movement", key: "intervalStart", value: value)
            try assertCode(graph, "field.type")
        }
        try assertCode(fixture("missing-interval"), "field.required")
        var graph = try fixture()
        try field(&graph, node: "before", key: "complete", value: false)
        try assertCode(graph, "unknownKey")
    }

    func testReferenceScopeTypeExistenceAndDuplicateEdges() throws {
        for (key, value, code) in [("revisionKey", "wrong", "ref.scope"), ("nodeId", "ghost", "ref.missing"), ("type", "eventcore:Entity", "ref.type")] {
            var graph = try fixture()
            var edges = try XCTUnwrap(graph["edges"] as? [Object])
            var ref = try XCTUnwrap(edges[0]["from"] as? Object)
            ref[key] = value
            edges[0]["from"] = ref
            graph["edges"] = edges
            try assertCode(graph, code)
        }
        var graph = try fixture()
        var edges = try XCTUnwrap(graph["edges"] as? [Object])
        edges.append(try XCTUnwrap(edges.first))
        graph["edges"] = edges
        try assertCode(graph, "edge.duplicate")
    }

    func testRecordIdentityAndDirectStateCardinality() throws {
        var graph = try fixture()
        try field(&graph, node: "omission", key: "recordKey", value: "movement")
        try assertCode(graph, "record.duplicate")
        graph = try fixture()
        try remove(&graph, relation: "recordBeforeSnapshot", from: "movement")
        try assertCode(graph, "relation.cardinality")
        graph = try fixture()
        try field(&graph, node: "after", key: "scopeKey", value: "other-episode")
        try assertCode(graph, "record.snapshots")
    }

    func testObservationAlternativesAndReviewProjection() throws {
        var graph = try fixture()
        try append(&graph, relation: "observationSuppliesFact", from: "unknown-before", to: "road")
        try assertCode(graph, "observation.shape")
        try field(&graph, node: "unknown-before", key: "availability", value: "partial")
        XCTAssertEqual(try issues(graph), [])
        graph = try fixture()
        try field(&graph, node: "unknown-before", key: "availability", value: "known")
        try assertCode(graph, "observation.shape")
        try append(&graph, relation: "observationSnapshot", from: "unknown-before", to: "before")
        XCTAssertEqual(try issues(graph), [])
        graph["projections"] = [["projectionKey": "location", "schemaKey": "location-v1", "domain": "review"]]
        try assertCode(graph, "record.snapshots")
    }

    func testExactDeltaAndKnownEmptyControl() throws {
        var graph = try fixture()
        try remove(&graph, relation: "deltaAddsFact")
        try assertCode(graph, "delta.exact")
        graph = try fixture()
        try remove(&graph, relation: "snapshotContainsFact")
        try remove(&graph, relation: "deltaAddsFact")
        try remove(&graph, relation: "deltaRemovesFact")
        XCTAssertEqual(try issues(graph), [])
        try append(&graph, relation: "deltaAddsFact", from: "movement-delta", to: "parking")
        try assertCode(graph, "delta.exact")
    }

    func testDuplicateDeltaRejectedEvenWhenIdentical() throws {
        var graph = try fixture()
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "duplicate-delta", "type": "eventcore:Delta", "fields": Object()])
        graph["nodes"] = nodes
        for (relation, target) in [("deltaOfRecord", "movement"), ("deltaAddsFact", "parking"), ("deltaRemovesFact", "road")] {
            try append(&graph, relation: relation, from: "duplicate-delta", to: target)
        }
        try assertCode(graph, "delta.duplicate")
    }

    func testCausalEndpointsClockTemporalAndLifecycle() throws {
        for (node, key, value, code): (String, String, Any, String) in [
            ("omission", "intervalStart", 10, "hypothesis.order"),
            ("omission", "clockKey", "other", "hypothesis.clock"),
            ("movement", "intervalFinish", 2, "record.interval")
        ] {
            var graph = try fixture()
            try field(&graph, node: node, key: key, value: value)
            try assertCode(graph, code)
        }
        var graph = try fixture()
        try change(&graph, node: "causal-link") { $0["state"] = "true" }
        try assertCode(graph, "state.invalid")
    }

    func testRoleReinterpretationAndOpposedSupportRemainScoped() throws {
        var graph = try fixture()
        try field(&graph, node: "car-role", key: "roleName", value: "instrument")
        let result = try issues(graph)
        XCTAssertEqual(result, [])
        try field(&graph, node: "brake", key: "propositionKey", value: "road")
        try field(&graph, node: "brake", key: "polarity", value: "negative")
        try append(&graph, relation: "snapshotContainsFact", from: "before", to: "brake")
        try append(&graph, relation: "deltaRemovesFact", from: "movement-delta", to: "brake")
        XCTAssertEqual(try issues(graph), [])
    }

    func testInterpretationCannotReplaceRecordSnapshots() throws {
        var graph = try fixture()
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "alternate-view", "type": "eventcore:Interpretation", "fields": ["interpretationKey": "alternate"]])
        graph["nodes"] = nodes
        try append(&graph, relation: "interpretsRecord", from: "alternate-view", to: "movement")
        try append(&graph, relation: "interpretationBindsRole", from: "alternate-view", to: "owner-role")
        XCTAssertEqual(try issues(graph), [])
        try append(&graph, relation: "recordBeforeSnapshot", from: "alternate-view", to: "after")
        try assertCode(graph, "relation.endpoints")
    }
}
