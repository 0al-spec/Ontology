import Foundation
@testable import OntologyCompiler
import XCTest

final class DiagramTransitiveImportTests: XCTestCase {
    func testExplicitChainUsesExactSourceWithoutAddingRootImports() throws {
        try fixture { files in
            let compiler = OntologyCompiler()
            let first = OntologyDiagramOptions(imports: [files.child, files.core])
            let second = OntologyDiagramOptions(imports: [files.core, files.child])
            let graph = try compiler.diagramProjection(path: files.root, options: first)
            XCTAssertEqual(try compiler.diagramJSON(path: files.root, options: first),
                           try compiler.diagramJSON(path: files.root, options: second))
            XCTAssertEqual(try compiler.diagramDOT(path: files.root, options: first),
                           try compiler.diagramDOT(path: files.root, options: second))

            let coreAlias = try alias(graph, id: "example.core", version: "1.0.0")
            XCTAssertNotEqual(coreAlias, "foundation")
            let classes = try XCTUnwrap(graph["classes"] as? [[String: Any]])
            let core = try XCTUnwrap(classes.first { $0["fqid"] as? String == "\(coreAlias):Core" })
            let source = try XCTUnwrap(core["source"] as? [String: Any])
            XCTAssertEqual(source["id"] as? String, "example.core")
            XCTAssertEqual(source["version"] as? String, "1.0.0")
            XCTAssertEqual(source["pointer"] as? String, "/spec/classes/Core")
            let relations = try XCTUnwrap(graph["relations"] as? [[String: Any]])
            let edge = try XCTUnwrap(relations.first { $0["fqid"] as? String == "child:usesCore" })
            XCTAssertEqual(edge["domain"] as? String, "child:Child")
            XCTAssertEqual(edge["range"] as? String, "\(coreAlias):Core")
            let imports = try XCTUnwrap(graph["imports"] as? [[String: Any]])
            XCTAssertFalse(imports.contains { $0["id"] as? String == "example.core" })

            let options = OntologyDiagramOptions(view: .relations, imports: [files.core, files.child],
                                                 expandedTypes: ["child:Child", "\(coreAlias):Core"])
            let selected = try compiler.diagramProjection(path: files.root, options: options)
            let selectedRelations = try XCTUnwrap(selected["relations"] as? [[String: Any]])
            XCTAssertTrue(selectedRelations.contains { $0["fqid"] as? String == "child:usesCore" })
        }
    }

