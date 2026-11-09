import Foundation
import XCTest
@testable import OntologyCompiler

final class ImportedProtocolInheritanceTests: XCTestCase {
    func testInheritedProtocolUsesSuppliedAncestorSource() throws {
        try withFixture { root in
            let parent = try writePackage(root, name: "shared", classes: """
                Base: {extends: 'ont:DomainEntity', description: Base., implements: [Tracked]}
            """, protocols: "Tracked: {description: Tracked., requiredFields: [trace]}",
            extraRelations: "trace: {domain: Base, range: TestRoot, description: Trace.}")
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: parent, version: 1.0.0}\n", classes: """
                Child: {extends: 'parent:Base', description: Child.}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: parent)]
            )
            XCTAssertFalse(diagnostics.contains { $0.code == "sdk.inheritance.protocol_unavailable" }, "\(diagnostics)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("readonly trace: string;"), types)
            XCTAssertTrue(schemas.contains("trace: z.string(),"), schemas)
        }
    }

    func testProtocolImportsUseEachDeclaringPackagesAlias() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "definitions", classes: "", protocols: """
                Tracked: {description: Ancestor protocol., requiredFields: [ancestorTrace], requiredRelations: [declaredRelation]}
            """)
            let other = try writePackage(root, name: "other", classes: "", protocols: """
                Tracked: {description: Child protocol., requiredFields: [childTrace]}
            """)
            let parent = try writePackage(root, name: "shared", imports: "    - {id: example.definitions, namespace: contract, version: 1.0.0}\n", classes: """
                Base: {extends: 'ont:DomainEntity', description: Base., implements: ['contract:Tracked']}
            """)
            let child = try writePackage(root, name: "child", imports:
                "    - {id: example.shared, namespace: parent, version: 1.0.0}\n" +
                "    - {id: example.other, namespace: contract, version: 1.0.0}\n", classes: """
                Child: {extends: 'parent:Base', description: Child., implements: ['contract:Tracked']}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: parent), OntologySourcePath(url: definitions), OntologySourcePath(url: other)]
            )
            XCTAssertFalse(diagnostics.contains { $0.code == "sdk.inheritance.protocol_unavailable" }, "\(diagnostics)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            for name in ["ancestorTrace", "childTrace"] {
                XCTAssertTrue(types.contains("readonly \(name): string;"), types)
                XCTAssertTrue(schemas.contains("\(name): z.string(),"), schemas)
            }
            XCTAssertFalse(types.contains("readonly declaredRelation:"), types)
            XCTAssertFalse(schemas.contains("declaredRelation: z."), schemas)
        }
    }

    func testMissingProtocolSourceWarnsWithoutGuessing() throws {
        try withFixture { root in
            let child = try writePackage(root, name: "child", imports: "    - {id: example.definitions, namespace: contract, version: 2.0.0}\n", classes: """
                Child: {extends: 'ont:DomainEntity', description: Child., implements: ['contract:Tracked']}
            """)
            let wrongVersion = try writePackage(root, name: "definitions", classes: "", protocols: """
                Tracked: {description: Wrong version., requiredFields: [mustNotAppear]}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: wrongVersion)]
            )
            XCTAssertTrue(diagnostics.contains { $0.code == "sdk.inheritance.protocol_unavailable" && $0.message.contains("example.definitions@2.0.0") }, "\(diagnostics)")
            for file in ["types.ts", "schemas.ts"] {
                let text = try String(contentsOf: output.appendingPathComponent(file), encoding: .utf8)
                XCTAssertTrue(text.contains("example.definitions@2.0.0"), text)
                XCTAssertFalse(text.contains("mustNotAppear"), text)
            }
        }
    }

    func testSuppliedProtocolSourceMustContainReferencedProtocol() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "definitions", classes: "")
            let child = try writePackage(root, name: "child", imports: "    - {id: example.definitions, namespace: contract, version: 1.0.0}\n", classes: """
                Child: {extends: 'ont:DomainEntity', description: Child., implements: ['contract:Missing']}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: definitions)]
            )
            XCTAssertTrue(diagnostics.contains { $0.code == "protocol.unresolved" }, "\(diagnostics)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        }
    }

    func testImportedProtocolFieldConflictsAreRejectedDuringCheckAndCompile() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "definitions", classes: "", protocols: """
                Tracked: {description: Protocol., requiredFields: [trace]}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.definitions, namespace: contract, version: 1.0.0}\n", classes: """
                Child:
                  extends: ont:DomainEntity
                  description: Child.
                  implements: ['contract:Tracked']
                  fields: {trace: {type: integer, required: true}}
            """)
            let path = OntologySourcePath(url: child)
            let imports = [OntologySourcePath(url: definitions)]
            let findings = OntologyCompiler().check(path: path, imports: imports)
            XCTAssertTrue(findings.contains {
                $0.code == "class.inheritance.protocol_field_conflict" && $0.path == "spec.classes.Child.fields.trace"
            }, "\(findings)")
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(path: path, outDirectory: OntologyOutputDirectory(path: output.path), imports: imports)
            XCTAssertTrue(diagnostics.contains { $0.code == "class.inheritance.protocol_field_conflict" }, "\(diagnostics)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        }
    }

    func testMissingImportedProtocolIsAttributedToBothAffectedSources() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "definitions", classes: "")
            let parent = try writePackage(root, name: "shared", imports: "    - {id: example.definitions, namespace: contract, version: 1.0.0}\n", classes: """
                Base: {extends: 'ont:DomainEntity', description: Base., implements: ['contract:Missing']}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: parent, version: 1.0.0}\n", classes: """
                Child: {extends: 'parent:Base', description: Child.}
            """)
            func snapshot(_ url: URL) throws -> OntologySourceSnapshot {
                try .init(source: String(contentsOf: url, encoding: .utf8), path: OntologySourcePath(url: url))
            }
            let findings = try OntologyCompiler().checkSources(source: snapshot(child), imports: [snapshot(parent), snapshot(definitions)])
                .filter { $0.diagnostic.code == "protocol.unresolved" }
            XCTAssertTrue(findings.contains {
                $0.source == OntologySourcePath(url: parent) && $0.diagnostic.path == "spec.classes.Base.implements"
            }, "\(findings)")
            XCTAssertTrue(findings.contains {
                $0.source == OntologySourcePath(url: child) && $0.diagnostic.path == "spec.classes.Child.extends"
            }, "\(findings)")
        }
    }

    private func withFixture(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }

    private func writePackage(_ root: URL, name: String, imports: String = "", classes: String,
                              protocols: String = "", extraRelations: String = "") throws -> URL {
        let path = root.appendingPathComponent("\(name).yaml")
        let lines = classes.split(separator: "\n", omittingEmptySubsequences: false)
        let indent = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.prefix { $0 == " " }.count }.min() ?? 0
        let indentedClasses = lines.map { "    \($0.dropFirst(indent))" }.joined(separator: "\n")
        let protocolBlock = protocols.isEmpty ? "" : "  protocols:\n" + protocols.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n") + "\n"
        let relationsBlock = extraRelations.isEmpty ? "" : "\n" + extraRelations.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n")
        let text = """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata: {id: example.\(name), namespace: \(name), version: 1.0.0}
        spec:
          imports:
            - {id: ontology.foundation, namespace: ont, version: 0.2.0}
        \(imports)  classes:
        \(indentedClasses)
            TestRoot: {extends: 'ont:DomainEntity', description: Test root.}
          relations:
            contains: {domain: TestRoot, range: TestRoot, description: Test relation.}
        \(relationsBlock)
        \(protocolBlock)
        """
        try text.write(to: path, atomically: true, encoding: .utf8)
        return path
    }
}
