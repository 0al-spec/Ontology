import Foundation
import OntologyCompiler
import XCTest

final class DiagramRelationsTests: XCTestCase {
    func testDefaultDiagramMatchesExistingDOTBytes() throws {
        let example = path("Examples/package-visualization/domain-ontology-package.yaml")
        let dot = try OntologyCompiler().diagramDOT(path: example, direction: .topToBottom)
        XCTAssertEqual(dot, try String(contentsOf: path("Examples/package-visualization/ontology.dot").url, encoding: .utf8))
    }

    func testRelationsViewHidesScaffoldingAndRetainsAllRootRelations() throws {
        let dot = try diagram()
        for label in ["hypothesisMotive", "hypothesisView", "hypothesisActorRole", "hypothesisNegativeSupport", "operatorSupportAuthor"] {
            XCTAssertTrue(dot.contains(label), label)
        }
        for hidden in ["extends", "appliesTo", "implements", "lifecycle", "ReviewMotivation", "hypothesisKey: string"] {
            XCTAssertFalse(dot.contains(hidden), hidden)
        }
        XCTAssertTrue(dot.contains("external/classes/eventcore:Interpretation"))
    }

    func testSelectedImportsShowRecordDeltaAndCausalRelationsWithSourceIdentity() throws {
        let selected = ["Interpretation", "InterpretationCandidate", "RecordedEvent", "Delta", "StateSnapshot", "RoleBinding", "Entity", "CausalHypothesis"]
            .map { "eventcore:\($0)" }
        let dot = try diagram(imports: [events], expanded: selected)
        for label in ["eventcore:interpretsRecord", "eventcore:deltaOfRecord", "eventcore:recordBeforeSnapshot", "eventcore:recordAfterSnapshot",
                      "eventcore:roleBoundEntity", "eventcore:hypothesisCauseView", "eventcore:hypothesisEffectView"] {
            XCTAssertTrue(dot.contains(label), label)
        }
        XCTAssertTrue(dot.contains("«imported class»"))
        XCTAssertTrue(dot.contains("org.0al.events.core@0.2.0"))
        XCTAssertFalse(dot.contains("external/classes/eventcore:Interpretation\""))
        XCTAssertTrue(dot.contains("external/classes/eventcore:SourceAssertion"))
        XCTAssertEqual(dot, try diagram(imports: [events], expanded: selected.reversed() + [selected[0]]))
    }

    func testCanonicalNamespaceIsRebasedToRootAlias() throws {
        try withMutation(motivation, { $0.replacingOccurrences(of: "namespace: eventcore", with: "namespace: ev")
            .replacingOccurrences(of: "eventcore:", with: "ev:") }) { source in
            let dot = try diagram(source: source, imports: [events], expanded: ["ev:Interpretation", "ev:RecordedEvent"])
            XCTAssertTrue(dot.contains("ev:interpretsRecord"))
            XCTAssertTrue(dot.contains("classes/ev:RecordedEvent"))
            XCTAssertFalse(dot.contains("classes/eventcore:RecordedEvent"))
        }
    }

    func testWrongIdentityVersionAndUnknownSelectorsAreRejected() throws {
        for replacement in ["org.0al.other.core", "0.2.1"] {
            let original = replacement.hasPrefix("org.") ? "org.0al.events.core" : "0.2.0"
            try withMutation(events, { $0.replacingOccurrences(of: original, with: replacement) }) { source in
                XCTAssertThrowsError(try diagram(imports: [source], expanded: ["eventcore:Interpretation"])) {
                    XCTAssertTrue(String(describing: $0).contains("not an exact direct import"))
                }
            }
        }
        XCTAssertThrowsError(try diagram(imports: [events], expanded: ["eventcore:Missing"]))
        XCTAssertThrowsError(try diagram(imports: [events, events], expanded: ["eventcore:Interpretation"]))
        XCTAssertThrowsError(try diagram(imports: [events]))
        XCTAssertThrowsError(try diagram(expanded: ["eventcore:Interpretation"]))
    }

