import Foundation
import XCTest
import Yams

// swiftlint:disable function_body_length type_body_length

final class HypercodeOntologyPackageImportTests: XCTestCase {
    func testV2PackageRootWithoutOntologySectionsUsesGenericDraft() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2-generic-package")
        let input = directory.appendingPathComponent("generic-package.ir.json")
        let output = directory.appendingPathComponent("generic-package.yaml")
        try """
        {
          "version": "hypercode.ir/v2",
          "nodes": [
            {
              "type": "Package",
              "properties": {},
              "children": [
                {
                  "type": "Feature",
                  "properties": {},
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
            "org.0al.hypercode.generic",
            "--namespace",
            "generic",
            "--version",
            "0.1.0"
        ])

        XCTAssertEqual(result.status, 0, result.combinedOutput)
        let check = try ontologyc(["check", output.path])
        XCTAssertEqual(check.status, 0, check.combinedOutput)

        let draft = try XCTUnwrap(Yams.load(yaml: String(contentsOf: output)) as? [String: Any])
        let spec = try XCTUnwrap(draft["spec"] as? [String: Any])
        let classes = try XCTUnwrap(spec["classes"] as? [String: Any])
        XCTAssertNotNil(classes["Package"])
        XCTAssertNotNil(classes["Feature"])
    }

    func testV2DefaultsOptionalMetadataAndImportNamespace() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2-optional")
        let input = directory.appendingPathComponent("optional.ir.json")
        let output = directory.appendingPathComponent("optional.yaml")
        try minimalV2OntologyPackageIR(
            publisher: nil,
            source: nil,
            importNamespace: nil
        ).write(to: input, atomically: true, encoding: .utf8)

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

        let draft = try XCTUnwrap(Yams.load(yaml: String(contentsOf: output)) as? [String: Any])
        let metadata = try XCTUnwrap(draft["metadata"] as? [String: Any])
        XCTAssertEqual(metadata["publisher"] as? String, "ontologyc import-hypercode")
        XCTAssertEqual(metadata["source"] as? String, input.path)

        let spec = try XCTUnwrap(draft["spec"] as? [String: Any])
        let imports = try XCTUnwrap(spec["imports"] as? [[String: Any]])
        XCTAssertEqual(imports.first?["id"] as? String, "specgraph.foundation")
        XCTAssertNil(imports.first?["namespace"])
    }

    func testV2RejectsEmptyRequiredSectionsBeforeWriting() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2-empty-section")
        let input = directory.appendingPathComponent("empty-section.ir.json")
        let output = directory.appendingPathComponent("empty-section.yaml")
        try minimalV2OntologyPackageIR(importsChildren: "")
            .write(to: input, atomically: true, encoding: .utf8)

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
            result.stderr.contains("Imports must contain at least one Import"),
            result.stderr
        )
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
    }

    func testV2RejectsEmptyCommaListEntries() throws {
        let directory = try makeTemporaryDirectory(name: "ontologyc-import-hypercode-v2-empty-csv")
        let input = directory.appendingPathComponent("empty-csv.ir.json")
        let output = directory.appendingPathComponent("empty-csv.yaml")
        try minimalV2OntologyPackageIR(relationRange: "StartService,")
            .write(to: input, atomically: true, encoding: .utf8)

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
            result.stderr.contains("Relation#controls.range must not be empty"),
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

    private func ontologyc(_ arguments: [String]) throws -> OntologyCommandResult {
        let binary = repoRoot.appendingPathComponent(".build/debug/ontologyc")
        if !FileManager.default.fileExists(atPath: binary.path) {
            let build = try run("/usr/bin/env", ["swift", "build", "--product", "ontologyc"])
            XCTAssertEqual(build.status, 0, build.combinedOutput)
        }
        return try run(binary.path, arguments)
    }

    private func run(_ executable: String, _ arguments: [String]) throws -> OntologyCommandResult {
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

        return OntologyCommandResult(
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

    private func minimalV2OntologyPackageIR(
        publisher: String? = "ontologyc import-hypercode test",
        source: String? = "Tests/fixtures/service.ir.json",
        importNamespace: String? = "sg",
        importsChildren: String? = nil,
        relationRange: String = "StartService"
    ) -> String {
        var metadataProperties = [
            jsonProperty("package_id", "org.0al.hypercode.service"),
            jsonProperty("namespace", "hypercodeservice"),
            jsonProperty("version", "0.1.0"),
            jsonProperty("approval_status", "draft")
        ]
        if let publisher {
            metadataProperties.append(jsonProperty("publisher", publisher))
        }
        if let source {
            metadataProperties.append(jsonProperty("source", source))
        }

        let importProperties = [
            jsonProperty("import_id", "specgraph.foundation"),
            importNamespace.map { jsonProperty("namespace", $0) },
            jsonProperty("version", "0.1.0")
        ].compactMap { $0 }.joined(separator: ",\n")

        let importChildren = importsChildren ?? """
                    {
                      "type": "Import",
                      "id": "foundation",
                      "properties": {
        \(importProperties)
                      },
                      "children": []
                    }
        """

        return """
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
        \(metadataProperties.joined(separator: ",\n"))
                  },
                  "children": []
                },
                {
                  "type": "Imports",
                  "properties": {},
                  "children": [
        \(importChildren)
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
        \(jsonProperty("extends", "sg:DomainEntity")),
        \(jsonProperty("description", "Service root."))
                      },
                      "children": []
                    },
                    {
                      "type": "Class",
                      "id": "StartService",
                      "properties": {
        \(jsonProperty("extends", "sg:Command")),
        \(jsonProperty("description", "Start service."))
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
        \(jsonProperty("domain", "Service")),
        \(jsonProperty("range", relationRange)),
                        "card_min": { "value": 0 },
        \(jsonProperty("card_max", "*"))
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
        \(jsonProperty("extends", "sg:Policy")),
        \(jsonProperty("enforceability", "manual")),
        \(jsonProperty("applies_to", "Service")),
        \(jsonProperty("text", "Generated service imports require review."))
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
        \(jsonProperty("states", "draft, reviewed"))
                      },
                      "children": [
                        {
                          "type": "Transition",
                          "id": "review",
                          "properties": {
        \(jsonProperty("from", "draft")),
        \(jsonProperty("to", "reviewed")),
        \(jsonProperty("command", "StartService"))
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
        \(jsonProperty("patch_allowed", "add description")),
        \(jsonProperty("minor_allowed", "add class, add relation")),
        \(jsonProperty("major_requires", "remove class"))
                  },
                  "children": []
                }
              ]
            }
          ]
        }
        """
    }

    private func jsonProperty(_ key: String, _ value: String) -> String {
        "                    \"\(key)\": { \"value\": \"\(value)\" }"
    }
}

private struct OntologyCommandResult {
    let status: Int32
    let stdout: String
    let stderr: String

    var combinedOutput: String {
        stdout + stderr
    }
}
