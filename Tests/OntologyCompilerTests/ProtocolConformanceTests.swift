import Foundation
import XCTest
@testable import OntologyCompiler

final class ProtocolConformanceTests: XCTestCase {
    func testRequiredFieldCannotBeReplacedBySameNamedRelation() throws {
        try withFixture { root in
            let package = try writePackage(root, name: "local", classes: """
                Document: {extends: 'ont:DomainEntity', implements: [Signed], description: Document.}
            """, protocols: "Signed: {description: Signed., requiredFields: [signature]}", relations: """
                signature: {domain: Document, range: Anchor, description: Not an instance field.}
            """)
            let findings = OntologyCompiler().check(path: .init(url: package))
            XCTAssertTrue(findings.contains { $0.code == "protocol.field.missing" && $0.path.contains("Document") }, "\(findings)")
            let output = root.appendingPathComponent("out")
            let emitted = try OntologyCompiler().compile(path: .init(url: package), outDirectory: .init(path: output.path))
            XCTAssertTrue(emitted.contains { $0.code == "protocol.field.missing" }, "\(emitted)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        }
    }

    func testExplicitRequiredFieldSatisfiesProtocolWithoutMatchingRelation() throws {
        try withFixture { root in
            let package = try writePackage(root, name: "local", classes: """
                Document:
                  extends: ont:DomainEntity
                  description: Document.
                  implements: [Signed]
                  fields: {signature: {type: string, required: true}}
            """, protocols: "Signed: {description: Signed., requiredFields: [signature]}")
            let output = root.appendingPathComponent("out")
            let findings = try OntologyCompiler().compile(path: .init(url: package), outDirectory: .init(path: output.path))
            XCTAssertFalse(findings.contains { $0.severity == "error" }, "\(findings)")
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(schemas.contains("signature: z.string(),"), schemas)
        }
    }

    func testProtocolCanRequireTheBuiltinIdentity() throws {
        try withFixture { root in
            let package = try writePackage(root, name: "local", classes: """
                Document: {extends: 'ont:DomainEntity', implements: [Identified], description: Document.}
            """, protocols: "Identified: {description: Identified., requiredFields: [id]}")
            let output = root.appendingPathComponent("out")
            let findings = try OntologyCompiler().compile(path: .init(url: package), outDirectory: .init(path: output.path))
            XCTAssertFalse(findings.contains { $0.severity == "error" }, "\(findings)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("readonly id: string;"), types)
            XCTAssertTrue(schemas.contains("id: z.string(),"), schemas)
        }
    }

    func testImportedProtocolRequiresItsRelationAndAttributesMissingToSource() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "protocols", protocols: """
                Reviewable: {description: Reviewable., requiredRelations: [cites]}
            """)
            let parent = try writePackage(root, name: "parent", imports: "- {id: example.protocols, namespace: p, version: 1.0.0}", classes: """
                Base: {extends: 'ont:DomainEntity', implements: ['p:Reviewable'], description: Base.}
            """)
            let child = try writePackage(root, name: "child", imports: "- {id: example.parent, namespace: base, version: 1.0.0}", classes: """
                Child: {extends: 'base:Base', description: Child.}
            """)
            func snapshot(_ url: URL) throws -> OntologySourceSnapshot {
                try .init(source: String(contentsOf: url, encoding: .utf8), path: .init(url: url))
            }
            let findings = try OntologyCompiler().checkSources(source: snapshot(child), imports: [snapshot(parent), snapshot(definitions)])
                .filter { $0.diagnostic.code == "protocol.relation.missing" }
            XCTAssertTrue(findings.contains {
                $0.source == OntologySourcePath(url: parent) && $0.diagnostic.path.contains("Base")
            }, "\(findings)")
            XCTAssertTrue(findings.contains {
                $0.source == OntologySourcePath(url: child) && $0.diagnostic.path == "spec.classes.Child.extends"
            }, "\(findings)")
        }
    }

