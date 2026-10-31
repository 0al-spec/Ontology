import Foundation
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif
import OntologyCompiler
import XCTest

final class DiagramProjectionTests: XCTestCase {
    func testFullProjectionIdentifiesDeclarationsAndFieldsInTheirSource() throws {
        let graph = try OntologyCompiler().diagramProjection(path: example)
        XCTAssertEqual(graph["schemaVersion"] as? String, "ontology.diagram-projection/v1")
        XCTAssertEqual(graph["view"] as? String, "full")
        XCTAssertNil(graph["diagnostics"], "A projection must not assert that validation produced no diagnostics")
        let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
        XCTAssertEqual(sources.count, 1)
        XCTAssertEqual(sources[0]["id"] as? String, "example.review")
        let digest = try XCTUnwrap(sources[0]["sourceDigest"] as? String)
        let sourceBytes = try Data(contentsOf: example.url)
        let expectedDigest = "sha256:" + SHA256.hash(data: sourceBytes).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(digest, expectedDigest)
        XCTAssertEqual(sources[0]["sourceByteDigest"] as? String, expectedDigest)
        let proposal = try record("review:Proposal", in: graph, section: "classes")
        let source = try XCTUnwrap(proposal["source"] as? [String: Any])
        XCTAssertEqual(source["id"] as? String, "example.review")
        XCTAssertEqual(source["sourceDigest"] as? String, digest)
        XCTAssertEqual(source["pointer"] as? String, "/spec/classes/Proposal")
        let fields = try XCTUnwrap(proposal["fields"] as? [[String: Any]])
        let field = try XCTUnwrap(fields.first)
        let fieldSource = try XCTUnwrap(field["source"] as? [String: Any])
        XCTAssertEqual(fieldSource["pointer"] as? String, "/spec/classes/Proposal/fields/title")
    }

    func testSelectedImportedDeclarationsKeepTheirOwningPackageAndAlias() throws {
        let options = OntologyDiagramOptions(view: .relations, imports: [events],
                                             expandedTypes: ["eventcore:Interpretation", "eventcore:RecordedEvent"])
        let graph = try OntologyCompiler().diagramProjection(path: motivation, options: options)
        let imported = try record("eventcore:Interpretation", in: graph, section: "classes")
        let source = try XCTUnwrap(imported["source"] as? [String: Any])
        XCTAssertEqual(source["id"] as? String, "org.0al.events.core")
        XCTAssertEqual(source["version"] as? String, "0.2.0")
        XCTAssertEqual(source["pointer"] as? String, "/spec/classes/Interpretation")
        let relations = try XCTUnwrap(graph["relations"] as? [[String: Any]])
        let relation = try XCTUnwrap(relations.first { $0["id"] as? String == "eventcore:interpretsRecord" })
        let relationSource = try XCTUnwrap(relation["source"] as? [String: Any])
        XCTAssertEqual(relationSource["id"] as? String, "org.0al.events.core")
        XCTAssertEqual(relationSource["pointer"] as? String, "/spec/relations/interpretsRecord")
        XCTAssertEqual(relation["domain"] as? String, "eventcore:Interpretation")
        XCTAssertEqual(relation["range"] as? String, "eventcore:RecordedEvent")
        XCTAssertTrue((graph["protocols"] as? [[String: Any]] ?? []).isEmpty)
        XCTAssertFalse((graph["classes"] as? [[String: Any]] ?? []).contains { $0["fqid"] as? String == "eventcore:SourceAssertion" })
    }

    func testOneOfIsOneRelationWithAlternatives() throws {
        let graph = try OntologyCompiler().diagramProjection(path: path("SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"))
        let relation = try record("examcalc:records", in: graph, section: "relations")
        let range = try XCTUnwrap(relation["range"] as? [String: Any])
        XCTAssertEqual(Set(try XCTUnwrap(range["oneOf"] as? [String])),
                       Set(["examcalc:PolicyViolation", "examcalc:ExamModeSession"]))
    }

