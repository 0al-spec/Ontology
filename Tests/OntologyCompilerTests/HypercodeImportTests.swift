import Foundation
import XCTest
import Yams

// swiftlint:disable function_body_length type_body_length

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

    func testImportHypercodeV2OntologyPackageMapsResolvedProperties() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2")
        let input = directory.appendingPathComponent("service.ir.json")
        let output = directory.appendingPathComponent("service-domain-ontology.yaml")
        try """
        {
          "version": "hypercode.ir/v2",
          "nodes": [
            {
              "type": "Package",
              "id": "service",
              "properties": {},
              "children": [
                {
                  "type": "Metadata",
                  "properties": {
                    "package_id": { "value": "org.0al.hypercode.service" },
                    "namespace": { "value": "hypercodeservice" },
                    "version": { "value": "0.1.0" },
                    "publisher": { "value": "ontologyc import-hypercode test" },
                    "source": { "value": "Tests/fixtures/service.ir.json" },
                    "approval_status": { "value": "draft" }
                  },
                  "children": []
                },
                {
                  "type": "Imports",
                  "properties": {},
                  "children": [
                    {
                      "type": "Import",
                      "id": "foundation",
                      "properties": {
                        "import_id": { "value": "specgraph.foundation" },
                        "namespace": { "value": "sg" },
                        "version": { "value": "0.1.0" }
                      },
                      "children": []
                    }
                  ]
                },
                {
                  "type": "Classes",
                  "properties": {},
                  "children": [
                    {
                      "type": "Class",
                      "id": "Service",
                      "properties": {
                        "extends": { "value": "sg:DomainEntity" },
                        "description": { "value": "Service root." },
                        "central": { "value": true }
                      },
                      "children": [
                        {
                          "type": "Field",
                          "id": "endpoint",
                          "properties": {
                            "type": { "value": "string" },
                            "required": { "value": true },
                            "description": { "value": "Public endpoint." }
                          },
                          "children": []
                        }
                      ]
                    },
                    {
                      "type": "Class",
                      "id": "StartService",
                      "properties": {
                        "extends": { "value": "sg:Command" },
                        "description": { "value": "Start service." }
                      },
                      "children": []
                    }
                  ]
                },
                {
                  "type": "Relations",
                  "properties": {},
                  "children": [
                    {
                      "type": "Relation",
                      "id": "controls",
                      "properties": {
                        "domain": { "value": "Service" },
                        "range": { "value": "StartService" },
                        "card_min": { "value": 0 },
                        "card_max": { "value": "*" },
                        "description": { "value": "Service command relation." }
                      },
                      "children": []
                    }
                  ]
                },
                {
                  "type": "Policies",
                  "properties": {},
                  "children": [
                    {
                      "type": "Policy",
                      "id": "GeneratedDraftRequiresReview",
                      "properties": {
                        "extends": { "value": "sg:Policy" },
                        "enforceability": { "value": "manual" },
                        "applies_to": { "value": "Service" },
                        "text": { "value": "Generated service imports require review." }
                      },
                      "children": []
                    }
                  ]
                },
                {
                  "type": "StateMachines",
                  "properties": {},
                  "children": [
                    {
                      "type": "Machine",
                      "id": "ServiceLifecycle",
                      "properties": {
                        "states": { "value": "draft, reviewed" }
                      },
                      "children": [
                        {
                          "type": "Transition",
                          "id": "review",
                          "properties": {
                            "from": { "value": "draft" },
                            "to": { "value": "reviewed" },
                            "command": { "value": "StartService" }
                          },
                          "children": []
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "Compatibility",
                  "properties": {
                    "patch_allowed": { "value": "add description" },
                    "minor_allowed": { "value": "add class, add relation" },
                    "major_requires": { "value": "remove class" }
                  },
                  "children": []
                }
              ]
            }
          ]
        }
        """.write(to: input, atomically: true, encoding: .utf8)

        let result = try ontologyc([
            "import-hypercode",
            input.path,
            "--out",
            output.path,
            "--id",
            "ignored.by.v2.metadata",
            "--namespace",
            "ignored",
            "--version",
            "9.9.9"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        let check = try ontologyc(["check", output.path])
        XCTAssertEqual(check.status, 0, check.combinedOutput)

        let draft = try XCTUnwrap(Yams.load(yaml: String(contentsOf: output)) as? [String: Any])
        let metadata = try XCTUnwrap(draft["metadata"] as? [String: Any])
        XCTAssertEqual(metadata["id"] as? String, "org.0al.hypercode.service")

        let spec = try XCTUnwrap(draft["spec"] as? [String: Any])
        let classes = try XCTUnwrap(spec["classes"] as? [String: Any])
        let service = try XCTUnwrap(classes["Service"] as? [String: Any])
        XCTAssertEqual(service["central"] as? Bool, true)
        XCTAssertNotNil(service["fields"] as? [String: Any])

        let relations = try XCTUnwrap(spec["relations"] as? [String: Any])
        let controls = try XCTUnwrap(relations["controls"] as? [String: Any])
        let cardinality = try XCTUnwrap(controls["cardinality"] as? [String: Any])
        XCTAssertEqual(cardinality["min"] as? Int, 0)
        XCTAssertEqual(cardinality["max"] as? String, "*")
    }

    func testImportHypercodeV2RequiresDraftApprovalStatus() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2-approved")
        let input = directory.appendingPathComponent("approved.ir.json")
        let output = directory.appendingPathComponent("approved.yaml")
        try """
        {
          "version": "hypercode.ir/v2",
          "nodes": [
            {
              "type": "Package",
              "id": "service",
              "properties": {},
              "children": [
                {
                  "type": "Metadata",
                  "properties": {
                    "package_id": { "value": "org.0al.hypercode.service" },
                    "namespace": { "value": "hypercodeservice" },
                    "version": { "value": "0.1.0" },
                    "publisher": { "value": "ontologyc import-hypercode test" },
                    "source": { "value": "Tests/fixtures/service.ir.json" },
                    "approval_status": { "value": "approved" }
                  },
                  "children": []
                },
                { "type": "Imports", "properties": {}, "children": [] },
                { "type": "Classes", "properties": {}, "children": [] },
                { "type": "Relations", "properties": {}, "children": [] },
                { "type": "Policies", "properties": {}, "children": [] },
                { "type": "StateMachines", "properties": {}, "children": [] },
                { "type": "Compatibility", "properties": {}, "children": [] }
              ]
            }
          ]
        }
        """.write(to: input, atomically: true, encoding: .utf8)

        let result = try ontologyc([
            "import-hypercode",
            input.path,
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
        XCTAssertTrue(
            result.stderr.contains("Metadata.approval_status must be draft"),
            result.stderr
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
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
        XCTAssertTrue(
            result.stderr.contains("Expected Hypercode IR version hypercode.ir/v1 or hypercode.ir/v2"),
            result.stderr
        )
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
