import Foundation
import OntologyCompiler
import XCTest

final class DiagramFullProjectionTests: XCTestCase {
    func testFullImportsRebaseEveryDeclarationFamilyAndPreserveSources() throws {
        try fixture { root, child in
            let compiler = OntologyCompiler()
            let graph = try compiler.diagramProjection(path: root, options: OntologyDiagramOptions(imports: [child]))
            func imported(_ section: String, _ id: String) throws -> [String: Any] {
                try XCTUnwrap((graph[section] as? [[String: Any]])?.first { $0["fqid"] as? String == "dep:\(id)" })
            }
            let proposal = try imported("classes", "Proposal")
            XCTAssertEqual(proposal["extends"] as? String, "base:DomainEntity")
            XCTAssertEqual(proposal["implements"] as? [String], ["dep:Reviewable"])
            XCTAssertEqual(proposal["lifecycle"] as? String, "dep:ReviewState")
            let source = try XCTUnwrap(proposal["source"] as? [String: Any])
            XCTAssertEqual(source["id"] as? String, "example.dependency")
            XCTAssertEqual(source["pointer"] as? String, "/spec/classes/Proposal")
            let field = try XCTUnwrap((proposal["fields"] as? [[String: Any]])?.first)
            XCTAssertEqual((field["source"] as? [String: Any])?["pointer"] as? String, "/spec/classes/Proposal/fields/title")
            XCTAssertEqual(try imported("protocols", "Reviewable")["requiredRelations"] as? [String], ["dep:cites"])
            XCTAssertEqual(try imported("policies", "EvidenceRequired")["appliesTo"] as? [String], ["dep:Proposal"])
            XCTAssertEqual(try imported("policies", "EvidenceRequired")["extends"] as? String, "base:Policy")
            let relation = try imported("relations", "cites")
            XCTAssertEqual(relation["domain"] as? String, "dep:Proposal")
            XCTAssertEqual(relation["range"] as? String, "dep:Evidence")
            let machine = try imported("stateMachines", "ReviewState")
            XCTAssertEqual((machine["transitions"] as? [[String: Any]])?.first?["command"] as? String, "dep:Approve")
            let dot = try compiler.diagramDOT(path: root, options: OntologyDiagramOptions(imports: [child]))
            XCTAssertTrue(dot.contains("classes/dep:Proposal\" -> \"stateMachines/dep:ReviewState"))
            XCTAssertFalse(dot.contains("review:dep:ReviewState"))
        }
    }

    func testFullProjectionIsIndependentOfImportOrder() throws {
        try fixture { root, child in
            let original = try String(contentsOf: root.url, encoding: .utf8)
            try original.replacingOccurrences(of: "  classes:", with: """
                - id: org.0al.events.core
                  namespace: ev
                  version: 0.2.0
              classes:
            """).write(to: root.url, atomically: true, encoding: .utf8)
            let events = path("SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml")
            let compiler = OntologyCompiler()
            let first = OntologyDiagramOptions(imports: [child, events])
            let second = OntologyDiagramOptions(imports: [events, child])
            XCTAssertEqual(try compiler.diagramJSON(path: root, options: first), try compiler.diagramJSON(path: root, options: second))
            XCTAssertEqual(try compiler.diagramDOT(path: root, options: first), try compiler.diagramDOT(path: root, options: second))
            XCTAssertThrowsError(try compiler.diagramProjection(path: root, options: OntologyDiagramOptions(imports: [child, child])))
        }
    }

    func testUnboundNestedNamespaceCannotAccidentallyJoinARootAlias() throws {
        try fixture { root, child in
            let text = try String(contentsOf: child.url, encoding: .utf8)
                .replacingOccurrences(of: "specgraph.foundation", with: "example.private")
            try text.write(to: child.url, atomically: true, encoding: .utf8)
            XCTAssertThrowsError(try OntologyCompiler().diagramProjection(path: root, options: OntologyDiagramOptions(imports: [child]))) {
                XCTAssertTrue(String(describing: $0).contains("Cannot bind imported reference"))
            }
        }
    }

    private func fixture(_ body: (OntologySourcePath, OntologySourcePath) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let example = try String(contentsOf: path("Examples/package-visualization/domain-ontology-package.yaml").url, encoding: .utf8)
        let root = example.replacingOccurrences(of: "namespace: sg", with: "namespace: base")
            .replacingOccurrences(of: "sg:", with: "base:")
            .replacingOccurrences(of: "  classes:", with: """
                - id: example.dependency
                  namespace: dep
                  version: 0.1.0
              classes:
            """)
        let child = example.replacingOccurrences(of: "id: example.review", with: "id: example.dependency")
            .replacingOccurrences(of: "namespace: review", with: "namespace: original")
        let rootURL = directory.appendingPathComponent("root.yaml"), childURL = directory.appendingPathComponent("child.yaml")
        try root.write(to: rootURL, atomically: true, encoding: .utf8)
        try child.write(to: childURL, atomically: true, encoding: .utf8)
        try body(OntologySourcePath(url: rootURL), OntologySourcePath(url: childURL))
    }

    private func path(_ relative: String) -> OntologySourcePath {
        OntologySourcePath(url: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent(relative))
    }
}