    func testByteDigestIncludesBOMAndSourceDigestMatchesCompilerIR() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("package.yaml")
        let bytes = Data([0xef, 0xbb, 0xbf]) + (try Data(contentsOf: example.url))
        try bytes.write(to: input)
        let compiler = OntologyCompiler()
        let graph = try compiler.diagramProjection(path: OntologySourcePath(url: input))
        let rawSource = try XCTUnwrap(String(data: bytes, encoding: .utf8))
        XCTAssertFalse(compiler.check(source: rawSource, path: OntologySourcePath(url: input)).contains { $0.severity == "error" })
        XCTAssertFalse(compiler.check(path: OntologySourcePath(url: input)).contains { $0.severity == "error" })
        let expected = "sha256:" + SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
        XCTAssertEqual(graph["sourceByteDigest"] as? String, expected)
        let proposal = try record("review:Proposal", in: graph, section: "classes")
        XCTAssertEqual((proposal["source"] as? [String: Any])?["sourceByteDigest"] as? String, expected)
        let output = directory.appendingPathComponent("compiled")
        let diagnostics = try compiler.compile(path: OntologySourcePath(url: input), outDirectory: OntologyOutputDirectory(url: output))
        XCTAssertFalse(diagnostics.contains { $0.severity == "error" }, "\(diagnostics)")
        let irData = try Data(contentsOf: output.appendingPathComponent("ontology.normalized.json"))
        let ir = try XCTUnwrap(JSONSerialization.jsonObject(with: irData) as? [String: Any])
        XCTAssertEqual(graph["sourceDigest"] as? String, ir["sourceDigest"] as? String)
        XCTAssertNotEqual(graph["sourceDigest"] as? String, expected)
    }

    func testInvalidUTF8CannotProduceProjection() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("package.yaml")
        try Data([0xff]).write(to: input)
        XCTAssertThrowsError(try OntologyCompiler().diagramProjection(path: OntologySourcePath(url: input))) {
            XCTAssertTrue(String(describing: $0).contains("io.read"))
        }
    }

    func testProjectionJSONIsDeterministicAndRejectsUnknownSelectors() throws {
        let first = OntologyDiagramOptions(view: .relations, imports: [events],
                                           expandedTypes: ["eventcore:Interpretation", "eventcore:RecordedEvent"])
        let reversed = OntologyDiagramOptions(view: .relations, imports: [events],
                                              expandedTypes: ["eventcore:RecordedEvent", "eventcore:Interpretation"])
        let compiler = OntologyCompiler()
        XCTAssertEqual(try compiler.diagramJSON(path: motivation, options: first),
                       try compiler.diagramJSON(path: motivation, options: reversed))
        let invalid = OntologyDiagramOptions(view: .relations, imports: [events], expandedTypes: ["eventcore:Missing"])
        XCTAssertThrowsError(try compiler.diagramProjection(path: motivation, options: invalid))
    }

    func testMultipleImportsContributingRelationsAreOrderIndependent() throws {
        let original = try String(contentsOf: example.url, encoding: .utf8)
        let source = original.replacingOccurrences(of: "  classes:", with: """
            - id: org.0al.events.core
              namespace: ev
              version: 0.2.0
            - id: org.0al.motivation.core
              namespace: motives
              version: 0.1.0
          classes:
        """)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("package.yaml")
        try source.write(to: input, atomically: true, encoding: .utf8)
        let selected = ["motives:MotivationHypothesis", "ev:Interpretation", "ev:InterpretationCandidate", "ev:RecordedEvent"]
        let first = OntologyDiagramOptions(view: .relations, imports: [motivation, events], expandedTypes: selected)
        let second = OntologyDiagramOptions(view: .relations, imports: [events, motivation], expandedTypes: selected.reversed())
        let compiler = OntologyCompiler()
        let path = OntologySourcePath(url: input)
        let graph = try compiler.diagramProjection(path: path, options: first)
        _ = try record("motives:hypothesisView", in: graph, section: "relations")
        _ = try record("ev:interpretsRecord", in: graph, section: "relations")
        XCTAssertEqual(try compiler.diagramJSON(path: path, options: first), try compiler.diagramJSON(path: path, options: second))
    }

    func testImportAliasKeepsOriginalSourceIdentityAndRebasesGraphReferences() throws {
        let source = try String(contentsOf: motivation.url, encoding: .utf8)
            .replacingOccurrences(of: "namespace: eventcore", with: "namespace: ev")
            .replacingOccurrences(of: "eventcore:", with: "ev:")
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let input = directory.appendingPathComponent("package.yaml")
        try source.write(to: input, atomically: true, encoding: .utf8)
        let options = OntologyDiagramOptions(view: .relations, imports: [events],
                                             expandedTypes: ["ev:Interpretation", "ev:RecordedEvent"])
        let graph = try OntologyCompiler().diagramProjection(path: OntologySourcePath(url: input), options: options)
        let imported = try record("ev:Interpretation", in: graph, section: "classes")
        XCTAssertEqual((imported["source"] as? [String: Any])?["id"] as? String, "org.0al.events.core")
        let relation = try record("ev:interpretsRecord", in: graph, section: "relations")
        XCTAssertEqual(relation["domain"] as? String, "ev:Interpretation")
        XCTAssertEqual(relation["range"] as? String, "ev:RecordedEvent")
        XCTAssertEqual((relation["source"] as? [String: Any])?["pointer"] as? String, "/spec/relations/interpretsRecord")
        let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
        let eventSource = try XCTUnwrap(sources.first { $0["id"] as? String == "org.0al.events.core" })
        XCTAssertEqual(eventSource["namespace"] as? String, "eventcore")
        XCTAssertEqual(eventSource["alias"] as? String, "ev")
    }

    func testUnloadedImportsAreNotFabricatedAsDeclarations() throws {
        let graph = try OntologyCompiler().diagramProjection(path: motivation, options: OntologyDiagramOptions(view: .relations))
        let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
        XCTAssertEqual(sources.count, 1)
        let classes = try XCTUnwrap(graph["classes"] as? [[String: Any]])
        XCTAssertFalse(classes.contains { ($0["fqid"] as? String ?? "").hasPrefix("eventcore:") })
        let relation = try record("motivcore:hypothesisView", in: graph, section: "relations")
        let range = try XCTUnwrap(relation["range"] as? [String: Any])
        XCTAssertEqual(Set(try XCTUnwrap(range["oneOf"] as? [String])),
                       Set(["eventcore:Interpretation", "eventcore:InterpretationCandidate"]))
    }

    private func record(_ fqid: String, in graph: [String: Any], section: String) throws -> [String: Any] {
        try XCTUnwrap((graph[section] as? [[String: Any]])?.first { $0["fqid"] as? String == fqid })
    }

    private var example: OntologySourcePath { path("Examples/package-visualization/domain-ontology-package.yaml") }
    private var motivation: OntologySourcePath { path("SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml") }
    private var events: OntologySourcePath { path("SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml") }

    private func path(_ relative: String) -> OntologySourcePath {
        OntologySourcePath(url: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent(relative))
    }
}
