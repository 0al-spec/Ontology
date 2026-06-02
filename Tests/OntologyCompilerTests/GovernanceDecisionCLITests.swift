import Foundation
import XCTest

final class GovernanceDecisionCLITests: XCTestCase {
    func testValidateGovernanceDecisionCliWritesReportAndRejectsInvalidActor() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-governance-decision")
        let passReport = output.appendingPathComponent("governance-report.yaml")
        let pass = try ontologyc([
            "validate-governance-decision",
            "SPECS/ontology/examples/governance/approved-decision.yaml",
            "--package",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--out",
            passReport.path
        ])

        XCTAssertEqual(pass.status, 0, pass.combinedOutput)
        XCTAssertTrue(pass.stdout.contains("ontologyc validate-governance-decision: PASS"), pass.stdout)
        XCTAssertTrue(FileManager.default.fileExists(atPath: passReport.path))
        XCTAssertTrue(try String(contentsOf: passReport).contains("OntologyGovernanceDecisionValidationReport"))

        let fail = try ontologyc([
            "validate-governance-decision",
            "SPECS/ontology/examples/governance/invalid-agent-approval.yaml"
        ])

        XCTAssertEqual(fail.status, 1, fail.combinedOutput)
        XCTAssertTrue(fail.stderr.contains("ontologyc validate-governance-decision: FAIL"), fail.stderr)
        XCTAssertTrue(fail.combinedOutput.contains("governance.decision.actor.authority.invalid"), fail.combinedOutput)
    }

    func testPublishTrustedRequiresGovernanceDecisionBeforeRegistryRequest() throws {
        let result = try ontologyc([
            "publish",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--registry",
            "https://registry.example.com",
            "--channel",
            "trusted"
        ])

        XCTAssertEqual(result.status, 1, result.combinedOutput)
        XCTAssertTrue(result.stderr.contains("ontologyc publish: FAIL"), result.stderr)
        XCTAssertTrue(result.combinedOutput.contains("registry.publish.governanceDecision.required"), result.combinedOutput)
    }

    func testPublishRejectsInvalidChannelUsage() throws {
        let result = try ontologyc([
            "publish",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--registry",
            "https://registry.example.com",
            "--channel",
            "stable"
        ])

        XCTAssertEqual(result.status, 2, result.combinedOutput)
        XCTAssertTrue(result.stderr.contains("invalid publish channel stable"), result.stderr)
        XCTAssertTrue(result.stderr.contains("candidate or trusted"), result.stderr)
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
