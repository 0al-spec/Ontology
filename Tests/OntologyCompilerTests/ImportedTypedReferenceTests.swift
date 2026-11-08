import Foundation
import XCTest
@testable import OntologyCompiler

final class ImportedTypedReferenceTests: XCTestCase {
    func testImportedTargetRequiresExactSuppliedClass() throws {
        try fixture { model, shared, _, directory in
            let compiler = OntologyCompiler()
            let path = OntologySourcePath(url: model)
            let imported = OntologySourcePath(url: shared)
            XCTAssertEqual(compiler.check(path: path).map(\.code), ["class.field.target.unresolved"])
            XCTAssertTrue(compiler.check(path: path, imports: [imported]).isEmpty)

            let text = try String(contentsOf: model, encoding: .utf8)
            let unknown = text.replacingOccurrences(of: "shared:Item", with: "shared:Missing")
            XCTAssertEqual(compiler.check(source: unknown, path: path, imports: [imported]).map(\.code),
                           ["class.field.target.unresolved"])
            let undeclared = text.replacingOccurrences(of: "shared:Item", with: "other:Item")
            XCTAssertEqual(compiler.check(source: undeclared, path: path, imports: [imported]).map(\.code),
                           ["class.field.target.unresolved"])

            let wrongVersion = directory.appendingPathComponent("wrong-version.yaml")
            let sharedText = try String(contentsOf: shared, encoding: .utf8)
            try sharedText.replacingOccurrences(of: "version: 1.0.0", with: "version: 2.0.0")
                .write(to: wrongVersion, atomically: true, encoding: .utf8)
            XCTAssertEqual(compiler.check(path: path, imports: [OntologySourcePath(url: wrongVersion)]).map(\.code),
                           ["class.field.target.unresolved"])
            XCTAssertTrue(compiler.check(path: path, imports: [imported, imported])
                .contains { $0.code == "imports.source.duplicate" })
            let shadowedNamespace = text.replacingOccurrences(of: "namespace: draft", with: "namespace: canonical")
            XCTAssertEqual(compiler.check(source: shadowedNamespace, path: path, imports: [imported]).map(\.code),
                           ["class.field.target.namespace_conflict"])
            let distinctLocal = shadowedNamespace
                .replacingOccurrences(of: "    Item: {", with: "    LocalItem: {")
                .replacingOccurrences(of: "domain: Item, range: Item", with: "domain: LocalItem, range: LocalItem")
            XCTAssertTrue(compiler.check(source: distinctLocal, path: path, imports: [imported]).isEmpty)

            let second = directory.appendingPathComponent("second.yaml")
            try sharedText.replacingOccurrences(of: "id: example.shared", with: "id: example.other")
                .write(to: second, atomically: true, encoding: .utf8)
            let ambiguous = text.replacingOccurrences(
                of: "    - {id: example.shared, namespace: shared, version: 1.0.0}",
                with: "    - {id: example.shared, namespace: shared, version: 1.0.0}\n    - {id: example.other, namespace: other, version: 1.0.0}"
            )
            XCTAssertEqual(compiler.check(source: ambiguous, path: path, imports: [imported, OntologySourcePath(url: second)]).map(\.code),
                           ["class.field.target.namespace_conflict"])
        }
    }

