import Foundation
import XCTest

extension InstanceGraphRulesTests {
    func testEpisodeScopeIdentityMustBeUniqueInGraphRevision() throws {
        var graph = try fixture()
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "episode-alias", "type": "eventcore:Episode", "fields": ["scopeKey": "episode-1"]])
        graph["nodes"] = nodes
        try assertCode(graph, "episode.duplicate")
    }

    func testInvalidOrIncomparableIntervalsDoNotProduceOrderDiagnostics() throws {
        var graph = try fixture()
        try field(&graph, node: "movement", key: "intervalStart", value: -1)
        var codes = try issues(graph).map(\.code)
        XCTAssertEqual(codes, ["instanceGraph.record.interval"])
        graph = try fixture()
        try field(&graph, node: "omission", key: "intervalStart", value: 10)
        try field(&graph, node: "omission", key: "clockKey", value: "other-clock")
        codes = try issues(graph).map(\.code)
        XCTAssertEqual(codes, ["instanceGraph.hypothesis.clock"])
    }

    func testIdentityProjectionAndCollectionShapeFailures() throws {
        var graph = try fixture()
        graph["nodes"] = NSNull()
        try assertCode(graph, "collection")
        graph = try fixture()
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(try XCTUnwrap(nodes.first))
        graph["nodes"] = nodes
        try assertCode(graph, "node.duplicate")
        graph = try fixture()
        let projections = try XCTUnwrap(graph["projections"] as? [Object])
        graph["projections"] = projections + projections
        try assertCode(graph, "projection.duplicate")
        graph = try fixture()
        graph["graphKey"] = "contains spaces"
        try assertCode(graph, "identifier")
        graph = try fixture()
        graph["profile"] = "execute-custom-policy"
        try assertCode(graph, "literal")
    }

    func testWrongNodeAndFieldShapesAreRejected() throws {
        var graph = try fixture()
        try change(&graph, node: "movement") { $0["type"] = "undeclared:Record" }
        try assertCode(graph, "node.type")
        graph = try fixture()
        try change(&graph, node: "movement") { $0["fields"] = [] }
        try assertCode(graph, "fields.object")
        graph = try fixture()
        try change(&graph, node: "movement") { $0["state"] = "reviewed" }
        try assertCode(graph, "state.forbidden")
        graph = try fixture()
        var edges = try XCTUnwrap(graph["edges"] as? [Object])
        edges[0]["from"] = "untyped-id"
        graph["edges"] = edges
        try assertCode(graph, "ref.object")
        edges[0]["relation"] = "eventcore:unknown"
        graph = try fixture()
        try remove(&graph, relation: "snapshotContainsFact")
        try append(&graph, relation: "unknown", from: "before", to: "road")
        try assertCode(graph, "relation.unknown")
    }

    func testCandidateObservationContradictionsAndScope() throws {
        var graph = try fixture()
        try field(&graph, node: "unknown-before", key: "availability", value: "partial")
        try assertCode(graph, "observation.shape")
        try append(&graph, relation: "observationSuppliesFact", from: "unknown-before", to: "road")
        XCTAssertEqual(try issues(graph), [])
        try append(&graph, relation: "observationSnapshot", from: "unknown-before", to: "before")
        try assertCode(graph, "observation.shape")
        try field(&graph, node: "unknown-before", key: "availability", value: "known")
        try assertCode(graph, "observation.shape")
        graph = try fixture()
        try field(&graph, node: "unknown-before", key: "availability", value: "unsupported")
        try assertCode(graph, "observation.shape")
        graph = try fixture()
        try field(&graph, node: "unknown-before", key: "availability", value: "known")
        try append(&graph, relation: "observationSnapshot", from: "unknown-before", to: "before")
        try field(&graph, node: "before", key: "scopeKey", value: "elsewhere")
        try assertCode(graph, "candidate.scope")
    }

    func testCausalSelfLinkAndRegistryScopeFail() throws {
        var graph = try fixture()
        try remove(&graph, relation: "hypothesisCauseView")
        try append(&graph, relation: "hypothesisCauseView", from: "causal-link", to: "movement-view")
        try assertCode(graph, "hypothesis.distinct")
        graph = try fixture()
        try field(&graph, node: "causal-link", key: "profileRef", value: "custom")
        try assertCode(graph, "hypothesis.profile")
        graph = try fixture()
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "other-registry", "type": "eventcore:EventRegistry", "fields": ["registryKey": "other", "revisionKey": "r1"]])
        graph["nodes"] = nodes
        try remove(&graph, relation: "recordInRegistry", from: "movement")
        try append(&graph, relation: "recordInRegistry", from: "movement", to: "other-registry")
        try assertCode(graph, "hypothesis.scope")
        try field(&graph, node: "other-registry", key: "registryKey", value: "synthetic")
        try field(&graph, node: "other-registry", key: "revisionKey", value: "events-r1")
        try assertCode(graph, "registry.duplicate")
    }

    func testFactSetDuplicatesPolaritySourcesAndWrongDeltaOwner() throws {
        var graph = try fixture()
        try field(&graph, node: "brake", key: "propositionKey", value: "road")
        try append(&graph, relation: "snapshotContainsFact", from: "before", to: "brake")
        try assertCode(graph, "fact.duplicate")
        graph = try fixture()
        try field(&graph, node: "brake", key: "polarity", value: "both")
        try assertCode(graph, "fact.polarity")
        graph = try fixture()
        try field(&graph, node: "letter", key: "endOffset", value: 8)
        try assertCode(graph, "source.offsets")
        graph = try fixture()
        try remove(&graph, relation: "deltaOfRecord")
        try append(&graph, relation: "deltaOfRecord", from: "movement-delta", to: "omission")
        try assertCode(graph, "delta.exact")
    }
}
