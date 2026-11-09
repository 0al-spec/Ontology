import Foundation
import XCTest
@testable import OntologyCompiler

final class ImportedReferenceWorkflowTests: XCTestCase {
    func testDiffUsesSeparateDependencySnapshotsAndFailsBeforeWriting() throws {
        try withFixture { fixture in
            let compiler = OntologyCompiler()
            let out = OntologyOutputPath(url: fixture.directory.appendingPathComponent("diff.yaml"))
            let missing = try compiler.diffPackages(from: fixture.old, to: fixture.new, outPath: out)
            XCTAssertTrue(compiler.hasErrors(missing))
            XCTAssertFalse(FileManager.default.fileExists(atPath: out.path))

            let wrong = try compiler.diffPackages(from: fixture.old, to: fixture.new, outPath: out,
                                                   fromImports: [fixture.sharedV1], toImports: [fixture.sharedV1])
            XCTAssertTrue(compiler.hasErrors(wrong))
            XCTAssertFalse(FileManager.default.fileExists(atPath: out.path))
            let noItemPath = fixture.directory.appendingPathComponent("missing-target.yaml")
            let sharedSource = try String(contentsOfFile: fixture.sharedV1.path, encoding: .utf8)
            try sharedSource.replacingOccurrences(of: "Item", with: "Other")
                .write(to: noItemPath, atomically: true, encoding: .utf8)
            let noTarget = try compiler.diffPackages(from: fixture.old, to: fixture.old, outPath: out,
                fromImports: [fixture.sharedV1], toImports: [OntologySourcePath(url: noItemPath)])
            XCTAssertTrue(noTarget.contains { $0.code == "class.field.target.unresolved" })
            XCTAssertFalse(FileManager.default.fileExists(atPath: out.path))

            let diagnostics = try compiler.diffPackages(from: fixture.old, to: fixture.new, outPath: out,
                                                         fromImports: [fixture.sharedV1], toImports: [fixture.sharedV2])
            XCTAssertFalse(compiler.hasErrors(diagnostics), "\(diagnostics)")
            let report = try String(contentsOfFile: out.path, encoding: .utf8)
            XCTAssertTrue(report.contains("compatible: false"), report)
            XCTAssertTrue(report.contains("draft:Use.target"), report)

            let same = try compiler.diffPackages(from: fixture.old, to: fixture.old, outPath: out,
                                                 fromImports: [fixture.sharedV1], toImports: [fixture.sharedV1OtherBytes])
            XCTAssertFalse(compiler.hasErrors(same), "\(same)")
            XCTAssertTrue(try String(contentsOfFile: out.path, encoding: .utf8).contains("compatible: true"))
            let renamedPath = fixture.directory.appendingPathComponent("renamed-namespace.yaml")
            try sharedSource.replacingOccurrences(of: "namespace: canonical", with: "namespace: changed")
                .write(to: renamedPath, atomically: true, encoding: .utf8)
            let renamed = try compiler.diffPackages(from: fixture.old, to: fixture.old, outPath: out,
                fromImports: [fixture.sharedV1], toImports: [OntologySourcePath(url: renamedPath)])
            XCTAssertFalse(compiler.hasErrors(renamed), "\(renamed)")
            XCTAssertTrue(try String(contentsOfFile: out.path, encoding: .utf8).contains("compatible: false"))
        }
    }

