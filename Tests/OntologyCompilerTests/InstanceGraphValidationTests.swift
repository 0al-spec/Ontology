import Foundation
@testable import OntologyCompiler
import XCTest

final class InstanceGraphValidationTests: XCTestCase {
    var root: URL { URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent() }
    var ir: OntologySourcePath { .init(url: root.appendingPathComponent("SPECS/ontology/packages/events-core/generated/ontology.normalized.json")) }

    func temporary() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ont043-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        return url
    }

    func fixture(_ name: String) -> OntologySourcePath { .init(url: root.appendingPathComponent("SPECS/ontology/fixtures/instance-graphs/\(name).json")) }

    func testValidateAndReportAreDeterministicAndBounded() throws {
        let output = try temporary()
        let compiler = OntologyCompiler()
        let first = try compiler.validateInstanceGraph(graphPath: fixture("synthetic-car"), ontologyIRPath: ir, outPath: .init(url: output.appendingPathComponent("first.json")))
        let second = try compiler.validateInstanceGraph(graphPath: fixture("synthetic-car"), ontologyIRPath: ir, outPath: .init(url: output.appendingPathComponent("second.json")))
        XCTAssertTrue(first.passed)
        XCTAssertTrue(second.passed)
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("first.json")), try Data(contentsOf: output.appendingPathComponent("second.json")))
        let authority = try XCTUnwrap(first.report["authority"] as? [String: Bool])
        XCTAssertEqual(authority["structuralOnly"], true)
        XCTAssertEqual(authority["sourceTruthVerified"], false)
        XCTAssertEqual(authority["responsibilityVerified"], false)
    }

    func testRejectsTamperedIREvenWithUnchangedMetadata() throws {
        let output = try temporary().appendingPathComponent("ir.json")
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: ir.url)) as? [String: Any])
        object["relations"] = []
        try JSONSerialization.data(withJSONObject: object).write(to: output)
        let result = try OntologyCompiler().validateInstanceGraph(graphPath: fixture("synthetic-car"), ontologyIRPath: .init(url: output))
        XCTAssertFalse(result.passed)
        XCTAssertTrue(result.diagnostics.first?.message.contains("instanceGraph.ir.pin") == true)
    }

    func testMalformedNullAndDuplicateJSONKeysFailClosed() throws {
        let output = try temporary().appendingPathComponent("graph.json")
        let originals = ["not json", "null", "[]", "{\"profile\":1,\"profile\":2}", "{\"profile\":1,\"profi\\u006ce\":2}"]
        for text in originals {
            try text.write(to: output, atomically: true, encoding: .utf8)
            let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: output), ontologyIRPath: ir)
            XCTAssertFalse(result.passed, text)
            XCTAssertEqual(result.diagnostics.first?.code, "instanceGraph.input")
        }
    }

    func testExportMatchesGeneratedConsumerBaseline() throws {
        let output = try temporary()
        let compiler = OntologyCompiler()
        let first = output.appendingPathComponent("first")
        let second = output.appendingPathComponent("second")
        try compiler.exportInstanceContract(ontologyIRPath: ir, outDirectory: .init(url: first))
        try compiler.exportInstanceContract(ontologyIRPath: ir, outDirectory: .init(url: second))
        for name in ["instance-graph.ts", "instance-graph.schema.json"] {
            let data = try Data(contentsOf: first.appendingPathComponent(name))
            XCTAssertEqual(data, try Data(contentsOf: second.appendingPathComponent(name)))
            XCTAssertEqual(data, try Data(contentsOf: root.appendingPathComponent("SPECS/ontology/instance-graph/generated/\(name)")))
        }
    }

    func testRealCLIHasFailingExitStatusAndWritesDiagnostics() throws {
        let output = try temporary()
        let pass = try cli(["validate-instances", fixture("synthetic-car").path, "--ontology-ir", ir.path])
        XCTAssertEqual(pass.0, 0, pass.1)
        let report = output.appendingPathComponent("report.json")
        let fail = try cli(["validate-instances", fixture("missing-interval").path, "--ontology-ir", ir.path, "--out", report.path])
        XCTAssertEqual(fail.0, 1, fail.1)
        XCTAssertTrue(fail.1.contains("instanceGraph.field.required"), fail.1)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: report)) as? [String: Any])
        XCTAssertEqual(object["status"] as? String, "failed")
        let exported = try cli(["export-instance-contract", "--ontology-ir", ir.path, "--out", output.appendingPathComponent("export").path])
        XCTAssertEqual(exported.0, 0, exported.1)
    }

    private func cli(_ arguments: [String]) throws -> (Int32, String) {
        let environment = ProcessInfo.processInfo.environment
        let binary = environment["ONTOLOGYC_TEST_BINARY_PATH"].map(URL.init(fileURLWithPath:)) ?? root.appendingPathComponent(".build/debug/ontologyc")
        let process = Process()
        process.executableURL = binary
        process.arguments = arguments
        process.currentDirectoryURL = root
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
