import Foundation
import XCTest

final class OntologyCFileRegistryTests: XCTestCase {
    func testFileRegistryCliRoundTrip() throws {
        let registry = try makeTemporaryDirectory(name: "ontologyc-file-registry")
        let pullOutput = try makeTemporaryDirectory(name: "ontologyc-file-registry-pull")
        let report = try makeTemporaryDirectory(name: "ontologyc-file-registry-compat")
            .appendingPathComponent("compatibility-report.yaml")
        let registryURL = registry.absoluteString

        let publish = try ontologyc([
            "publish",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--registry",
            registryURL
        ])

        XCTAssertEqual(publish.status, 0, publish.combinedOutput)
        XCTAssertTrue(
            publish.stdout.contains("ontologyc publish: PASS edu.university.examcalc@0.1.0 channel=candidate"),
            publish.stdout
        )

        let pull = try ontologyc([
            "pull",
            "edu.university.examcalc@0.1.0",
            "--registry",
            registryURL,
            "--out",
            pullOutput.path
        ])

        XCTAssertEqual(pull.status, 0, pull.combinedOutput)
        XCTAssertTrue(pull.stdout.contains("ontologyc pull: PASS edu.university.examcalc@0.1.0"), pull.stdout)
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: pullOutput
                .appendingPathComponent("edu-university-examcalc-0.1.0.normalized.json")
                .path)
        )

        let compat = try ontologyc([
            "compat-check",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--against",
            "edu.university.examcalc@0.1.0",
            "--registry",
            registryURL,
            "--out",
            report.path
        ])

        XCTAssertEqual(compat.status, 0, compat.combinedOutput)
        XCTAssertTrue(compat.stdout.contains("ontologyc compat-check: PASS"), compat.stdout)
        XCTAssertTrue(try String(contentsOf: report).contains("compatible: true"))
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func ontologyc(_ arguments: [String]) throws -> FileRegistryCommandResult {
        let binary = repoRoot.appendingPathComponent(".build/debug/ontologyc")
        if !FileManager.default.fileExists(atPath: binary.path) {
            let build = try run("/usr/bin/env", ["swift", "build", "--product", "ontologyc"])
            XCTAssertEqual(build.status, 0, build.combinedOutput)
        }
        return try run(binary.path, arguments)
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> FileRegistryCommandResult {
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

        return FileRegistryCommandResult(
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

private struct FileRegistryCommandResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        stdout + stderr
    }
}
