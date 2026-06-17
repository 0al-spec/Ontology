import Foundation
import XCTest

final class SpecGraphCorePackageTests: XCTestCase {
    private let packagePath = "SPECS/ontology/packages/specgraph-core/domain-ontology-package.yaml"
    private let generatedPath = "SPECS/ontology/packages/specgraph-core/generated"
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

    private let expectedClasses: Set<String> = [
        "SpecGraph",
        "Intent",
        "Spec",
        "Node",
        "Edge",
        "Requirement",
        "AcceptanceCriterion",
        "Decision",
        "Constraint",
        "Invariant",
        "Evidence",
        "CodeSurface",
        "Test",
        "Release"
    ]

    private let expectedRelations: [String: (String, String)] = [
        "containsNode": ("sgcore:SpecGraph", "sgcore:Node"),
        "containsEdge": ("sgcore:SpecGraph", "sgcore:Edge"),
        "containsSpec": ("sgcore:SpecGraph", "sgcore:Spec"),
        "refinesIntent": ("sgcore:Spec", "sgcore:Intent"),
        "definesRequirement": ("sgcore:Spec", "sgcore:Requirement"),
        "hasAcceptanceCriterion": ("sgcore:Spec", "sgcore:AcceptanceCriterion"),
        "requirementValidatedByCriterion": ("sgcore:Requirement", "sgcore:AcceptanceCriterion"),
        "nodeConnectedByEdge": ("sgcore:Node", "sgcore:Edge"),
        "edgeRelatesNode": ("sgcore:Edge", "sgcore:Node"),
        "decisionConstrainsSpec": ("sgcore:Decision", "sgcore:Spec"),
        "constraintAppliesToNode": ("sgcore:Constraint", "sgcore:Node"),
        "invariantGovernsSpecGraph": ("sgcore:Invariant", "sgcore:SpecGraph"),
        "codeSurfaceImplementsSpec": ("sgcore:CodeSurface", "sgcore:Spec"),
        "testValidatesRequirement": ("sgcore:Test", "sgcore:Requirement"),
        "releasePackagesCodeSurface": ("sgcore:Release", "sgcore:CodeSurface"),
        "evidenceSupportsCriterion": ("sgcore:Evidence", "sgcore:AcceptanceCriterion")
    ]

    func testSpecGraphCorePackagePassesCompilerCheck() throws {
        let result = try ontologyc(["check", packagePath])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        XCTAssertEqual(
            result.stdout.trimmingCharacters(in: .whitespacesAndNewlines),
            "ontologyc check: PASS \(packagePath)"
        )

        let packageText = try String(contentsOf: repoRoot.appendingPathComponent(packagePath))
        XCTAssertTrue(packageText.contains("approvalStatus: draft"), packageText)
    }

    func testSpecGraphCorePackageGeneratedOutputMatchesCommittedBaseline() throws {
        let output = try makeTemporaryDirectory(name: "ontologyc-specgraph-core-compile")
        let result = try ontologyc([
            "compile",
            packagePath,
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
            let expected = repoRoot.appendingPathComponent(generatedPath).appendingPathComponent(file)

            XCTAssertTrue(FileManager.default.fileExists(atPath: actual.path), "Missing \(file)")
            XCTAssertEqual(
                try Data(contentsOf: actual),
                try Data(contentsOf: expected),
                "\(file) drifted from committed SpecGraph Core baseline"
            )
        }
    }

    func testSpecGraphCoreNormalizedIRDefinesStableCoreVocabulary() throws {
        let irURL = repoRoot.appendingPathComponent(generatedPath).appendingPathComponent("ontology.normalized.json")
        let ir = try loadJSON(irURL)

        XCTAssertEqual(ir["id"] as? String, "org.0al.specgraph.core")
        XCTAssertEqual(ir["namespace"] as? String, "sgcore")
        XCTAssertEqual(ir["version"] as? String, "0.1.0")

        let classes = try XCTUnwrap(ir["classes"] as? [[String: Any]])
        XCTAssertEqual(Set(classes.compactMap { $0["id"] as? String }), expectedClasses)
        XCTAssertEqual(classes.first { $0["id"] as? String == "SpecGraph" }?["central"] as? Bool, true)

        let relations = try XCTUnwrap(ir["relations"] as? [[String: Any]])
        XCTAssertEqual(Set(relations.compactMap { $0["id"] as? String }), Set(expectedRelations.keys))
        for relation in relations {
            let id = try XCTUnwrap(relation["id"] as? String)
            let expected = try XCTUnwrap(expectedRelations[id])
            XCTAssertEqual(relation["domain"] as? String, expected.0, id)
            XCTAssertEqual(relation["range"] as? String, expected.1, id)
        }

        let policies = try XCTUnwrap(ir["policies"] as? [[String: Any]])
        XCTAssertEqual(policies.compactMap { $0["id"] as? String }, ["DraftAuthorityBoundary"])
        XCTAssertEqual(policies.first?["enforceability"] as? String, "manual")

        let stateMachines = try XCTUnwrap(ir["stateMachines"] as? [[String: Any]])
        XCTAssertEqual(stateMachines.compactMap { $0["id"] as? String }, ["SpecReviewState"])
        XCTAssertEqual(stateMachines.first?["states"] as? [String], ["draft", "reviewed"])
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func ontologyc(_ arguments: [String]) throws -> SpecGraphCoreCommandResult {
        let binary = repoRoot.appendingPathComponent(".build/debug/ontologyc")
        if !FileManager.default.fileExists(atPath: binary.path) {
            let build = try run("/usr/bin/env", ["swift", "build", "--product", "ontologyc"])
            XCTAssertEqual(build.status, 0, build.combinedOutput)
        }
        return try run(binary.path, arguments)
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> SpecGraphCoreCommandResult {
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

        return SpecGraphCoreCommandResult(
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

    private func loadJSON(_ url: URL) throws -> [String: Any] {
        let data = try Data(contentsOf: url)
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private struct SpecGraphCoreCommandResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        stdout + stderr
    }
}
