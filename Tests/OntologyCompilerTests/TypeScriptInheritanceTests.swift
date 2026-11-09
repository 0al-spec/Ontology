import Foundation
import XCTest
@testable import OntologyCompiler

final class TypeScriptInheritanceTests: XCTestCase {
    func testMultiLevelInheritanceProjectsFieldsAndSchemas() throws {
        try withFixture { root in
            let source = try writePackage(root, name: "local", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Base.
                  fields:
                    name: {type: string, required: true}
                Child:
                  extends: Base
                  description: Child.
                  fields:
                    count: {type: integer, required: false}
                Leaf:
                  extends: Child
                  description: Leaf.
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: source), outDirectory: OntologyOutputDirectory(path: output.path)
            )
            XCTAssertTrue(diagnostics.isEmpty, "\(diagnostics)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("interface Child<$OntologyType extends string = \"local:Child\"> extends Base<$OntologyType>"), types)
            XCTAssertTrue(types.contains("interface Leaf<$OntologyType extends string = \"local:Leaf\"> extends Child<$OntologyType>"), types)
            XCTAssertTrue(types.contains("$OntologyFoundationInstance<\"ontology://ontology.foundation/0.2.0/classes/DomainEntity\", $OntologyType>"), types)
            let leaf = try XCTUnwrap(schemas.components(separatedBy: "export const LeafSchema").last)
            XCTAssertTrue(leaf.contains("name: z.string(),"), leaf)
            XCTAssertTrue(leaf.contains("count: z.number().int().optional(),"), leaf)
        }
    }

    func testImportedBaseFieldsUseExactSource() throws {
        try withFixture { root in
            let shared = try writePackage(root, name: "shared", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Shared base.
                  fields:
                    sharedName: {type: string, required: true}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 1.0.0}\n", classes: """
                Child: {extends: 'alias:Base', description: Child.}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: shared)]
            )
            XCTAssertTrue(diagnostics.isEmpty, "\(diagnostics)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("readonly sharedName: string;"), types)
            XCTAssertTrue(schemas.contains("sharedName: z.string(),"), schemas)
        }
    }

    func testMissingOrWrongVersionOfImportedBaseIsReported() throws {
        try withFixture { root in
            let shared = try writePackage(root, name: "shared", classes: """
                Base: {extends: 'ont:DomainEntity', description: Shared base.}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 2.0.0}\n", classes: """
                Child: {extends: 'alias:Base', description: Child.}
            """)
            let output = root.appendingPathComponent("out")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: shared)]
            )
            XCTAssertEqual(diagnostics.filter { $0.code == "sdk.inheritance.source_unavailable" }.count, 1)
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("Unverified inherited fields from example.shared@2.0.0:Base"), types)
            XCTAssertTrue(schemas.contains("Unverified inherited fields from example.shared@2.0.0:Base"), schemas)
        }
    }

    func testTransitiveImportsUseTheDeclaringPackagesAliases() throws {
        try withFixture { root in
            let first = try writePackage(root, name: "first", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: First ancestor.
                  fields: {firstField: {type: string, required: true}}
            """)
            let second = try writePackage(root, name: "second", imports: "    - {id: example.first, namespace: localalias, version: 1.0.0}\n", classes: """
                Middle:
                  extends: localalias:Base
                  description: Intermediate ancestor.
                  fields: {secondField: {type: integer, required: true}}
            """)
            let third = try writePackage(root, name: "third", imports: "    - {id: example.second, namespace: localalias, version: 1.0.0}\n", classes: """
                Leaf: {extends: 'localalias:Middle', description: Derived class.}
            """)
            let output = root.appendingPathComponent("full")
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: third), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: second), OntologySourcePath(url: first)]
            )
            XCTAssertTrue(diagnostics.isEmpty, "\(diagnostics)")
            let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("readonly firstField: string;"), types)
            XCTAssertTrue(types.contains("readonly secondField: number;"), types)
            XCTAssertTrue(types.contains("$OntologyFoundationInstance<\"ontology://ontology.foundation/0.2.0/classes/DomainEntity\", $OntologyType>"), types)

            let incomplete = root.appendingPathComponent("incomplete")
            let warnings = try OntologyCompiler().compile(
                path: OntologySourcePath(url: third), outDirectory: OntologyOutputDirectory(path: incomplete.path),
                imports: [OntologySourcePath(url: second)]
            )
            XCTAssertTrue(warnings.contains { $0.code == "sdk.inheritance.source_unavailable" }, "\(warnings)")
            let partial = try String(contentsOf: incomplete.appendingPathComponent("types.ts"), encoding: .utf8)
            XCTAssertTrue(partial.contains("readonly secondField: number;"), partial)
            XCTAssertFalse(partial.contains("readonly firstField: string;"), partial)
        }
    }

    func testInheritedReferenceRejectsCanonicalNamespaceCollision() throws {
        try withFixture { root in
            let parent = try writePackage(root, name: "shared", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Imported base.
                  fields: {related: {type: ref, target: Target, required: true}}
                Target: {extends: 'ont:DomainEntity', description: Imported target.}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 1.0.0}\n", classes: """
                Derived: {extends: 'alias:Base', description: Derived class.}
                Target: {extends: 'ont:DomainEntity', description: Unrelated local target.}
            """)
            let text = try String(contentsOf: child, encoding: .utf8)
            try text.replacingOccurrences(of: "namespace: child", with: "namespace: shared")
                .write(to: child, atomically: true, encoding: .utf8)
            let output = root.appendingPathComponent("collision")
            let compiler = OntologyCompiler()
            let diagnostics = try compiler.compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: parent)]
            )
            XCTAssertTrue(diagnostics.contains { $0.code == "class.field.target.namespace_conflict" }, "\(diagnostics)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            let checked = compiler.check(path: OntologySourcePath(url: child), imports: [OntologySourcePath(url: parent)])
            XCTAssertTrue(checked.contains { $0.code == "class.field.target.namespace_conflict" }, "\(checked)")
        }
    }

    func testInheritedReferenceRejectsCollisionWithAnotherImportedPackage() throws {
        try withFixture { root in
            let parent = try writePackage(root, name: "shared", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Imported base.
                  fields: {related: {type: ref, target: Target, required: true}}
                Target: {extends: 'ont:DomainEntity', description: Imported target.}
            """)
            let other = try writePackage(root, name: "other", classes: """
                Target: {extends: 'ont:DomainEntity', description: Different target.}
            """)
            let text = try String(contentsOf: other, encoding: .utf8)
            try text.replacingOccurrences(of: "namespace: other", with: "namespace: shared")
                .write(to: other, atomically: true, encoding: .utf8)
            let imports = "    - {id: example.shared, namespace: first, version: 1.0.0}\n" +
                "    - {id: example.other, namespace: second, version: 1.0.0}\n"
            let child = try writePackage(root, name: "child", imports: imports, classes: """
                Derived: {extends: 'first:Base', description: Derived class.}
            """)
            let output = root.appendingPathComponent("collision")
            let compiler = OntologyCompiler()
            let diagnostics = try compiler.compile(
                path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(path: output.path),
                imports: [OntologySourcePath(url: parent), OntologySourcePath(url: other)]
            )
            XCTAssertTrue(diagnostics.contains { $0.code == "class.field.target.namespace_conflict" }, "\(diagnostics)")
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
        }
    }

    func testCycleAndIncompatibleOverrideDoNotEmitSDK() throws {
        for classes in [
            "A: {extends: B, description: A.}\nB: {extends: A, description: B.}",
            """
                A:
                  extends: ont:DomainEntity
                  description: A.
                  fields: {value: {type: string, required: true}}
                B:
                  extends: A
                  description: B.
                  fields: {value: {type: number, required: true}}
            """
        ] {
            try withFixture { root in
                let source = try writePackage(root, name: "local", classes: classes)
                let output = root.appendingPathComponent("out")
                let compiler = OntologyCompiler()
                do {
                    let diagnostics = try compiler.compile(
                        path: OntologySourcePath(url: source), outDirectory: OntologyOutputDirectory(path: output.path)
                    )
                    XCTAssertTrue(diagnostics.contains {
                        ["class.inheritance.cycle", "class.inheritance.field_conflict"].contains($0.code)
                    }, "Expected an inheritance error, got \(diagnostics)")
                } catch {
                    XCTAssertFalse(String(describing: error).isEmpty)
                }
                XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            }
        }
    }

    private func withFixture(_ body: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try body(root)
    }

    private func writePackage(_ root: URL, name: String, imports: String = "", classes: String) throws -> URL {
        let path = root.appendingPathComponent("\(name).yaml")
        let lines = classes.split(separator: "\n", omittingEmptySubsequences: false)
        let indent = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { $0.prefix { $0 == " " }.count }.min() ?? 0
        let indentedClasses = lines.map { "    \($0.dropFirst(indent))" }.joined(separator: "\n")
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
        """
        try text.write(to: path, atomically: true, encoding: .utf8)
        return path
    }
}