    func testPartialImportedOneOfIsOmittedAsAWhole() throws {
        try withMutation(events, { $0.replacingOccurrences(of: "range: RecordedEvent", with: "range:\n        oneOf: [RecordedEvent, Entity]") }) { source in
            let partial = try diagram(imports: [source], expanded: ["eventcore:Delta", "eventcore:RecordedEvent"])
            XCTAssertFalse(partial.contains("label=\"eventcore:deltaOfRecord"))
            let complete = try diagram(imports: [source], expanded: ["eventcore:Delta", "eventcore:RecordedEvent", "eventcore:Entity"])
            XCTAssertEqual(complete.components(separatedBy: "label=\"eventcore:deltaOfRecord [1..1] · oneOf\"").count - 1, 2)
        }
    }

    func testCrossPackageReferencesUseDeclaredIdentityAndAreInputOrderIndependent() throws {
        let source = path("Examples/package-visualization/domain-ontology-package.yaml")
        try withMutation(source, { $0.replacingOccurrences(of: "  classes:", with: """
            - id: org.0al.events.core
              namespace: ev
              version: 0.2.0
            - id: org.0al.motivation.core
              namespace: motives
              version: 0.1.0
          classes:
        """) }) { root in
            let selected = ["motives:MotivationHypothesis", "ev:Interpretation", "ev:InterpretationCandidate"]
            let first = try diagram(source: root, imports: [motivation, events], expanded: selected)
            XCTAssertTrue(first.contains("classes/motives:MotivationHypothesis\" -> \"classes/ev:Interpretation\""))
            XCTAssertEqual(first, try diagram(source: root, imports: [events, motivation], expanded: selected.reversed()))
        }
    }

    func testImportedNamespaceShadowingIsRejectedBeforeProjection() throws {
        try withMutation(events, { $0.replacingOccurrences(of: "namespace: sg", with: "namespace: eventcore")
            .replacingOccurrences(of: "sg:", with: "eventcore:") }) { source in
            XCTAssertThrowsError(try diagram(imports: [source], expanded: ["eventcore:Interpretation"]))
        }
    }

    func testImportedRelationsCanReturnToRootThroughDeclaredCyclicIdentity() throws {
        let source = path("Examples/package-visualization/domain-ontology-package.yaml")
        try withMutation(source, { $0.replacingOccurrences(of: "  classes:", with: """
            - id: org.0al.events.core
              namespace: ev
              version: 0.2.0
          classes:
        """) }) { root in
            try withMutation(events, { $0.replacingOccurrences(of: "  classes:", with: """
                - id: example.review
                  namespace: r
                  version: 0.1.0
              classes:
            """).replacingOccurrences(of: "  relations:", with: """
              relations:
                backToRoot:
                  domain: Interpretation
                  range: r:Proposal
            """) }) { dependency in
                let dot = try diagram(source: root, imports: [dependency], expanded: ["ev:Interpretation"])
                XCTAssertTrue(dot.contains("classes/ev:Interpretation\" -> \"classes/review:Proposal\" [label=\"ev:backToRoot"))
            }
        }
    }

    private func diagram(source: OntologySourcePath? = nil, imports: [OntologySourcePath] = [], expanded: [String] = []) throws -> String {
        try OntologyCompiler().diagramDOT(path: source ?? motivation,
            options: OntologyDiagramOptions(view: .relations, imports: imports, expandedTypes: expanded))
    }

    private func withMutation(_ source: OntologySourcePath, _ mutate: (String) -> String, body: (OntologySourcePath) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let target = directory.appendingPathComponent("package.yaml")
        try mutate(String(contentsOf: source.url, encoding: .utf8)).write(to: target, atomically: true, encoding: .utf8)
        try body(OntologySourcePath(url: target))
    }

    private var motivation: OntologySourcePath { path("SPECS/ontology/packages/motivation-core/domain-ontology-package.yaml") }
    private var events: OntologySourcePath { path("SPECS/ontology/packages/events-core/versions/0.2.0/domain-ontology-package.yaml") }

    private func path(_ relative: String) -> OntologySourcePath {
        OntologySourcePath(url: URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent(relative))
    }
}
