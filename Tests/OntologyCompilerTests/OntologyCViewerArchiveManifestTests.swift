import Foundation
import XCTest

final class OntologyCViewerArchiveManifestTests: XCTestCase {
    func testExportViewerArchiveManifestWritesSpecSpaceContract() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-viewer-archive-manifest")
        let manifest = output.appendingPathComponent("ontology-viewer-archive-manifest.json")
        let result = try ontologyc([
            "export-viewer-archive-manifest",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--generated",
            "SPECS/ontology/packages/examcalc/generated",
            "--out",
            manifest.path
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertTrue(result.stdout.contains("ontologyc export-viewer-archive-manifest: PASS \(manifest.path)"))

        let object = try manifestObject(at: manifest)
        XCTAssertEqual(object["artifact_kind"] as? String, "ontology_viewer_archive_manifest")
        XCTAssertEqual(object["schema_version"] as? Int, 1)

        let package = try XCTUnwrap(object["package"] as? [String: Any])
        XCTAssertEqual(package["id"] as? String, "edu.university.examcalc")
        XCTAssertEqual(package["namespace"] as? String, "examcalc")
        XCTAssertEqual(package["version"] as? String, "0.1.0")

        let boundary = try XCTUnwrap(object["authority_boundary"] as? [String: Any])
        XCTAssertEqual(boundary["viewer_manifest_is_authority"] as? Bool, false)
        XCTAssertEqual(boundary["may_write_ontology_package"] as? Bool, false)
        XCTAssertEqual(boundary["may_publish_registry_entry"] as? Bool, false)
        XCTAssertEqual(boundary["may_mutate_specgraph"] as? Bool, false)

        let artifacts = try XCTUnwrap(object["artifacts"] as? [[String: Any]])
        XCTAssertTrue(requiredArtifactPaths(artifacts).contains {
            $0.hasSuffix("SPECS/ontology/packages/examcalc/domain-ontology-package.yaml")
        })
        XCTAssertTrue(requiredArtifactPaths(artifacts).contains {
            $0.hasSuffix("SPECS/ontology/packages/examcalc/generated/ontology.normalized.json")
        })
        XCTAssertTrue(artifacts.contains {
            $0["role"] as? String == "generated_sdk" &&
                ($0["path"] as? String)?.hasSuffix("generated/refs.ts") == true
        })

        let publicSafety = try XCTUnwrap(object["public_safety"] as? [String: Any])
        XCTAssertTrue((publicSafety["public_safe_roles"] as? [String] ?? []).contains("normalized_ir"))
        XCTAssertTrue((publicSafety["local_only_roles"] as? [String] ?? []).contains("governance_evidence"))
    }

    func testExportViewerArchiveManifestRejectsMismatchedNormalizedIR() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-viewer-archive-mismatch")
        let generated = output.appendingPathComponent("generated")
        try FileManager.default.createDirectory(at: generated, withIntermediateDirectories: true)
        let sourceIR = repoRoot.appendingPathComponent("SPECS/ontology/packages/examcalc/generated/ontology.normalized.json")
        let staleIR = generated.appendingPathComponent("ontology.normalized.json")
        var object = try manifestObject(at: sourceIR)
        object["id"] = "org.0al.stale"
        try writeJSON(object, to: staleIR)

        let result = try ontologyc([
            "export-viewer-archive-manifest",
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml",
            "--generated",
            generated.path,
            "--out",
            output.appendingPathComponent("manifest.json").path
        ])

        XCTAssertEqual(result.status, 1, result.combinedOutput)
        XCTAssertTrue(result.combinedOutput.contains("viewerArchive.normalizedIR.mismatch"))
        XCTAssertTrue(result.combinedOutput.contains("normalized IR id must match package metadata edu.university.examcalc"))
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

    private func manifestObject(at url: URL) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }

    private func writeJSON(_ object: [String: Any], to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: url)
    }

    private func requiredArtifactPaths(_ artifacts: [[String: Any]]) -> Set<String> {
        Set(
            artifacts
                .filter { $0["required"] as? Bool == true }
                .compactMap { $0["path"] as? String }
        )
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