    func testMissingTransitivePackageRemainsAnIdentifiedExternalReference() throws {
        try fixture { files in
            let compiler = OntologyCompiler()
            let options = OntologyDiagramOptions(imports: [files.child])
            let graph = try compiler.diagramProjection(path: files.root, options: options)
            let bindings = try XCTUnwrap(graph["externalImports"] as? [[String: Any]])
            let core = try XCTUnwrap(bindings.first { $0["id"] as? String == "example.core" })
            XCTAssertEqual(core["version"] as? String, "1.0.0")
            let alias = try XCTUnwrap(core["alias"] as? String)
            let loaded = try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core]))
            XCTAssertEqual(alias, try self.alias(loaded, id: "example.core", version: "1.0.0"))
            let relations = try XCTUnwrap(graph["relations"] as? [[String: Any]])
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "child:usesCore" }?["range"] as? String,
                           "\(alias):Core")
            let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
            XCTAssertFalse(sources.contains { $0["id"] as? String == "example.core" })
            let dot = try compiler.diagramDOT(path: files.root, options: options)
            XCTAssertTrue(dot.contains("external/classes/\(alias):Core"))
            XCTAssertTrue(dot.contains("example.core@1.0.0"))
        }
    }

    func testSelectedTransitiveClassKeepsItsInheritanceInTheDiagramScope() throws {
        try fixture { files in
            let original = try String(contentsOf: files.core.url, encoding: .utf8)
            let withBase = original.replacingOccurrences(
                of: "    Core:\n      extends: ont:DomainEntity",
                with: "    Base:\n      extends: ont:DomainEntity\n      description: A base entity.\n    Core:\n      extends: Base"
            )
            XCTAssertNotEqual(withBase, original)
            try withBase.write(to: files.core.url, atomically: true, encoding: .utf8)
            let compiler = OntologyCompiler()
            let imports = [files.child, files.core]
            let full = try compiler.diagramProjection(path: files.root, options: OntologyDiagramOptions(imports: imports))
            let coreAlias = try alias(full, id: "example.core", version: "1.0.0")
            let selected = try compiler.diagramProjection(path: files.root, options: OntologyDiagramOptions(
                view: .relations, imports: imports, expandedTypes: ["\(coreAlias):Core"]
            ))
            let core = try XCTUnwrap((selected["classes"] as? [[String: Any]])?.first { $0["fqid"] as? String == "\(coreAlias):Core" })
            XCTAssertEqual(core["extends"] as? String, "\(coreAlias):Base")
        }
    }

    func testImportedPackageCanUseDefaultFoundationNamespace() throws {
        try fixture { files in
            let original = try String(contentsOf: files.child.url, encoding: .utf8)
            let amended = original.replacingOccurrences(
                of: "{id: ontology.foundation, namespace: ont, version: 0.2.0}",
                with: "{id: ontology.foundation, version: 0.2.0}"
            )
            XCTAssertNotEqual(amended, original)
            try amended.write(to: files.child.url, atomically: true, encoding: .utf8)
            let graph = try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core]))
            let child = try XCTUnwrap((graph["classes"] as? [[String: Any]])?.first { $0["fqid"] as? String == "child:Child" })
            XCTAssertEqual(child["extends"] as? String, "ont:DomainEntity")
        }
    }

    func testDotLabelsAnUnloadedDirectFoundationWithItsDefaultNamespace() throws {
        try fixture { files in
            let original = try String(contentsOf: files.root.url, encoding: .utf8)
            let amended = original.replacingOccurrences(
                of: "{id: ontology.foundation, namespace: ont, version: 0.2.0}",
                with: "{id: ontology.foundation, version: 0.2.0}"
            )
            XCTAssertNotEqual(amended, original)
            try amended.write(to: files.root.url, atomically: true, encoding: .utf8)
            let dot = try OntologyCompiler().diagramDOT(path: files.root, options: OntologyDiagramOptions())
            XCTAssertTrue(dot.contains("ontology.foundation@0.2.0"))
        }
    }

    func testSameAliasAndDifferentVersionsDoNotMergePackages() throws {
        try fixture { files in
            let root = package(id: "example.root", namespace: "root", className: "Root", imports: [
                ("example.child", "child", "1.0.0"), ("example.core", "foundation", "2.0.0")
            ], target: "child:Child")
            try root.write(to: files.root.url, atomically: true, encoding: .utf8)
            let other = try write(package(id: "example.core", namespace: "newcore", version: "2.0.0",
                                          className: "Core", target: "Core"), to: files.directory, name: "core-v2.yaml")
            let graph = try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [other, files.child, files.core]))
            let one = try alias(graph, id: "example.core", version: "1.0.0")
            let two = try alias(graph, id: "example.core", version: "2.0.0")
            XCTAssertEqual(two, "foundation")
            XCTAssertNotEqual(one, two)
            let relations = try XCTUnwrap(graph["relations"] as? [[String: Any]])
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "child:usesCore" }?["range"] as? String,
                           "\(one):Core")

            let missing = try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [other, files.child]))
            let external = try XCTUnwrap((missing["externalImports"] as? [[String: Any]])?.first {
                $0["id"] as? String == "example.core" && $0["version"] as? String == "1.0.0"
            })
            XCTAssertEqual(external["alias"] as? String, one)
            let missingRelations = try XCTUnwrap(missing["relations"] as? [[String: Any]])
            XCTAssertEqual(missingRelations.first { $0["fqid"] as? String == "child:usesCore" }?["range"] as? String,
                           "\(one):Core")
        }
    }

    func testGeneratedAliasCannotShadowARootImport() throws {
        try fixture { files in
            let compiler = OntologyCompiler()
            let original = try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core]))
            let reserved = try alias(original, id: "example.core", version: "1.0.0")
            let root = package(id: "example.root", namespace: "root", className: "Root", imports: [
                ("example.child", "child", "1.0.0"), ("example.other", reserved, "1.0.0")
            ], target: "child:Child")
            try root.write(to: files.root.url, atomically: true, encoding: .utf8)
            let changed = try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core]))
            let safe = try alias(changed, id: "example.core", version: "1.0.0")
            XCTAssertNotEqual(safe, reserved)
            let relations = try XCTUnwrap(changed["relations"] as? [[String: Any]])
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "child:usesCore" }?["range"] as? String,
                           "\(safe):Core")
        }
    }

    func testSyntheticHashPrefixCollisionsRemainDistinctAndOrderIndependent() throws {
        let root: [String: Any] = ["id": "example.root", "version": "1.0.0", "namespace": "root",
                                   "imports": [["id": "example.child", "version": "1.0.0", "namespace": "child"]]]
        let child: [String: Any] = ["id": "example.child", "version": "1.0.0", "namespace": "child-src",
                                    "imports": [["id": "example.core", "version": "1.0.0", "namespace": "one"],
                                                ["id": "example.core", "version": "2.0.0", "namespace": "two"]]]
        let core1: [String: Any] = ["id": "example.core", "version": "1.0.0", "namespace": "core", "imports": []]
        let core2: [String: Any] = ["id": "example.core", "version": "2.0.0", "namespace": "core", "imports": []]
        func aliases(_ supplied: [[String: Any]]) throws -> [String: String] {
            let scope = try DiagramDependencyScope(root: root, supplied: supplied) { _ in "sha256:" + String(repeating: "a", count: 64) }
            return Dictionary(uniqueKeysWithValues: scope.imported.map { item in
                ("\(item.ir["id"] ?? "")@\(item.ir["version"] ?? "")", item.namespace)
            })
        }
        let first = try aliases([child, core1, core2])
        XCTAssertNotEqual(first["example.core@1.0.0"], first["example.core@2.0.0"])
        XCTAssertEqual(first, try aliases([core2, core1, child]))
    }

    func testAmbiguousRootBindingsAreNotGuessed() throws {
        try fixture { files in
            let root = package(id: "example.root", namespace: "root", className: "Root", imports: [
                ("example.child", "child", "1.0.0"),
                ("example.core", "first", "1.0.0"), ("example.core", "second", "1.0.0")
            ], target: "child:Child")
            try root.write(to: files.root.url, atomically: true, encoding: .utf8)
            XCTAssertThrowsError(try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child])))
            XCTAssertThrowsError(try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core])))
        }
    }

    func testCLIAndSavedProfileAcceptTransitiveFilesWithoutOverwritingInputs() throws {
        try fixture { files in
            let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            let binary = try ontologycTestBinary(in: root).deletingLastPathComponent().appendingPathComponent("ontologyviz")
            func run(_ arguments: [String]) throws -> (Int32, String) {
                let process = Process()
                process.executableURL = binary
                process.arguments = arguments
                let errors = Pipe()
                process.standardError = errors
                process.standardOutput = Pipe()
                try process.run()
                process.waitUntilExit()
                return (process.terminationStatus, String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
            }
            let output = files.directory.appendingPathComponent("cli")
            let args = [files.root.path, "--import", files.core.path, "--import", files.child.path,
                        "--view", "full", "--format", "json", "--out", output.path]
            let direct = try run(args)
            XCTAssertEqual(direct.0, 0, direct.1)
            let profile = files.directory.appendingPathComponent("profile.json")
            let profileData = try JSONSerialization.data(withJSONObject: [
                "schemaVersion": 1, "package": "root.yaml", "imports": ["child.yaml", "core.yaml"], "view": "full"
            ])
            try profileData.write(to: profile)
            let profileOutput = files.directory.appendingPathComponent("profile-output")
            let saved = try run(["--profile", profile.path, "--format", "json", "--out", profileOutput.path])
            XCTAssertEqual(saved.0, 0, saved.1)
            XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("ontology.graph.json")),
                           try Data(contentsOf: profileOutput.appendingPathComponent("ontology.graph.json")))

            let collision = files.directory.appendingPathComponent("collision")
            try FileManager.default.createDirectory(at: collision, withIntermediateDirectories: true)
            let imported = collision.appendingPathComponent("ontology.graph.json")
            let before = try Data(contentsOf: files.core.url)
            try before.write(to: imported)
            let protected = try run([files.root.path, "--import", files.child.path, "--import", imported.path,
                                     "--format", "json", "--out", collision.path])
            XCTAssertEqual(protected.0, 1)
            XCTAssertTrue(protected.1.contains("overwrite input"), protected.1)
            XCTAssertEqual(try Data(contentsOf: imported), before)
        }
    }

    func testUnreachableAndDuplicateOrConflictingPackagesAreRejected() throws {
        try fixture { files in
            let unrelated = try write(package(id: "example.unrelated", namespace: "unrelated",
                                              className: "Other", target: "Other"),
                                      to: files.directory, name: "unrelated.yaml")
            let compiler = OntologyCompiler()
            XCTAssertThrowsError(try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, unrelated])))
            XCTAssertThrowsError(try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core, files.core])))
            let altered = try String(contentsOf: files.core.url, encoding: .utf8)
                .replacingOccurrences(of: "A sample entity.", with: "A conflicting entity.")
            let conflicting = try write(altered, to: files.directory, name: "conflict.yaml")
            XCTAssertThrowsError(try compiler.diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.child, files.core, conflicting])))
        }
    }

    func testDiamondAndCycleShareOneExactIdentityAndTerminate() throws {
        try fixture { files in
            let root = package(id: "example.root", namespace: "root", className: "Root", imports: [
                ("example.child", "child", "1.0.0"), ("example.sibling", "sibling", "1.0.0")
            ], target: "child:Child")
            try root.write(to: files.root.url, atomically: true, encoding: .utf8)
            let sibling = try write(package(id: "example.sibling", namespace: "sibling-src", className: "Sibling",
                                            imports: [("example.core", "shared", "1.0.0")], target: "shared:Core"),
                                    to: files.directory, name: "sibling.yaml")
            let core = package(id: "example.core", namespace: "core", className: "Core",
                               imports: [("example.root", "back", "1.0.0")], target: "back:Root")
            try core.write(to: files.core.url, atomically: true, encoding: .utf8)
            let graph = try OntologyCompiler().diagramProjection(path: files.root,
                options: OntologyDiagramOptions(imports: [files.core, sibling, files.child]))
            let coreAlias = try alias(graph, id: "example.core", version: "1.0.0")
            let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
            XCTAssertEqual(sources.filter { $0["id"] as? String == "example.core" }.count, 1)
            let relations = try XCTUnwrap(graph["relations"] as? [[String: Any]])
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "child:usesCore" }?["range"] as? String,
                           "\(coreAlias):Core")
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "sibling:pointsTo" }?["range"] as? String,
                           "\(coreAlias):Core")
            XCTAssertEqual(relations.first { $0["fqid"] as? String == "\(coreAlias):pointsTo" }?["range"] as? String,
                           "root:Root")
        }
    }
}