    func testImportedInheritedRelationAndFieldsAreAccepted() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "protocols", protocols: """
                Reviewable: {description: Reviewable., requiredFields: [label], requiredRelations: [cites]}
            """)
            let parent = try writePackage(root, name: "parent", imports: "- {id: example.protocols, namespace: p, version: 1.0.0}", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Base.
                  implements: ['p:Reviewable']
                  fields: {label: {type: string, required: true}}
            """, relations: "cites: {domain: Base, range: Anchor, description: Cites.}")
            let child = try writePackage(root, name: "child", imports: "- {id: example.parent, namespace: base, version: 1.0.0}", classes: """
                Child: {extends: 'base:Base', description: Child.}
            """)
            let findings = OntologyCompiler().check(path: .init(url: child), imports: [.init(url: parent), .init(url: definitions)])
            XCTAssertFalse(findings.contains { $0.severity == "error" }, "\(findings)")
        }
    }

    func testChildCanSatisfyItsProtocolWithVerifiedAncestorDeclarations() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "protocols", protocols: """
                Reviewable: {description: Reviewable., requiredFields: [label], requiredRelations: [cites]}
            """)
            let parent = try writePackage(root, name: "parent", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Base.
                  fields: {label: {type: string, required: true}}
            """, relations: "cites: {domain: Base, range: Anchor, description: Cites.}")
            let child = try writePackage(root, name: "child", imports: """
                - {id: example.parent, namespace: base, version: 1.0.0}
                - {id: example.protocols, namespace: p, version: 1.0.0}
            """, classes: """
                Child: {extends: 'base:Base', implements: ['p:Reviewable'], description: Child.}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(path: .init(url: child), outDirectory: .init(path: output.path),
                                                             imports: [.init(url: parent), .init(url: definitions)])
            XCTAssertFalse(diagnostics.contains { $0.severity == "error" }, "\(diagnostics)")
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(schemas.contains("label: z.string(),"), schemas)
        }
    }

    func testSameNamedImportedClassCannotSatisfyRelationRequirement() throws {
        try withFixture { root in
            let other = try writePackage(root, name: "other", classes: """
                Document: {extends: 'ont:DomainEntity', description: Different document.}
            """)
            let package = try writePackage(root, name: "local", imports: "- {id: example.other, namespace: remote, version: 1.0.0}", classes: """
                Document: {extends: 'ont:DomainEntity', implements: [Reviewable], description: Document.}
            """, protocols: "Reviewable: {description: Reviewable., requiredRelations: [cites]}", relations: """
                cites: {domain: 'remote:Document', range: Anchor, description: Unrelated domain.}
            """)
            let findings = OntologyCompiler().check(path: .init(url: package), imports: [.init(url: other)])
            XCTAssertTrue(findings.contains { $0.code == "protocol.relation.missing" && $0.path.contains("Document") }, "\(findings)")
        }
    }

    func testMissingAncestorDoesNotProduceFalseMissingFieldOrRelation() throws {
        try withFixture { root in
            let definitions = try writePackage(root, name: "protocols", protocols: """
                Reviewable: {description: Reviewable., requiredFields: [label], requiredRelations: [cites]}
            """)
            let child = try writePackage(root, name: "child", imports: """
                - {id: example.protocols, namespace: p, version: 1.0.0}
                - {id: example.parent, namespace: base, version: 1.0.0}
            """, classes: """
                Child: {extends: 'base:Base', implements: ['p:Reviewable'], description: Child.}
            """)
            let findings = OntologyCompiler().check(path: .init(url: child), imports: [.init(url: definitions)])
            XCTAssertTrue(findings.contains { $0.code == "sdk.inheritance.source_unavailable" }, "\(findings)")
            XCTAssertFalse(findings.contains { ["protocol.field.missing", "protocol.relation.missing"].contains($0.code) }, "\(findings)")
        }
    }

    func testUnverifiedLocalProtocolDoesNotFabricateSDKFields() throws {
        try withFixture { root in
            let child = try writePackage(root, name: "child", imports: "- {id: example.parent, namespace: base, version: 1.0.0}", classes: """
                Child: {extends: 'base:Base', implements: [Tracked], description: Child.}
            """, protocols: "Tracked: {description: Tracked., requiredFields: [label]}")
            let output = root.appendingPathComponent("out")
            let findings = try OntologyCompiler().compile(path: .init(url: child), outDirectory: .init(path: output.path))
            XCTAssertTrue(findings.contains { $0.code == "protocol.field.unverified" }, "\(findings)")
            XCTAssertFalse(findings.contains { $0.severity == "error" }, "\(findings)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertFalse(types.contains("extends Tracked"), types)
            XCTAssertFalse(types.contains("readonly label:"), types)
            XCTAssertFalse(schemas.contains("label: z."), schemas)
            XCTAssertTrue(schemas.contains("Cannot verify required field label"), schemas)
        }
    }

    func testOptionalAndNonStringFieldsDoNotSatisfyRequiredField() throws {
        for field in ["{type: string, required: false}", "{type: integer, required: true}"] {
            try withFixture { root in
                let package = try writePackage(root, name: "local", classes: """
                    Document:
                      extends: ont:DomainEntity
                      implements: [Signed]
                      description: Document.
                      fields: {signature: \(field)}
                """, protocols: "Signed: {description: Signed., requiredFields: [signature]}")
                let findings = OntologyCompiler().check(path: .init(url: package))
                XCTAssertTrue(findings.contains { $0.code == "class.inheritance.protocol_field_conflict" }, "\(findings)")
            }
        }
    }

    private func withFixture(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }

    private func writePackage(_ root: URL, name: String, imports: String = "", classes: String = "",
                              protocols: String = "", relations: String = "") throws -> URL {
        func indent(_ text: String, spaces: Int) -> String {
            let lines = text.split(separator: "\n")
            let common = lines.map { $0.prefix { $0 == " " }.count }.min() ?? 0
            return lines.map { String(repeating: " ", count: spaces) + $0.dropFirst(common) }.joined(separator: "\n")
        }
        var lines = [
            "apiVersion: ontology.specgraph.io/v1alpha1", "kind: DomainOntologyPackage",
            "metadata: {id: example.\(name), namespace: \(name), version: 1.0.0}",
            "spec:", "  imports:", "    - {id: ontology.foundation, namespace: ont, version: 0.2.0}"
        ]
        if !imports.isEmpty { lines.append(indent(imports, spaces: 4)) }
        lines += ["  classes:", "    Anchor: {extends: 'ont:DomainEntity', description: Anchor.}"]
        if !classes.isEmpty { lines.append(indent(classes, spaces: 4)) }
        lines += ["  relations:", "    links: {domain: Anchor, range: Anchor, description: Link.}"]
        if !relations.isEmpty { lines.append(indent(relations, spaces: 4)) }
        if !protocols.isEmpty { lines += ["  protocols:", indent(protocols, spaces: 4)] }
        let source = lines.joined(separator: "\n") + "\n"
        let path = root.appendingPathComponent("\(name).yaml")
        try source.write(to: path, atomically: true, encoding: .utf8)
        return path
    }
}
