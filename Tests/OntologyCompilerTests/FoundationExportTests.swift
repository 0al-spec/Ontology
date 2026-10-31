import Foundation
import OntologyCompiler
import XCTest

final class FoundationExportTests: XCTestCase {
    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private var valid: URL {
        root.appendingPathComponent("SPECS/ontology/fixtures/valid/local-model-omitted-sections.yaml")
    }

    private func temporary() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: dir) }
        return dir
    }

    private func cli(_ args: [String]) throws -> (status: Int32, data: Data) {
        let process = Process()
        process.executableURL = try ontologycTestBinary(in: root)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, data)
    }

    func testExecutableExportsReleaseCatalogAndHelp() throws {
        let result = try cli(["export-foundation"])
        XCTAssertEqual(result.status, 0)
        let file = root.appendingPathComponent("SPECS/ontology/foundation/0.1.0/exports.json")
        XCTAssertEqual(result.data, try Data(contentsOf: file))
        XCTAssertEqual(try cli(["export-foundation", "--help"]).status, 0)
        XCTAssertEqual(try cli(["export-foundation", "extra"]).status, 2)
    }

    func testCheckAndCompileCatchTypoAtItsField() throws {
        let invalid = root.appendingPathComponent("SPECS/ontology/fixtures/invalid/unknown-foundation-export.yaml")
        let good = try cli(["check", "--format", "json", valid.path])
        XCTAssertEqual(good.status, 0)
        XCTAssertEqual(try JSONDecoder().decode([[String: String]].self, from: good.data), [])
        let bad = try cli(["check", invalid.path, "--format=json"])
        XCTAssertEqual(bad.status, 1)
        let findings = try JSONDecoder().decode([[String: String]].self, from: bad.data)
        XCTAssertEqual(findings.count, 1)
        XCTAssertEqual(findings.first?["path"], "spec.classes.Scenario.extends")
        XCTAssertEqual(findings.first?["code"], "class.extends.unresolved")
        XCTAssertTrue(findings.first?["message"]?.contains("sg:Typo") == true)
        XCTAssertEqual(try cli(["check", valid.path, "--format", "other"]).status, 2)
        let directory = try temporary()
        let out = directory.appendingPathComponent("new-sdk")
        let rejected = try cli(["compile", invalid.path, "--target", "typescript", "--out", out.path])
        XCTAssertEqual(rejected.status, 1)
        XCTAssertTrue(String(decoding: rejected.data, as: UTF8.self).contains("spec.classes.Scenario.extends"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: out.path))
        XCTAssertEqual(try cli(["compile", valid.path, "--target", "typescript", "--out", out.path]).status, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: out.appendingPathComponent("ontology.normalized.json").path))
    }

    func testFoundationResolutionUsesImportIdentityVersionAndAlias() throws {
        let source = try String(contentsOf: valid, encoding: .utf8)
        let alias = source.replacingOccurrences(of: "namespace: sg,", with: "namespace: base,")
            .replacingOccurrences(of: "sg:ValueObject", with: "base:ValueObject")
        XCTAssertTrue(try errors(alias).isEmpty)
        XCTAssertTrue(try errors(source.replacingOccurrences(of: "namespace: sg, ", with: "")).isEmpty)
        let unknown = try errors(alias.replacingOccurrences(of: "base:ValueObject", with: "base:Typo"))
        XCTAssertTrue(unknown.contains { $0.code == "class.extends.unresolved" && $0.path == "spec.classes.CheckResult.extends" })
        let wrongVersion = alias.replacingOccurrences(of: "base, version: 0.1.0", with: "base, version: 9.0.0")
        XCTAssertTrue(try errors(wrongVersion).contains { $0.code == "imports.foundation.version.unavailable" && $0.path == "spec.imports[0].version" })
        let futureSymbol = try errors(wrongVersion.replacingOccurrences(of: "base:ValueObject", with: "base:FutureType"))
        XCTAssertEqual(futureSymbol.map(\.code), ["imports.foundation.version.unavailable"])
        let collision = alias.replacingOccurrences(of: "  classes:", with: "    - {id: org.example.other, version: 1.0.0, namespace: base}\n  classes:")
        XCTAssertTrue(try errors(collision).contains { $0.code == "imports.namespace.conflict" })
        let external = alias.replacingOccurrences(of: "specgraph.foundation", with: "org.example.other")
            .replacingOccurrences(of: "base:ValueObject", with: "base:ExternalType")
        XCTAssertTrue(try errors(external).isEmpty)
    }

    func testSlotRoleAndRangeMemberDetermineResolution() throws {
        let source = try String(contentsOf: valid, encoding: .utf8)
        let typed = source.replacingOccurrences(of: "      description: A local test declaration.", with: "      implements: [sg:Auditable]\n      description: A local test declaration.")
            .replacingOccurrences(of: "range: CheckResult", with: "range: {oneOf: [CheckResult, sg:Actor]}")
            + "\n  policies:\n    Review:\n      extends: sg:Policy\n      enforceability: manual\n      appliesTo: [sg:Actor]\n      text: Review.\n"
        XCTAssertTrue(try errors(typed).isEmpty)
        let mixed = try errors(typed.replacingOccurrences(of: "CheckResult, sg:Actor", with: "42, sg:Typo"))
        XCTAssertTrue(mixed.contains { $0.code == "relation.range.type" && $0.path == "spec.relations.includesCheck.range.oneOf[0]" })
        XCTAssertTrue(mixed.contains { $0.code == "relation.range.unresolved" && $0.path == "spec.relations.includesCheck.range.oneOf[1]" })
        for (before, after, path) in [
            ("extends: sg:ValueObject", "extends: sg:Auditable", "spec.classes.Scenario.extends"),
            ("implements: [sg:Auditable]", "implements: [sg:Actor]", "spec.classes.Scenario.implements[0]"),
            ("domain: Scenario", "domain: sg:Typo", "spec.relations.includesCheck.domain"),
            ("CheckResult, sg:Actor", "CheckResult, sg:Typo", "spec.relations.includesCheck.range.oneOf[1]"),
            ("extends: sg:Policy", "extends: sg:Actor", "spec.policies.Review.extends"),
            ("appliesTo: [sg:Actor]", "appliesTo: [sg:Typo]", "spec.policies.Review.appliesTo[0]")
        ] {
            let result = try errors(typed.replacingOccurrences(of: before, with: after))
            XCTAssertTrue(result.contains { $0.path == path }, "Missing diagnostic at \(path)")
        }
    }

    private func errors(_ input: String) throws -> [Diagnostic] {
        let file = try temporary().appendingPathComponent("package.yaml")
        try input.write(to: file, atomically: true, encoding: .utf8)
        return OntologyCompiler().check(path: OntologySourcePath(path: file.path)).filter { $0.severity == "error" }
    }
}
