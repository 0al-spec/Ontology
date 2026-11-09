import Foundation
import OntologyRules
import XCTest
@testable import OntologyCompiler

final class FoundationModelCatalogTests: XCTestCase {
    func testCatalogsPreservePinnedDefinitionsAndExportCoverage() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
        let pins = [
            ("0.1.0", "c52553f872f440dde26c61abf9193f5fff171d98",
             "322d149e9cd68f89012feeab56987f57d6b339139056f35f96506093667f6f7b"),
            ("0.2.0", "40672c189f33dee2b8c6fdac903758e90d9fba86",
             "48a80575141b48b5778f637409831eac94a91a557d953d52835de7c13a1975ac")
        ]
        for (version, revision, digest) in pins {
            let directory = root.appendingPathComponent("SPECS/ontology/foundation/\(version)")
            let document = try Data(contentsOf: directory.appendingPathComponent("model.md"))
            let source = try XCTUnwrap(String(data: document, encoding: .utf8))
            XCTAssertEqual(OntologyCompiler().sha256(document), "sha256:\(digest)")
            let model = try json(directory.appendingPathComponent("model.json"))
            let exports = try json(directory.appendingPathComponent("exports.json"))
            XCTAssertEqual(model["schemaVersion"] as? String, "ontology.foundation-model/v1")
            XCTAssertEqual(model["id"] as? String, exports["id"] as? String)
            XCTAssertEqual(model["version"] as? String, version)
            XCTAssertEqual(model["namespace"] as? String, exports["namespace"] as? String)
            let origin = try XCTUnwrap(model["source"] as? [String: String])
            XCTAssertEqual(origin, ["path": "model.md", "revision": revision, "sha256": digest])

            let builtIn = version == "0.1.0" ? FoundationExports.version010 : FoundationExports.current
            for section in ["classes", "protocols"] {
                let records = try XCTUnwrap(model[section] as? [String: [String: Any]])
                let names = try XCTUnwrap(exports[section] as? [String])
                XCTAssertEqual(Set(names), Set(section == "classes" ? builtIn.classes : builtIn.protocols))
                XCTAssertEqual(Set(records.keys), Set(names), "\(version) \(section)")
                for name in names {
                    XCTAssertEqual(records[name]?["declaration"] as? String, try interface(name, in: source))
                }
            }
            let supporting = try XCTUnwrap(model["supportingTypes"] as? [String: [String: Any]])
            let interfaceNames = ["OntologyNode", "ConceptRef", "StateMachineRef", "StateTransition"]
            XCTAssertEqual(Set(supporting.keys), Set(interfaceNames + ["ConceptKind"]))
            for name in interfaceNames {
                XCTAssertEqual(supporting[name]?["declaration"] as? String, try interface(name, in: source))
            }
            let start = try XCTUnwrap(source.range(of: "export type ConceptKind =")?.lowerBound)
            let end = try XCTUnwrap(source[start...].firstIndex(of: ";"))
            XCTAssertEqual(supporting["ConceptKind"]?["declaration"] as? String, String(source[start ... end]))
            let classes = try XCTUnwrap(model["classes"] as? [String: [String: Any]])
            let entity = try XCTUnwrap(classes["DomainEntity"])
            XCTAssertEqual(entity["extends"] as? String, "OntologyNode")
            let fields = try XCTUnwrap(entity["properties"] as? [[String: Any]])
            XCTAssertEqual(fields[1]["name"] as? String, "lifecycle")
            XCTAssertEqual(fields[1]["type"] as? String, "StateMachineRef")
            XCTAssertEqual(fields[1]["optional"] as? Bool, true)
            let invariant = try XCTUnwrap(classes["Invariant"]?["properties"] as? [[String: Any]])
            XCTAssertEqual(invariant[1]["name"] as? String, "appliesTo")
            XCTAssertEqual(invariant[1]["type"] as? String, "readonly ConceptRef[]")
        }
        XCTAssertEqual(FoundationExports.catalog(packageID: "specgraph.foundation", version: "0.1.0")?.version, "0.1.0")
        XCTAssertNil(FoundationExports.catalog(packageID: "specgraph.foundation", version: "0.2.0"))
    }

    private func json(_ url: URL) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func interface(_ name: String, in source: String) throws -> String {
        let marker = "export interface \(name)"
        let start = try XCTUnwrap(source.range(of: marker)?.lowerBound)
        let end = try XCTUnwrap(source.range(of: "\n}", range: start ..< source.endIndex)?.upperBound)
        return String(source[start ..< end])
    }
}
