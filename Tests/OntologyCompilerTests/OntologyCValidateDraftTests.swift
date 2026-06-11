import Foundation
import XCTest

final class OntologyCValidateDraftTests: XCTestCase {
    func testValidateDraftCliWritesReportAndFailsInvalidFixture() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-validate-draft")
        let passReport = output.appendingPathComponent("draft-pass-report.yaml")
        let passFixture = "SPECS/ontology/fixtures/induction-drafts/valid/voice-recorder"
        let pass = try ontologyc([
            "validate-draft",
            passFixture,
            "--out",
            passReport.path
        ])

        XCTAssertEqual(pass.status, 0, pass.combinedOutput)
        XCTAssertTrue(pass.stdout.contains("ontologyc validate-draft: PASS"), pass.stdout)
        XCTAssertTrue(try String(contentsOf: passReport).contains("candidate_only"))

        let failReport = output.appendingPathComponent("draft-fail-report.yaml")
        let fail = try ontologyc([
            "validate-draft",
            "SPECS/ontology/fixtures/induction-drafts/invalid/non-draft-package-status",
            "--out",
            failReport.path
        ])

        XCTAssertEqual(fail.status, 1, fail.combinedOutput)
        XCTAssertTrue(fail.stderr.contains("ontologyc validate-draft: FAIL"), fail.stderr)
        XCTAssertTrue(
            fail.combinedOutput.contains("inductionDraft.package.approvalStatus.invalid"),
            fail.combinedOutput
        )
        XCTAssertTrue(try String(contentsOf: failReport).contains("InductionDraftValidationReport"))
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
