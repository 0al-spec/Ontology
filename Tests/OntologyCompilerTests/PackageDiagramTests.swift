import Foundation
@testable import OntologyCompiler
import XCTest

final class PackageDiagramTests: XCTestCase {
    func testDiagramIncludesTypedReferencesRelationsAndLifecyclesDeterministically() throws {
        let compiler = OntologyCompiler()
        let first = try compiler.diagramDOT(path: example)
        XCTAssertEqual(first, try compiler.diagramDOT(path: example))
        for fragment in [
            "classes/review:Proposal", "protocols/review:Reviewable", "policies/review:EvidenceRequired",
            "extends", "implements", "cites [1..*]", "appliesTo", "lifecycle", "command: review:Approve",
            "title: string", "specgraph.foundation@0.1.0", "External references (declarations not loaded)",
            "stateMachines/review:ReviewState/states/draft"
        ] {
            XCTAssertTrue(first.contains(fragment), fragment)
        }
        let vertical = try compiler.diagramDOT(path: example, direction: .topToBottom)
        XCTAssertTrue(vertical.contains("rankdir=TB"))
    }

    func testExamcalcOneOfIsShownAsAlternativesWithCardinality() throws {
        let path = root.appendingPathComponent("SPECS/ontology/packages/examcalc/domain-ontology-package.yaml")
        let dot = try OntologyCompiler().diagramDOT(path: OntologySourcePath(url: path))
        XCTAssertEqual(dot.components(separatedBy: "label=\"records [0..*] · oneOf\"").count - 1, 2)
        XCTAssertTrue(dot.contains("classes/examcalc:PolicyViolation"))
        XCTAssertTrue(dot.contains("classes/examcalc:ExamModeSession"))
    }

    func testSameSpellingForClassAndProtocolKeepsSeparateNodeIdentities() throws {
        let dot = try renderMutation { source in
            source.replacingOccurrences(of: "Reviewable", with: "Evidence")
        }
        XCTAssertTrue(dot.contains("\"classes/review:Evidence\" [label="))
        XCTAssertTrue(dot.contains("\"protocols/review:Evidence\" [label="))
    }

    func testMissingCardinalityBoundStaysUnknownAndOptionalFieldIsVisible() throws {
        let dot = try renderMutation {
            $0.replacingOccurrences(of: "{min: 1, max: \"*\"}", with: "{min: 1}")
                .replacingOccurrences(of: "required: true", with: "required: false")
        }
        XCTAssertTrue(dot.contains("cites [1..?]"))
        XCTAssertTrue(dot.contains("title?: string"))
    }

    func testInvalidSourceFailsBeforeDiagramGeneration() throws {
        XCTAssertThrowsError(try renderMutation { $0.replacingOccurrences(of: "range: Evidence", with: "range: Missing") }) { error in
            XCTAssertTrue(String(describing: error).contains("relation.range.unresolved"))
        }
    }

    func testDOTQuotingKeepsUnicodeQuotesBackslashesAndNewlinesAsData() {
        let label = "Ready \"α\" \\N\n]; injected [image=\"/tmp/secret\"]"
        var diagram = PackageDiagram(ir: [
            "id": "example.escaping", "namespace": "safe", "version": "0.1.0",
            "stateMachines": [["id": "Flow", "fqid": "safe:Flow", "states": [label]]]
        ])
        let dot = diagram.render(direction: .leftToRight)
        XCTAssertTrue(dot.contains("Ready \\\"α\\\" \\\\N\\n]; injected [image=\\\"/tmp/secret\\\"]"))
        XCTAssertFalse(dot.contains("\n]; injected"))
    }

    private func renderMutation(_ mutate: (String) -> String) throws -> String {
        let temp = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temp) }
        let input = temp.appendingPathComponent("package.yaml")
        try mutate(String(contentsOf: example.url, encoding: .utf8)).write(to: input, atomically: true, encoding: .utf8)
        return try OntologyCompiler().diagramDOT(path: OntologySourcePath(url: input))
    }

    private var example: OntologySourcePath {
        OntologySourcePath(url: root.appendingPathComponent("Examples/package-visualization/domain-ontology-package.yaml"))
    }

    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
}
