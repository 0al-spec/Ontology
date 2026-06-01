import CryptoKit
import Foundation
import XCTest

final class OntologyCRegressionTests: XCTestCase {
    private let expectedGeneratedFiles = [
        "ontology.normalized.json",
        "refs.ts",
        "types.ts",
        "relations.ts",
        "policies.ts",
        "state-machines.ts",
        "protocols.ts",
        "schemas.ts",
        "registry.ts",
        "validators.ts"
    ]

    func testCheckPassesCanonicalExamcalcPackage() throws {
        let result = try ontologyc([
            "check",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "ontologyc check: PASS SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
        )
    }

    func testRootHelpPrintsCommandSummary() throws {
        let result = try ontologyc(["--help"])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(result.stdout.contains("Usage:"), result.stdout)
        XCTAssertTrue(result.stdout.contains("ontologyc <command> [options]"), result.stdout)
        XCTAssertTrue(result.stdout.contains("compat-check"), result.stdout)
        XCTAssertEqual(result.stderr, "")
    }

    func testCommandHelpPrintsCommandSpecificUsage() throws {
        let result = try ontologyc(["compile", "--help"])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(
            result.stdout.contains("ontologyc compile <package.yaml> --target typescript --out <directory>"),
            result.stdout
        )
        XCTAssertEqual(result.stderr, "")
    }

    func testCompileAcceptsFlagsInAnyOrder() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-compile-reordered")
        let result = try ontologyc([
            "compile",
            "--out",
            output.path,
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--target",
            "typescript"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "ontologyc compile: PASS \(output.path)"
        )
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("schemas.ts").path))
    }

    func testDiffAcceptsFlagsInAnyOrder() throws {
        let report = try makeTemporaryDirectory(name: "ontologyc-diff-reordered")
            .appendingPathComponent("compatibility-report.yaml")
        let result = try ontologyc([
            "diff",
            "--out",
            report.path,
            "--to",
            "SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml",
            "--from",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(result.stdout.contains("ontologyc diff: PASS \(report.path)"), result.stdout)
        XCTAssertTrue(FileManager.default.fileExists(atPath: report.path))
    }

    func testMissingRequiredOptionPrintsActionableUsage() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-compile-error")
        let result = try ontologyc([
            "compile",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--out",
            output.path
        ])

        XCTAssertEqual(result.status, 2, result.combinedOutput)
        XCTAssertTrue(result.stderr.contains("missing required option --target"), result.stderr)
        XCTAssertTrue(result.stderr.contains("ontologyc compile <package.yaml>"), result.stderr)
    }

    func testOptionValueMayStartWithDash() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-compile-dash-value")
        let result = try ontologyc([
            "compile",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--target",
            "-typescript",
            "--out",
            output.path
        ])

        XCTAssertEqual(result.status, 2, result.combinedOutput)
        XCTAssertTrue(result.stderr.contains("unsupported target -typescript"), result.stderr)
        XCTAssertFalse(result.stderr.contains("missing value for --target"), result.stderr)
    }

    func testDoubleDashAllowsDashPrefixedPositionalArgument() throws {
        let result = try ontologyc(["check", "--", "-missing-package.yaml"])

        XCTAssertEqual(result.status, 1, result.combinedOutput)
        XCTAssertTrue(result.combinedOutput.contains("-missing-package.yaml"), result.combinedOutput)
        XCTAssertFalse(result.stderr.contains("unknown option -missing-package.yaml"), result.stderr)
    }

    func testInvalidFixturesFail() throws {
        let fixtures = [
            "SPECS/ontology/fixtures/invalid/invalid-inheritance.yaml",
            "SPECS/ontology/fixtures/invalid/missing-metadata.yaml",
            "SPECS/ontology/fixtures/invalid/unknown-relation-ref.yaml",
            "SPECS/ontology/fixtures/invalid/unsafe-executable-looking-yaml.yaml"
        ]

        for fixture in fixtures {
            let result = try ontologyc(["check", fixture])

            XCTAssertNotEqual(result.status, 0, "\(fixture) unexpectedly passed")
            XCTAssertTrue(result.combinedOutput.contains("error"), result.combinedOutput)
        }
    }

    func testCompileProducesBaselineGeneratedArtifacts() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-compile")
        let result = try ontologyc([
            "compile",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--target",
            "typescript",
            "--out",
            output.path
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "ontologyc compile: PASS \(output.path)"
        )

        for file in expectedGeneratedFiles {
            let actual = output.appendingPathComponent(file)
            let expected = repoRoot
                .appendingPathComponent("SPECS/ontology/packages/examcalc/generated")
                .appendingPathComponent(file)

            XCTAssertTrue(FileManager.default.fileExists(atPath: actual.path), "Missing \(file)")
            XCTAssertEqual(
                try Data(contentsOf: actual),
                try Data(contentsOf: expected),
                "\(file) drifted from committed baseline"
            )
        }

        let ir = output.appendingPathComponent("ontology.normalized.json")
        XCTAssertEqual(
            try sha256Hex(of: ir),
            "bb626c69bb0989ab6e7e5605e0dde73dee9e220b6b203d584924e22a6e20936d"
        )
    }

    func testSpecGraphValidationOutputsMatchBaseline() throws {
        let validOutput = try makeTemporaryDirectory(name: "ontologyc-valid-specgraph")
        let valid = try ontologyc([
            "validate-specgraph",
            "SPECS/specgraph/semantic-validation/valid-semantic-binding.yaml",
            "--ontology-ir",
            "SPECS/ontology/packages/examcalc/generated/ontology.normalized.json",
            "--out",
            validOutput.path
        ])

        XCTAssertEqual(valid.status, 0, valid.combinedOutput)
        XCTAssertTrue(valid.stdout.contains("resolved=25 gaps=0"), valid.stdout)
        try assertOutput(
            validOutput.appendingPathComponent("concept-refs.yaml"),
            matches: "SPECS/specgraph/semantic-validation/out/valid/concept-refs.yaml"
        )

        let missingOutput = try makeTemporaryDirectory(name: "ontologyc-missing-specgraph")
        let missing = try ontologyc([
            "validate-specgraph",
            "SPECS/specgraph/semantic-validation/missing-ref-semantic-binding.yaml",
            "--ontology-ir",
            "SPECS/ontology/packages/examcalc/generated/ontology.normalized.json",
            "--out",
            missingOutput.path
        ])

        XCTAssertEqual(missing.status, 0, missing.combinedOutput)
        XCTAssertTrue(missing.stdout.contains("resolved=2 gaps=1"), missing.stdout)
        try assertOutput(
            missingOutput.appendingPathComponent("ontology-gaps.yaml"),
            matches: "SPECS/specgraph/semantic-validation/out/missing/ontology-gaps.yaml"
        )
    }

    func testCompatibilityDiffOutputMatchesBaseline() throws {
        let report = try makeTemporaryDirectory(name: "ontologyc-diff")
            .appendingPathComponent("compatibility-report.yaml")
        let result = try ontologyc([
            "diff",
            "--from",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--to",
            "SPECS/ontology/packages/examcalc/compatibility/examcalc-0.2.0-breaking.yaml",
            "--out",
            report.path
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(result.stdout.contains("ontologyc diff: PASS"), result.stdout)
        try assertOutput(
            report,
            matches: "SPECS/specgraph/semantic-validation/out/compatibility-report.yaml"
        )
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

    private func assertOutput(_ actual: URL, matches expectedPath: String) throws {
        let expected = repoRoot.appendingPathComponent(expectedPath)
        XCTAssertEqual(
            try Data(contentsOf: actual),
            try Data(contentsOf: expected),
            "\(actual.lastPathComponent) drifted from \(expectedPath)"
        )
    }

    private func sha256Hex(of url: URL) throws -> String {
        let digest = SHA256.hash(data: try Data(contentsOf: url))
        return digest.map { String(format: "%02x", $0) }.joined()
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