private extension DiagramTransitiveImportTests {
    struct Files {
        let directory: URL
        let root: OntologySourcePath
        let child: OntologySourcePath
        let core: OntologySourcePath
    }

    func fixture(_ body: (Files) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let root = try write(package(id: "example.root", namespace: "root", className: "Root",
                                     imports: [("example.child", "child", "1.0.0")], target: "child:Child"),
                             to: directory, name: "root.yaml")
        let child = try write(package(id: "example.child", namespace: "child-src", className: "Child",
                                      imports: [("example.core", "foundation", "1.0.0")],
                                      relation: "usesCore", target: "foundation:Core"), to: directory, name: "child.yaml")
        let core = try write(package(id: "example.core", namespace: "core", className: "Core", target: "Core"),
                             to: directory, name: "core.yaml")
        try body(Files(directory: directory, root: root, child: child, core: core))
    }

    func package(id: String, namespace: String, version: String = "1.0.0", className: String,
                         imports: [(String, String, String)] = [], relation: String = "pointsTo", target: String) -> String {
        let extra = imports.map { "    - {id: \($0.0), namespace: \($0.1), version: \($0.2)}" }.joined(separator: "\n")
        return """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: \(id)
          namespace: \(namespace)
          version: \(version)
          approvalStatus: draft
        spec:
          imports:
            - {id: ontology.foundation, namespace: ont, version: 0.2.0}
        \(extra)
          classes:
            \(className):
              extends: ont:DomainEntity
              description: A sample entity.
          relations:
            \(relation):
              domain: \(className)
              range: \(target)
        """
    }

    func write(_ content: String, to directory: URL, name: String) throws -> OntologySourcePath {
        let url = directory.appendingPathComponent(name)
        try content.write(to: url, atomically: true, encoding: .utf8)
        return OntologySourcePath(url: url)
    }

    func alias(_ graph: [String: Any], id: String, version: String) throws -> String {
        let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
        return try XCTUnwrap(sources.first { $0["id"] as? String == id && $0["version"] as? String == version }?["alias"] as? String)
    }
}
