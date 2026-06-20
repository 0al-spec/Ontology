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

    func testCompatibilityReportAddsReviewOnlyChangeClassification() {
        let report = OntologyCompiler().compatibilityReport(fromIR: classifiedFromIR, toIR: classifiedToIR)
        let changes = report["changes"] as? [String: Any]
        let classification = changes?["changeClassification"] as? [String: Any]
        let structuralChanges = classification?["structuralChanges"] as? [[String: Any]] ?? []
        let annotationChanges = classification?["annotationChanges"] as? [[String: Any]] ?? []
        let applicabilityChanges = classification?["applicabilityChanges"] as? [[String: Any]] ?? []

        XCTAssertTrue(structuralChanges.contains {
            $0["kind"] as? String == "classAdded" &&
                $0["ref"] as? String == "test:Requirement"
        }, "\(structuralChanges)")
        XCTAssertTrue(structuralChanges.contains {
            $0["kind"] as? String == "fieldChanged" &&
                $0["ref"] as? String == "test:Spec.title"
        }, "\(structuralChanges)")
        XCTAssertTrue(structuralChanges.contains {
            $0["kind"] as? String == "relationRangeChanged" &&
                $0["ref"] as? String == "test:definesRequirement"
        }, "\(structuralChanges)")
        XCTAssertTrue(annotationChanges.contains {
            $0["kind"] as? String == "layerChanged" &&
                $0["ref"] as? String == "test:Spec" &&
                $0["targetKind"] as? String == "class"
        }, "\(annotationChanges)")
        XCTAssertTrue(applicabilityChanges.contains {
            $0["kind"] as? String == "invalidationTriggerChanged" &&
                $0["ref"] as? String == "modelApplicability.invalidationTriggers.layer_contract"
        }, "\(applicabilityChanges)")
        XCTAssertTrue(applicabilityChanges.contains {
            $0["kind"] as? String == "assumptionAdded" &&
                $0["ref"] as? String == "modelApplicability.assumptions.owner_review"
        }, "\(applicabilityChanges)")
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

    private var classifiedFromIR: [String: Any] {
        [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.0.0",
            "sourceDigest": "",
            "modelApplicability": [
                "appliesTo": [
                    "domains": ["specgraph_core"]
                ],
                "assumptions": [] as [Any],
                "invalidationTriggers": [
                    [
                        "id": "layer_contract",
                        "layer": "meta",
                        "text": "Re-review when layer vocabulary changes."
                    ]
                ]
            ] as [String: Any],
            "classes": [
                [
                    "id": "Spec",
                    "fqid": "test:Spec",
                    "kind": "Entity",
                    "layer": "objective",
                    "fields": [
                        ["id": "title", "type": "string", "required": false]
                    ]
                ] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [
                [
                    "id": "definesRequirement",
                    "fqid": "test:definesRequirement",
                    "domain": "test:Spec",
                    "range": "test:Spec",
                    "layer": "mechanics"
                ] as [String: Any]
            ],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
    }

    private var classifiedToIR: [String: Any] {
        [
            "id": "test-ontology",
            "namespace": "test",
            "version": "1.1.0",
            "sourceDigest": "",
            "modelApplicability": [
                "appliesTo": [
                    "domains": ["specgraph_core"]
                ],
                "assumptions": [
                    [
                        "id": "owner_review",
                        "layer": "execution",
                        "text": "Owner review is required before accepting ontology changes."
                    ]
                ],
                "invalidationTriggers": [
                    [
                        "id": "layer_contract",
                        "layer": "meta",
                        "text": "Re-review when layer or applicability vocabulary changes."
                    ]
                ]
            ] as [String: Any],
            "classes": [
                [
                    "id": "Spec",
                    "fqid": "test:Spec",
                    "kind": "Entity",
                    "layer": "mechanics",
                    "fields": [
                        ["id": "title", "type": "integer", "required": false]
                    ]
                ] as [String: Any],
                ["id": "Requirement", "fqid": "test:Requirement", "kind": "Entity", "layer": "objective"] as [String: Any]
            ],
            "protocols": [] as [Any],
            "relations": [
                [
                    "id": "definesRequirement",
                    "fqid": "test:definesRequirement",
                    "domain": "test:Spec",
                    "range": "test:Requirement",
                    "layer": "mechanics"
                ] as [String: Any]
            ],
            "policies": [] as [Any],
            "stateMachines": [] as [Any]
        ]
    }
}
