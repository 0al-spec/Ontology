import XCTest
@testable import OntologyCompiler

final class CompatibilityLayerDiffTests: XCTestCase {
    func testCompatibilityReportClassifiesLayerChanges() {
        let report = OntologyCompiler().compatibilityReport(fromIR: fromIR, toIR: toIR)
        let result = report["result"] as? [String: Any]
        let changes = report["changes"] as? [String: Any]
        let layerChanges = changes?["layerChanges"] as? [[String: Any]] ?? []

        XCTAssertEqual(result?["compatible"] as? Bool, true)
        XCTAssertEqual(layerChanges.count, 3, "\(layerChanges)")
        XCTAssertTrue(layerChanges.contains {
            $0["symbol"] as? String == "test:Exam" &&
                $0["kind"] as? String == "class" &&
                $0["classification"] as? String == "layerChanged" &&
                $0["before"] as? String == "mechanics" &&
                $0["after"] as? String == "execution" &&
                $0["compatibility"] as? String == "compatible"
        }, "\(layerChanges)")
        XCTAssertTrue(layerChanges.contains {
            $0["symbol"] as? String == "test:Risk" &&
                $0["kind"] as? String == "class" &&
                $0["classification"] as? String == "layerAdded" &&
                $0["after"] as? String == "meta"
        }, "\(layerChanges)")
        XCTAssertTrue(layerChanges.contains {
            $0["symbol"] as? String == "test:hasRisk" &&
                $0["kind"] as? String == "relation" &&
                $0["classification"] as? String == "layerChanged"
        }, "\(layerChanges)")
    }

    private var fromIR: [String: Any] {
        [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.0.0",
            "sourceDigest": "",
            "classes": [
                ["id": "Exam", "fqid": "test:Exam", "kind": "Entity", "layer": "mechanics"] as [String: Any],
                ["id": "Risk", "fqid": "test:Risk", "kind": "Entity"] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [
                ["id": "hasRisk", "fqid": "test:hasRisk", "layer": "mechanics"] as [String: Any]
            ],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
    }

    private var toIR: [String: Any] {
        [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.1.0",
            "sourceDigest": "",
            "classes": [
                ["id": "Exam", "fqid": "test:Exam", "kind": "Entity", "layer": "execution"] as [String: Any],
                ["id": "Risk", "fqid": "test:Risk", "kind": "Entity", "layer": "meta"] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [
                ["id": "hasRisk", "fqid": "test:hasRisk", "layer": "execution"] as [String: Any]
            ],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
    }
}