    func testRegistryAndTrustedDecisionUseTheSameExplicitImports() throws {
        try withFixture { fixture in
            let compiler = OntologyCompiler()
            let registry = try XCTUnwrap(RegistryBaseURL(url: fixture.directory.appendingPathComponent("registry")))
            XCTAssertThrowsError(try compiler.publishPackage(path: fixture.old, registry: registry, token: nil))
            XCTAssertFalse(FileManager.default.fileExists(atPath: fixture.directory.appendingPathComponent("registry/ontologies").path))
            let published = try compiler.publishPackage(path: fixture.old, registry: registry, token: nil, imports: [fixture.sharedV1])
            XCTAssertEqual(published.packageRef.rawValue, "example.model@1.0.0")
            let irPath = fixture.directory.appendingPathComponent("registry/ontologies/example.model/1.0.0/ontology.normalized.json")
            let ir = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: irPath)) as? [String: Any])
            let classes = try XCTUnwrap(ir["classes"] as? [[String: Any]])
            let action = try XCTUnwrap(classes.first { $0["id"] as? String == "Use" })
            let fields = try XCTUnwrap(action["fields"] as? [[String: Any]])
            XCTAssertEqual(fields.first?["targetUri"] as? String, "ontology://example.shared/1.0.0/classes/Item")
            XCTAssertNotNil(fields.first?["targetSourceDigest"])
            let ref = try XCTUnwrap(OntologyPackageReference(rawValue: "example.model@1.0.0"))
            XCTAssertTrue(try compiler.compatCheckPackage(path: fixture.old, against: ref, registry: registry,
                                                          token: nil, outPath: nil, imports: [fixture.sharedV1]))
            XCTAssertFalse(try compiler.compatCheckPackage(path: fixture.new, against: ref, registry: registry,
                                                           token: nil, outPath: nil, imports: [fixture.sharedV2]))
            XCTAssertThrowsError(try compiler.compatCheckPackage(path: fixture.new, against: ref, registry: registry,
                                                                token: nil, outPath: nil, imports: [fixture.sharedV1]))
            var oldIR = ir
            var oldClasses = classes
            let index = try XCTUnwrap(oldClasses.firstIndex { $0["id"] as? String == "Use" })
            var oldFields = fields
            oldFields[0].removeValue(forKey: "targetUri")
            oldFields[0].removeValue(forKey: "targetSourceDigest")
            oldClasses[index]["fields"] = oldFields
            oldIR["classes"] = oldClasses
            let report = compiler.compatibilityReport(fromIR: oldIR, toIR: ir)
            let result = try XCTUnwrap(report["result"] as? [String: Any])
            XCTAssertEqual(result["compatible"] as? Bool, false)

            let decision = try decisionPath(for: fixture)
            let missingPackage = try compiler.validateGovernanceDecision(decisionPath: decision, packagePath: nil,
                goldenReportPath: nil, outPath: nil, imports: [fixture.sharedV2])
            XCTAssertTrue(missingPackage.diagnostics.contains { $0.code == "governance.imports.package.required" })
            XCTAssertThrowsError(try compiler.publishPackage(path: fixture.new, registry: registry, token: nil,
                channel: .trusted, governanceDecisionPath: decision))
            _ = try compiler.publishPackage(path: fixture.new, registry: registry, token: nil, channel: .trusted,
                                            governanceDecisionPath: decision, imports: [fixture.sharedV2])
        }
    }

    func testCLIUsesScopedAndRepeatableImportOptions() throws {
        try withFixture { fixture in
            let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            let binary = try ontologycTestBinary(in: root)
            func run(_ arguments: [String]) throws -> (Int32, String) {
                let process = Process()
                process.executableURL = binary
                process.arguments = arguments
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe
                try process.run()
                process.waitUntilExit()
                return (process.terminationStatus, String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self))
            }
            let report = fixture.directory.appendingPathComponent("cli-diff.yaml").path
            let diff = try run(["diff", "--from", fixture.old.path, "--to", fixture.new.path, "--out", report,
                                "--from-import", fixture.sharedV1.path, "--to-import", fixture.sharedV2.path])
            XCTAssertEqual(diff.0, 0, diff.1)
            let registry = fixture.directory.appendingPathComponent("cli-registry").absoluteString
            let publish = try run(["publish", fixture.old.path, "--registry", registry, "--import", fixture.sharedV1.path])
            XCTAssertEqual(publish.0, 0, publish.1)
            let check = try run(["compat-check", fixture.old.path, "--against", "example.model@1.0.0",
                                 "--registry", registry, "--import", fixture.sharedV1.path])
            XCTAssertEqual(check.0, 0, check.1)
            let decision = try decisionPath(for: fixture)
            let governance = try run(["validate-governance-decision", decision.path, "--package", fixture.new.path,
                                      "--import", fixture.sharedV2.path])
            XCTAssertEqual(governance.0, 0, governance.1)
            let ignoredImport = try run(["validate-governance-decision", decision.path, "--import", fixture.sharedV2.path])
            XCTAssertEqual(ignoredImport.0, 1, ignoredImport.1)
            XCTAssertTrue(ignoredImport.1.contains("governance.imports.package.required"), ignoredImport.1)
            let duplicate = try run(["publish", fixture.old.path, "--registry", registry,
                                     "--import", fixture.sharedV1.path, "--import", fixture.sharedV1.path])
            XCTAssertEqual(duplicate.0, 1, duplicate.1)
            XCTAssertTrue(duplicate.1.contains("imports.source.duplicate"), duplicate.1)
        }
    }

    private struct Fixture {
        let directory: URL
        let old: OntologySourcePath
        let new: OntologySourcePath
        let sharedV1: OntologySourcePath
        let sharedV2: OntologySourcePath
        let sharedV1OtherBytes: OntologySourcePath
    }

    private func withFixture(_ body: (Fixture) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        func write(_ name: String, _ content: String) throws -> OntologySourcePath {
            let url = directory.appendingPathComponent(name)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return OntologySourcePath(url: url)
        }
        func shared(_ version: String, _ description: String) -> String {
            """
            apiVersion: ontology.specgraph.io/v1alpha1
            kind: DomainOntologyPackage
            metadata: {id: example.shared, namespace: canonical, version: \(version)}
            spec:
              imports:
                - {id: ontology.foundation, namespace: ont, version: 0.2.0}
              classes:
                Item: {extends: 'ont:DomainEntity', description: \(description)}
              relations:
                contains: {domain: Item, range: Item, description: Shared relation.}
            """
        }
        func model(_ version: String) -> String {
            """
            apiVersion: ontology.specgraph.io/v1alpha1
            kind: DomainOntologyPackage
            metadata: {id: example.model, namespace: draft, version: \(version)}
            spec:
              imports:
                - {id: ontology.foundation, namespace: ont, version: 0.2.0}
                - {id: example.shared, namespace: shared, version: \(version)}
              classes:
                Use:
                  extends: ont:Action
                  description: Use a shared item.
                  fields:
                    target: {type: ref, target: 'shared:Item', required: true}
              relations:
                uses: {domain: Use, range: Use, description: Local relation.}
            """
        }
        try body(Fixture(directory: directory,
            old: write("old.yaml", model("1.0.0")), new: write("new.yaml", model("2.0.0")),
            sharedV1: write("shared-v1.yaml", shared("1.0.0", "Shared item.")),
            sharedV2: write("shared-v2.yaml", shared("2.0.0", "Shared item.")),
            sharedV1OtherBytes: write("shared-v1-other.yaml", shared("1.0.0", "Updated description."))))
    }

    private func decisionPath(for fixture: Fixture) throws -> OntologySourcePath {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let original = try String(contentsOf: root.appendingPathComponent("SPECS/ontology/examples/governance/approved-decision.yaml"), encoding: .utf8)
        let decision = original.replacingOccurrences(of: "edu.university.examcalc", with: "example.model")
            .replacingOccurrences(of: "namespace: examcalc", with: "namespace: draft")
            .replacingOccurrences(of: "version: 0.1.0", with: "version: 2.0.0")
        let url = fixture.directory.appendingPathComponent("decision.yaml")
        try decision.write(to: url, atomically: true, encoding: .utf8)
        return OntologySourcePath(url: url)
    }
}
