import Foundation
import XCTest
import Yams

extension OntologyCRegressionTests {
    func assertOntologycAdapterReport(_ url: URL) throws {
        let report = try loadYAMLObject(url)
        XCTAssertEqual(report["artifact_kind"] as? String, "ontologyc_adapter_report")
        XCTAssertEqual(report["schema_version"] as? Int, 1)
        XCTAssertEqual(report["proposal_id"] as? String, "0060")

        let producer = try XCTUnwrap(report["producer"] as? [String: Any])
        XCTAssertEqual(producer["tool"] as? String, "ontologyc")
        XCTAssertEqual(producer["command"] as? String, "validate-specgraph")
        XCTAssertEqual(
            producer["command_contract_ref"] as? String,
            "Ontology:SPECS/ontology/ontologyc.md#validate-specgraph"
        )

        let package = try XCTUnwrap(report["package"] as? [String: Any])
        XCTAssertEqual(package["package_id"] as? String, "edu.university.examcalc")
        XCTAssertEqual(package["namespace"] as? String, "examcalc")
        XCTAssertEqual(package["version"] as? String, "0.1.0")
        XCTAssertEqual(package["source_uri"] as? String, "git+https://github.com/0al-spec/Ontology.git")
        XCTAssertEqual(package["source_ref"] as? String, "main")
        XCTAssertEqual(
            package["digest"] as? String,
            "sha256:7cdf061c1c845e0d0d801c7d935b6d4b765db1317ec595910da2cb910eca9e2f"
        )

        let inputs = try XCTUnwrap(report["inputs"] as? [String: Any])
        XCTAssertEqual(inputs["binding_ref"] as? String, "missing-ref-semantic-binding.yaml")
        XCTAssertEqual(inputs["normalized_ir_ref"] as? String, "ontology.normalized.json")

        let outputs = try XCTUnwrap(report["outputs"] as? [String: Any])
        XCTAssertEqual(outputs["concept_refs_ref"] as? String, "concept-refs.yaml")
        XCTAssertEqual(outputs["ontology_lock_ref"] as? String, "ontology.lock.yaml")
        XCTAssertEqual(outputs["ontology_gaps_ref"] as? String, "ontology-gaps.yaml")

        let summary = try XCTUnwrap(report["summary"] as? [String: Any])
        XCTAssertEqual(summary["status"] as? String, "passed")
        XCTAssertEqual(summary["resolved_ref_count"] as? Int, 2)
        XCTAssertEqual(summary["gap_count"] as? Int, 1)
        XCTAssertEqual(summary["canonical_mutations_allowed"] as? Bool, false)
        XCTAssertEqual(summary["tracked_artifacts_written"] as? Bool, false)

        let authority = try XCTUnwrap(report["authority_boundary"] as? [String: Any])
        XCTAssertEqual(authority["report_is_authority"] as? Bool, false)
        XCTAssertEqual(authority["digest_authority"] as? String, "normalized_ir_sourceDigest")
        XCTAssertEqual(authority["ontology_lock_is_canonical"] as? Bool, false)
        XCTAssertEqual(authority["automatic_import_lock_update"] as? Bool, false)
        XCTAssertEqual(authority["automatic_canonical_node_update"] as? Bool, false)
    }

    private func loadYAMLObject(_ url: URL) throws -> [String: Any] {
        try XCTUnwrap(Yams.load(yaml: String(contentsOf: url)) as? [String: Any])
    }
}