    func testGeneratedSDKRetainsImportedIdentityDespiteLocalName() throws {
        try fixture { model, shared, _, directory in
            let out = directory.appendingPathComponent("generated")
            let source = try Data(contentsOf: shared)
            try (Data([0xEF, 0xBB, 0xBF]) + source).write(to: shared)
            let diagnostics = try OntologyCompiler().compile(
                path: OntologySourcePath(url: model), outDirectory: OntologyOutputDirectory(path: out.path),
                imports: [OntologySourcePath(url: shared)]
            )
            XCTAssertTrue(diagnostics.isEmpty, "\(diagnostics)")
            let types = try String(contentsOf: out.appendingPathComponent("types.ts"), encoding: .utf8)
            let schemas = try String(contentsOf: out.appendingPathComponent("schemas.ts"), encoding: .utf8)
            XCTAssertTrue(types.contains("Ref<{ readonly $type: \"canonical:Item\" }>"), types)
            XCTAssertTrue(schemas.contains("target: z.literal(\"canonical:Item\")"), schemas)
            let data = try Data(contentsOf: out.appendingPathComponent("ontology.normalized.json"))
            let ir = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
            let classes = try XCTUnwrap(ir["classes"] as? [[String: Any]])
            let action = try XCTUnwrap(classes.first { $0["fqid"] as? String == "draft:Use" })
            let fields = try XCTUnwrap(action["fields"] as? [[String: Any]])
            XCTAssertEqual(fields.first?["target"] as? String, "shared:Item")
            XCTAssertEqual(fields.first?["targetType"] as? String, "canonical:Item")
            XCTAssertEqual(fields.first?["targetUri"] as? String, "ontology://example.shared/1.0.0/classes/Item")
            let sharedOut = directory.appendingPathComponent("shared-generated")
            XCTAssertTrue(try OntologyCompiler().compile(path: OntologySourcePath(url: shared),
                outDirectory: OntologyOutputDirectory(path: sharedOut.path)).isEmpty)
            let sharedData = try Data(contentsOf: sharedOut.appendingPathComponent("ontology.normalized.json"))
            let sharedIR = try XCTUnwrap(JSONSerialization.jsonObject(with: sharedData) as? [String: Any])
            let sourceDigest = try XCTUnwrap(sharedIR["sourceDigest"] as? String)
            XCTAssertEqual(fields.first?["targetSourceDigest"] as? String, sourceDigest)
        }
    }

    func testDefaultFoundationAliasesPreserveImportedIdentity() throws {
        try fixture { model, shared, _, directory in
            let originalModel = try String(contentsOf: model, encoding: .utf8)
            let originalShared = try String(contentsOf: shared, encoding: .utf8)
            for (id, version, alias) in [("ontology.foundation", "0.2.0", "ont"), ("specgraph.foundation", "0.1.0", "sg")] {
                let foundation = directory.appendingPathComponent("\(alias)-foundation.yaml")
                let source = originalShared.replacingOccurrences(
                    of: "id: example.shared, namespace: canonical, version: 1.0.0",
                    with: "id: \(id), namespace: canonical, version: \(version)"
                )
                try source.write(to: foundation, atomically: true, encoding: .utf8)
                let sourceModel = originalModel
                    .replacingOccurrences(of: "{id: ontology.foundation, namespace: ont, version: 0.2.0}",
                                          with: "{id: \(id), version: \(version)}")
                    .replacingOccurrences(of: "    - {id: example.shared, namespace: shared, version: 1.0.0}\n", with: "")
                    .replacingOccurrences(of: "extends: ont:Action", with: "extends: ont:DomainEntity")
                    .replacingOccurrences(of: "ont:", with: "\(alias):")
                    .replacingOccurrences(of: "shared:Item", with: "\(alias):Item")
                try sourceModel.write(to: model, atomically: true, encoding: .utf8)
                let output = directory.appendingPathComponent("generated-\(alias)")
                let diagnostics = try OntologyCompiler().compile(
                    path: OntologySourcePath(url: model), outDirectory: OntologyOutputDirectory(path: output.path),
                    imports: [OntologySourcePath(url: foundation)]
                )
                guard diagnostics.isEmpty else {
                    XCTFail("\(diagnostics)")
                    continue
                }
                let data = try Data(contentsOf: output.appendingPathComponent("ontology.normalized.json"))
                let ir = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
                let classes = try XCTUnwrap(ir["classes"] as? [[String: Any]])
                let action = try XCTUnwrap(classes.first { $0["fqid"] as? String == "draft:Use" })
                let fields = try XCTUnwrap(action["fields"] as? [[String: Any]])
                XCTAssertEqual(fields.first?["target"] as? String, "\(alias):Item")
                XCTAssertEqual(fields.first?["targetType"] as? String, "canonical:Item")
                XCTAssertEqual(fields.first?["targetUri"] as? String, "ontology://\(id)/\(version)/classes/Item")
                XCTAssertNotNil(fields.first?["targetSourceDigest"])
                let types = try String(contentsOf: output.appendingPathComponent("types.ts"), encoding: .utf8)
                let schemas = try String(contentsOf: output.appendingPathComponent("schemas.ts"), encoding: .utf8)
                XCTAssertTrue(types.contains("Ref<{ readonly $type: \"canonical:Item\" }>"), types)
                XCTAssertTrue(schemas.contains("target: z.literal(\"canonical:Item\")"), schemas)
            }
        }
    }

