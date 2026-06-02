import Foundation
import XCTest

final class HypercodeImportTests: XCTestCase {
    func testImportHypercodeWritesCheckableDraftPackage() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-import-hypercode")
            .appendingPathComponent("service-domain-ontology.yaml")
        let result = try ontologyc([
            "import-hypercode",
            "SPECS/ontology/hypercode/service.production.ir.json",
            "--out",
            output.path,
            "--id",
            "org.0al.hypercode.service",
            "--namespace",
            "hypercodeservice",
            "--version",
            "0.1.0"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "ontologyc import-hypercode: PASS \(output.path)"
        )
        let draft = try String(contentsOf: output, encoding: .utf8)
        XCTAssertTrue(draft.contains("kind: DomainOntologyPackage"), draft)
        XCTAssertTrue(draft.contains("Service:"), draft)
        XCTAssertTrue(draft.contains("GeneratedDraftRequiresReview:"), draft)
        XCTAssertFalse(draft.contains("- Service\n        cardinality:"), draft)

        let check = try ontologyc(["check", output.path])
        XCTAssertEqual(check.status, 0, check.combinedOutput)
        XCTAssertTrue(check.stdout.contains("ontologyc check: PASS \(output.path)"), check.stdout)
    }

    func testImportHypercodeRejectsWrongIRVersionWithoutWritingOutput() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-invalid")
        let invalidIR = directory.appendingPathComponent("bad-version.json")
        let output = directory.appendingPathComponent("draft.yaml")
        try """
        {
          "version": "hypercode.ir/v0",
          "nodes": [
            {
              "type": "Service",
              "properties": {},
              "children": []
            }
          ]
        }
        """.write(to: invalidIR, atomically: true, encoding: .utf8)

        let result = try ontologyc([
            "import-hypercode",
            invalidIR.path,
            "--out",
            output.path,
            "--id",
            "org.0al.hypercode.service",
            "--namespace",
            "hypercodeservice",
            "--version",
            "0.1.0"
        ])

        XCTAssertEqual(result.status, 1, result.combinedOutput)
        XCTAssertTrue(result.stderr.contains("Expected Hypercode IR version hypercode.ir/v1"), result.stderr)
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func ontologyc(_ arguments: [String]) throws -> CommandResult {
        let binary = repoRoot.appendingPathComponent(".build/debug/ontologyc")
        if !FileManager.default.fileExists(atPath: binary.path) {
            let build = try run("/usr/bin/env", ["swift", "build", "--product", "ontologyc"])
            XCTAssertEqual(build.status, 0, build.combinedOutput)
        }
        return try run(binary.path, arguments)
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.currentDirectoryURL = repoRoot

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        return CommandResult(
            status: process.terminationStatus,
            stdout: String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "",
            stderr: String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        )
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct CommandResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        stdout + stderr
    }
}
