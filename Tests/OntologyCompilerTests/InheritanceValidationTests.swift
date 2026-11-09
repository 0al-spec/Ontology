import Foundation
import XCTest
@testable import OntologyCompiler

final class InheritanceValidationTests: XCTestCase {
    func testUnrelatedVersionDoesNotConflictWithSelectedImport() throws {
        try withFixture { root in
            let oldDirectory = root.appendingPathComponent("old")
            let newDirectory = root.appendingPathComponent("new")
            try FileManager.default.createDirectory(at: oldDirectory, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: newDirectory, withIntermediateDirectories: true)
            let classes = "Target: {extends: 'ont:DomainEntity', description: Target.}"
            let old = try writePackage(oldDirectory, name: "shared", classes: classes)
            let new = try writePackage(newDirectory, name: "shared", classes: classes)
            let text = try String(contentsOf: new, encoding: .utf8)
            try text.replacingOccurrences(of: "version: 1.0.0}", with: "version: 2.0.0}")
                .write(to: new, atomically: true, encoding: .utf8)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 2.0.0}\n", classes: """
                Leaf:
                  extends: ont:DomainEntity
                  description: Child.
                  fields: {target: {type: ref, target: 'alias:Target', required: true}}
            """)
            let compiler = OntologyCompiler()
            let imports = [OntologySourcePath(url: old), OntologySourcePath(url: new)]
            let findings = compiler.check(path: OntologySourcePath(url: child), imports: imports)
            XCTAssertFalse(compiler.hasErrors(findings), "\(findings)")
            let output = root.appendingPathComponent("sdk")
            let compiled = try compiler.compile(path: OntologySourcePath(url: child), outDirectory: OntologyOutputDirectory(url: output), imports: imports)
            XCTAssertFalse(compiler.hasErrors(compiled), "\(compiled)")
            XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("types.ts").path))

            let bothVersions = try writePackage(root, name: "both", imports: """
                - {id: example.shared, namespace: older, version: 1.0.0}
                - {id: example.shared, namespace: newer, version: 2.0.0}

            """, classes: """
                Leaf:
                  extends: ont:DomainEntity
                  description: Child.
                  fields: {target: {type: ref, target: 'newer:Target', required: true}}
            """)
            let ambiguous = compiler.check(path: OntologySourcePath(url: bothVersions), imports: imports)
            XCTAssertTrue(ambiguous.contains { $0.code == "class.field.target.namespace_conflict" }, "\(ambiguous)")
        }
    }

    func testCheckAndSnapshotCheckRejectCycleAndIncompatibleFields() throws {
        let examples: [(String, String)] = [
            ("A: {extends: B, description: A.}\nB: {extends: A, description: B.}", "class.inheritance.cycle"),
            ("""
                A:
                  extends: ont:DomainEntity
                  description: A.
                  fields: {value: {type: string, required: true}}
                B:
                  extends: A
                  description: B.
                  fields: {value: {type: integer, required: true}}
            """, "class.inheritance.field_conflict")
        ]
        for (classes, expected) in examples {
            try withFixture { root in
                let file = try writePackage(root, name: "local", classes: classes)
                let path = OntologySourcePath(url: file)
                let source = try String(contentsOf: file, encoding: .utf8)
                let compiler = OntologyCompiler()
                let findings = compiler.check(path: path)
                XCTAssertTrue(findings.contains { $0.code == expected && $0.severity == "error" }, "\(findings)")
                let snapshots = compiler.checkSources(source: .init(source: source, path: path), imports: [])
                XCTAssertTrue(snapshots.contains { $0.source == path && $0.diagnostic.code == expected }, "\(snapshots)")
            }
        }
    }

    func testImportedInheritanceFindingsHaveRealSourceLocations() throws {
        try withFixture { root in
            let parent = try writePackage(root, name: "shared", classes: """
                Base:
                  extends: ont:DomainEntity
                  description: Base.
                  fields: {value: {type: string, required: true}}
                Broken:
                  extends: Base
                  description: Conflicting derived class.
                  fields: {value: {type: integer, required: true}}
            """)
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 1.0.0}\n", classes: """
                Leaf: {extends: 'alias:Broken', description: Child.}
            """)
            let parentPath = OntologySourcePath(url: parent)
            let childPath = OntologySourcePath(url: child)
            let imported = OntologySourceSnapshot(source: try String(contentsOf: parent, encoding: .utf8), path: parentPath)
            let source = OntologySourceSnapshot(source: try String(contentsOf: child, encoding: .utf8), path: childPath)
            let findings = OntologyCompiler().checkSources(source: source, imports: [imported])
                .filter { $0.diagnostic.code == "class.inheritance.field_conflict" }
            XCTAssertTrue(findings.contains { $0.source == parentPath && $0.diagnostic.path == "spec.classes.Broken.fields.value" }, "\(findings)")
            XCTAssertTrue(findings.contains { $0.source == childPath && $0.diagnostic.path == "spec.classes.Leaf.extends" }, "\(findings)")
            XCTAssertFalse(findings.contains { $0.source == childPath && $0.diagnostic.path.contains("Broken.fields") }, "\(findings)")
        }
    }

    func testCycleAcrossExplicitImportsIsRejected() throws {
        try withFixture { root in
            let first = try writePackage(root, name: "first", imports: "    - {id: example.second, namespace: second, version: 1.0.0}\n", classes: """
                A: {extends: 'second:B', description: First.}
            """)
            let second = try writePackage(root, name: "second", imports: "    - {id: example.first, namespace: first, version: 1.0.0}\n", classes: """
                B: {extends: 'first:A', description: Second.}
            """)
            let firstPath = OntologySourcePath(url: first)
            let secondPath = OntologySourcePath(url: second)
            let source = OntologySourceSnapshot(source: try String(contentsOf: first, encoding: .utf8), path: firstPath)
            let imported = OntologySourceSnapshot(source: try String(contentsOf: second, encoding: .utf8), path: secondPath)
            let compiler = OntologyCompiler()
            XCTAssertTrue(compiler.check(path: firstPath, imports: [secondPath]).contains { $0.code == "class.inheritance.cycle" })
            let findings = compiler.checkSources(source: source, imports: [imported]).filter { $0.diagnostic.code == "class.inheritance.cycle" }
            XCTAssertTrue(findings.contains { $0.source == firstPath && $0.diagnostic.path == "spec.classes.A.extends" }, "\(findings)")
            XCTAssertTrue(findings.contains { $0.source == secondPath && $0.diagnostic.path == "spec.classes.B.extends" }, "\(findings)")
        }
    }

    func testCheckWarnsWhenInheritedSourceIsNotSupplied() throws {
        try withFixture { root in
            let child = try writePackage(root, name: "child", imports: "    - {id: example.shared, namespace: alias, version: 1.0.0}\n", classes: """
                Leaf: {extends: 'alias:Base', description: Child.}
            """)
            let findings = OntologyCompiler().check(path: OntologySourcePath(url: child))
            XCTAssertTrue(findings.contains { $0.code == "sdk.inheritance.source_unavailable" && $0.severity == "warning" }, "\(findings)")
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