    func testTransitiveDiagramRebindsImportedFieldToExactPackage() throws {
        try fixture { model, shared, overview, _ in
            let imports = [OntologySourcePath(url: model), OntologySourcePath(url: shared)]
            let compiler = OntologyCompiler()
            let graph = try compiler.diagramProjection(path: OntologySourcePath(url: overview),
                                                       options: OntologyDiagramOptions(imports: imports))
            let sources = try XCTUnwrap(graph["sources"] as? [[String: Any]])
            let sharedSource = try XCTUnwrap(sources.first { $0["id"] as? String == "example.shared" })
            let alias = try XCTUnwrap(sharedSource["alias"] as? String)
            let classes = try XCTUnwrap(graph["classes"] as? [[String: Any]])
            let action = try XCTUnwrap(classes.first { $0["fqid"] as? String == "model:Use" })
            let fields = try XCTUnwrap(action["fields"] as? [[String: Any]])
            XCTAssertEqual(fields.first?["target"] as? String, "\(alias):Item")
            XCTAssertTrue(classes.contains { $0["fqid"] as? String == "\(alias):Item" })
            XCTAssertThrowsError(try compiler.diagramProjection(path: OntologySourcePath(url: overview),
                options: OntologyDiagramOptions(imports: [OntologySourcePath(url: model)])))
        }
    }

    func testCLIRequiresAndAcceptsExplicitImport() throws {
        try fixture { model, shared, _, _ in
            let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
                .deletingLastPathComponent().deletingLastPathComponent()
            let binary = try ontologycTestBinary(in: root)
            func run(_ arguments: [String]) throws -> (Int32, String) {
                let process = Process()
                process.executableURL = binary
                process.arguments = arguments
                let output = Pipe()
                process.standardOutput = output
                process.standardError = output
                try process.run()
                process.waitUntilExit()
                let text = String(decoding: output.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
                return (process.terminationStatus, text)
            }
            let missing = try run(["check", model.path])
            XCTAssertEqual(missing.0, 1, missing.1)
            let present = try run(["check", model.path, "--import", shared.path])
            XCTAssertEqual(present.0, 0, present.1)
            let duplicate = try run(["check", model.path, "--import", shared.path, "--import", shared.path])
            XCTAssertEqual(duplicate.0, 1, duplicate.1)
            XCTAssertTrue(duplicate.1.contains("imports.source.duplicate"), duplicate.1)
        }
    }

    private func fixture(_ run: (URL, URL, URL, URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let shared = directory.appendingPathComponent("shared.yaml")
        let model = directory.appendingPathComponent("model.yaml")
        let overview = directory.appendingPathComponent("overview.yaml")
        try """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata: {id: example.shared, namespace: canonical, version: 1.0.0}
        spec:
          imports:
            - {id: ontology.foundation, namespace: ont, version: 0.2.0}
          classes:
            Item: {extends: 'ont:DomainEntity', description: A shared item.}
          relations:
            contains: {domain: Item, range: Item, description: Shared relation.}
        """.write(to: shared, atomically: true, encoding: .utf8)
        try """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata: {id: example.model, namespace: draft, version: 1.0.0}
        spec:
          imports:
            - {id: ontology.foundation, namespace: ont, version: 0.2.0}
            - {id: example.shared, namespace: shared, version: 1.0.0}
          classes:
            Item: {extends: 'ont:DomainEntity', description: Different local item.}
            Use:
              extends: ont:Action
              description: Use a shared item.
              fields:
                target: {type: ref, target: 'shared:Item', required: true}
          relations:
            uses: {domain: Item, range: Item, description: Local relation.}
        """.write(to: model, atomically: true, encoding: .utf8)
        try """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata: {id: example.overview, namespace: overview, version: 1.0.0}
        spec:
          imports:
            - {id: ontology.foundation, namespace: ont, version: 0.2.0}
            - {id: example.model, namespace: model, version: 1.0.0}
          classes:
            Root: {extends: 'ont:DomainEntity', description: Overview.}
          relations:
            includes: {domain: Root, range: 'model:Use', description: Includes.}
        """.write(to: overview, atomically: true, encoding: .utf8)
        try run(model, shared, overview, directory)
    }
}
