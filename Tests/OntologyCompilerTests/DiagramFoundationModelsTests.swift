import Foundation
import OntologyCompiler
import XCTest

final class DiagramFoundationModelsTests: XCTestCase {
    func testExplicitCatalogBindsLegacyIdentityWithoutFabricatingPackageSources() throws {
        let compiler = OntologyCompiler()
        let plain = try compiler.diagramProjection(path: example)
        XCTAssertNil(plain["foundationCatalogs"])
        let graph = try compiler.diagramProjection(path: example, options: .init(foundationModels: [model("0.1.0")]))
        let bindings = try XCTUnwrap(graph["foundationCatalogs"] as? [[String: Any]])
        XCTAssertEqual(bindings.count, 1)
        XCTAssertEqual(bindings[0]["id"] as? String, "specgraph.foundation")
        XCTAssertEqual(bindings[0]["version"] as? String, "0.1.0")
        XCTAssertEqual(bindings[0]["alias"] as? String, "sg")
        let catalog = try XCTUnwrap(bindings[0]["catalog"] as? [String: Any])
        let classes = try XCTUnwrap(catalog["classes"] as? [String: Any])
        XCTAssertNotNil(classes["DomainEntity"])
        XCTAssertEqual((graph["sources"] as? [[String: Any]])?.count, 1)
        XCTAssertThrowsError(try compiler.diagramDOT(path: example, options: .init(foundationModels: [model("0.1.0")])))
    }

    func testWrongMissingDuplicateAndModifiedModelsFail() throws {
        let compiler = OntologyCompiler()
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: [model("0.2.0")])))
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: [model("0.1.0"), model("0.1.0")])))
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let modified = temporary.appendingPathComponent("model.json")
        var bytes = try Data(contentsOf: model("0.1.0").url)
        bytes.append(0x20)
        try bytes.write(to: modified)
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: [.init(url: modified)])))
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: [.init(url: temporary.appendingPathComponent("missing.json"))])))
        let oversized = temporary.appendingPathComponent("oversized.json")
        try Data(repeating: 0x20, count: 1024 * 1024 + 1).write(to: oversized)
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: [.init(url: oversized)]))) {
            XCTAssertTrue(String(describing: $0).contains("Foundation model exceeds 1048576 bytes"))
        }
        XCTAssertThrowsError(try compiler.diagramProjection(path: example, options: .init(foundationModels: Array(repeating: model("0.1.0"), count: 17))))
    }

    func testTransitiveModelUsesRebasedAliasAndKeepsBothVersions() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let text = try String(contentsOf: example.url, encoding: .utf8)
        let root = text.replacingOccurrences(of: "  classes:", with: """
            - id: example.child
              namespace: child
              version: 0.1.0
          classes:
        """)
        let child = text.replacingOccurrences(of: "id: example.review", with: "id: example.child")
            .replacingOccurrences(of: "namespace: review", with: "namespace: child")
            .replacingOccurrences(of: "id: specgraph.foundation", with: "id: ontology.foundation")
            .replacingOccurrences(of: "namespace: sg", with: "namespace: ont")
            .replacingOccurrences(of: "version: 0.1.0\n  classes:", with: "version: 0.2.0\n  classes:")
            .replacingOccurrences(of: "sg:", with: "ont:")
        let rootURL = directory.appendingPathComponent("root.yaml"), childURL = directory.appendingPathComponent("child.yaml")
        try root.write(to: rootURL, atomically: true, encoding: .utf8)
        try child.write(to: childURL, atomically: true, encoding: .utf8)
        let options = OntologyDiagramOptions(imports: [.init(url: childURL)], foundationModels: [model("0.2.0"), model("0.1.0")])
        let graph = try OntologyCompiler().diagramProjection(path: .init(url: rootURL), options: options)
        let bindings = try XCTUnwrap(graph["foundationCatalogs"] as? [[String: Any]])
        XCTAssertEqual(bindings.count, 2)
        let current = try XCTUnwrap(bindings.first { $0["id"] as? String == "ontology.foundation" })
        XCTAssertEqual(current["version"] as? String, "0.2.0")
        let alias = try XCTUnwrap(current["alias"] as? String)
        XCTAssertNotEqual(alias, "ont")
        let classes = try XCTUnwrap(graph["classes"] as? [[String: Any]])
        XCTAssertEqual(classes.first { $0["fqid"] as? String == "child:Proposal" }?["extends"] as? String, "\(alias):DomainEntity")
        let reversed = OntologyDiagramOptions(imports: [.init(url: childURL)], foundationModels: [model("0.1.0"), model("0.2.0")])
        XCTAssertEqual(try OntologyCompiler().diagramJSON(path: .init(url: rootURL), options: options),
                       try OntologyCompiler().diagramJSON(path: .init(url: rootURL), options: reversed))
    }

    private var example: OntologySourcePath { path("Examples/package-visualization/domain-ontology-package.yaml") }
    private func model(_ version: String) -> OntologySourcePath { path("SPECS/ontology/foundation/\(version)/model.json") }
    private func path(_ relative: String) -> OntologySourcePath {
        .init(url: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent(relative))
    }
}
