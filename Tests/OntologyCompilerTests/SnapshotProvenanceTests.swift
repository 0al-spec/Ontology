import CryptoKit
import Foundation
@testable import OntologyCompiler
import XCTest

final class SnapshotProvenanceTests: XCTestCase {
    typealias Object = [String: Any]
    var root: URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    var fixtures: URL { root.appendingPathComponent("SPECS/ontology/fixtures/instance-graphs/provenance") }
    var ir: OntologySourcePath { .init(url: root.appendingPathComponent("SPECS/ontology/packages/events-core/versions/0.2.0/generated/ontology.normalized.json")) }
    let profile = "eventcore-provenance-v1"

    func read(_ path: URL) throws -> Object { try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: path)) as? Object) }
    func fixture(_ name: String) throws -> Object { try read(fixtures.appendingPathComponent("\(name).json")) }
    func digest(_ data: Data) -> String { SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() }

    func temporary() throws -> URL {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("ont047-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: path) }
        return path
    }

    // Rebinding is deliberately test-only: it supplies a new trusted document so
    // each inner admission rule can be tested independently of stale-byte refusal.
    func evaluate(_ graph: Object, authority: Object, resupplyBinding: Bool = true) throws -> InstanceGraphValidationResult {
        let directory = try temporary()
        let data = try JSONSerialization.data(withJSONObject: graph, options: [.sortedKeys])
        let graphPath = directory.appendingPathComponent("graph.json")
        try data.write(to: graphPath)
        var authority = authority
        if resupplyBinding { authority["graphSHA256"] = digest(data) }
        let authorityPath = directory.appendingPathComponent("authority.json")
        try JSONSerialization.data(withJSONObject: authority).write(to: authorityPath)
        return try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: graphPath), ontologyIRPath: ir, profile: profile, provenanceAuthorityPath: .init(url: authorityPath))
    }

    func assertCode(_ result: InstanceGraphValidationResult, _ code: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(result.passed, file: file, line: line)
        XCTAssertTrue(result.diagnostics.contains { $0.code == "instanceGraph.\(code)" }, "\(result.diagnostics)", file: file, line: line)
    }

    func changeNode(_ graph: inout Object, _ id: String, _ transform: (inout Object) -> Void) throws {
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        let offset = try XCTUnwrap(nodes.firstIndex { $0["id"] as? String == id })
        transform(&nodes[offset])
        graph["nodes"] = nodes
    }

    func field(_ graph: inout Object, _ id: String, _ key: String, _ value: Any) throws {
        try changeNode(&graph, id) {
            var fields = $0["fields"] as? Object ?? [:]
            fields[key] = value
            $0["fields"] = fields
        }
    }

    func appendEdge(_ graph: inout Object, _ relation: String, _ from: String, _ to: String) throws {
        let nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        func reference(_ id: String) throws -> Object {
            let node = try XCTUnwrap(nodes.first { $0["id"] as? String == id })
            return ["graphKey": graph["graphKey"] ?? "", "revisionKey": graph["revisionKey"] ?? "", "nodeId": id, "type": node["type"] ?? ""]
        }
        var edges = try XCTUnwrap(graph["edges"] as? [Object])
        try edges.append(["relation": "eventcore:\(relation)", "from": reference(from), "to": reference(to)])
        graph["edges"] = edges
    }

    func testStaticPositiveNegativeFixturesAndTruthBoundary() throws {
        let cases = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: fixtures.appendingPathComponent("cases.json"))) as? [Object])
        for item in cases {
            let name = try XCTUnwrap(item["name"] as? String)
            let graph = fixtures.appendingPathComponent(try XCTUnwrap(item["graph"] as? String))
            let authority = fixtures.appendingPathComponent(try XCTUnwrap(item["authority"] as? String))
            let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: graph), ontologyIRPath: ir, profile: profile, provenanceAuthorityPath: .init(url: authority))
            XCTAssertEqual(result.passed, item["status"] as? String == "passed", name)
            if let code = item["code"] as? String { assertCode(result, code) }
            let flags = try XCTUnwrap(result.report["authority"] as? [String: Bool])
            XCTAssertEqual(flags["sourceTruthVerified"], false)
            XCTAssertEqual(flags["causationVerified"], false)
            XCTAssertEqual(flags["responsibilityVerified"], false)
            let provenance = try XCTUnwrap(result.report["provenance"] as? Object)
            XCTAssertEqual(provenance["authorityAuthenticationVerified"] as? Bool, false)
            XCTAssertEqual(result.report["graphSHA256"] as? String, digest(try Data(contentsOf: graph)))
        }
    }

    func testSourceOnlyDoesNotInventSnapshotsOrDelta() throws {
        let graph = try fixture("source-only")
        let nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        XCTAssertFalse(nodes.contains { ["eventcore:StateSnapshot", "eventcore:RecordedEvent", "eventcore:Delta"].contains($0["type"] as? String ?? "") })
        let result = try evaluate(graph, authority: fixture("source-only-authority"))
        XCTAssertTrue(result.passed)
        let provenance = try XCTUnwrap(result.report["provenance"] as? Object)
        XCTAssertEqual(provenance["snapshotCount"] as? Int, 0)
        XCTAssertEqual(provenance["confirmationStatus"] as? String, "no-snapshots")
    }

    func testLegacyLimitationAndReportContractRemainUnchanged() throws {
        let oldIR = OntologySourcePath(url: root.appendingPathComponent("SPECS/ontology/packages/events-core/generated/ontology.normalized.json"))
        let oldGraph = OntologySourcePath(url: root.appendingPathComponent("SPECS/ontology/fixtures/instance-graphs/limitation-unproven-empty-enrichment.json"))
        let result = try OntologyCompiler().validateInstanceGraph(graphPath: oldGraph, ontologyIRPath: oldIR)
        XCTAssertTrue(result.passed)
        XCTAssertEqual(result.report["profile"] as? String, "eventcore-v1")
        XCTAssertNil(result.report["provenance"])
        XCTAssertNil(result.report["profilePin"])
        let flags = try XCTUnwrap(result.report["authority"] as? [String: Bool])
        XCTAssertEqual(flags["sourceTruthVerified"], false)
    }

    func testProfileSelectionAndAuthorityCannotBeImplicit() throws {
        let graph = OntologySourcePath(url: fixtures.appendingPathComponent("confirmed-source.json"))
        let compiler = OntologyCompiler()
        let implicit = try compiler.validateInstanceGraph(graphPath: graph, ontologyIRPath: ir)
        XCTAssertFalse(implicit.passed)
        XCTAssertTrue(implicit.diagnostics.first?.message.contains("instanceGraph.ir.pin") == true)
        let missingAuthority = try compiler.validateInstanceGraph(graphPath: graph, ontologyIRPath: ir, profile: profile)
        assertCode(missingAuthority, "provenance.authority.required")
        let unknown = try compiler.validateInstanceGraph(graphPath: graph, ontologyIRPath: ir, profile: "guess-latest")
        XCTAssertFalse(unknown.passed)
    }

    func testIRAndDefinitionPinTamperingFailClosed() throws {
        var graph = try fixture("confirmed-source")
        var pin = try XCTUnwrap(graph["profilePin"] as? Object)
        pin["definitionSHA256"] = String(repeating: "0", count: 64)
        graph["profilePin"] = pin
        assertCode(try evaluate(graph, authority: fixture("confirmed-source-authority")), "literal")
        let directory = try temporary()
        var object = try read(ir.url)
        object["relations"] = []
        let tampered = directory.appendingPathComponent("ir.json")
        try JSONSerialization.data(withJSONObject: object).write(to: tampered)
        let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: fixtures.appendingPathComponent("source-only.json")), ontologyIRPath: .init(url: tampered), profile: profile)
        XCTAssertFalse(result.passed)
        XCTAssertTrue(result.diagnostics.first?.message.contains("instanceGraph.ir.pin") == true)
    }

    func testChangedBytesRequireNewAuthorityEvenWithSameRevisionAndStates() throws {
        var graph = try fixture("confirmed-source")
        try field(&graph, "letter-role", "roleName", "target")
        let result = try evaluate(graph, authority: fixture("confirmed-source-authority"), resupplyBinding: false)
        assertCode(result, "provenance.authority.binding")
        XCTAssertTrue(try evaluate(graph, authority: fixture("confirmed-source-authority")).passed)
    }

    func testReportsAndNewConsumerExportsAreDeterministic() throws {
        let compiler = OntologyCompiler()
        let output = try temporary()
        let graph = OntologySourcePath(url: fixtures.appendingPathComponent("confirmed-source.json"))
        let authority = OntologySourcePath(url: fixtures.appendingPathComponent("confirmed-source-authority.json"))
        for name in ["first", "second"] {
            let result = try compiler.validateInstanceGraph(graphPath: graph, ontologyIRPath: ir, outPath: .init(url: output.appendingPathComponent("\(name).json")), profile: profile, provenanceAuthorityPath: authority)
            XCTAssertTrue(result.passed)
            try compiler.exportInstanceContract(ontologyIRPath: ir, outDirectory: .init(url: output.appendingPathComponent(name)), profile: profile)
        }
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("first.json")), try Data(contentsOf: output.appendingPathComponent("second.json")))
        for name in ["instance-graph.ts", "instance-graph.schema.json", "snapshot-authority.schema.json"] {
            let data = try Data(contentsOf: output.appendingPathComponent("first/\(name)"))
            XCTAssertEqual(data, try Data(contentsOf: output.appendingPathComponent("second/\(name)")))
            XCTAssertEqual(data, try Data(contentsOf: root.appendingPathComponent("SPECS/ontology/instance-graph/provenance/generated/\(name)")))
        }
    }
}
