import Foundation
import XCTest

final class OptionalPackageSectionsTests: XCTestCase {
    func testOmittedEmptyAndMixedSectionsCompileWithStableSDKSurfaces() throws {
        for sections in ["", "  policies: {}", "  stateMachines: {}", "  policies: {}\n  stateMachines: {}"] {
            let output = try compile(basePackage + "\n" + sections)
            let ir = try normalizedIR(in: output)
            for key in ["policies", "stateMachines"] {
                XCTAssertEqual(try XCTUnwrap(ir[key] as? [Any]).count, 0)
            }
            for file in [
                "ontology.normalized.json", "refs.ts", "types.ts", "relations.ts", "policies.ts",
                "state-machines.ts", "protocols.ts", "schemas.ts", "registry.ts", "validators.ts"
            ] {
                XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent(file).path), file)
            }
            XCTAssertEqual(try XCTUnwrap(exportedJSON("policies", file: "refs.ts", in: output) as? [String: Any]).count, 0)
            XCTAssertEqual(try XCTUnwrap(exportedJSON("stateMachines", file: "refs.ts", in: output) as? [String: Any]).count, 0)
            XCTAssertEqual(try XCTUnwrap(exportedJSON("policyDefinitions", file: "policies.ts", in: output) as? [Any]).count, 0)
            XCTAssertEqual(try XCTUnwrap(exportedJSON("stateMachineDefinitions", file: "state-machines.ts", in: output) as? [Any]).count, 0)
            let registry = try String(contentsOf: output.appendingPathComponent("registry.ts"), encoding: .utf8)
            XCTAssertTrue(registry.contains("policies: policyDefinitions"), registry)
            XCTAssertTrue(registry.contains("stateMachines: stateMachineDefinitions"), registry)
        }
    }

    func testEachOptionalSectionCanBePopulatedIndependently() throws {
        for (section, populatedKey, emptyKey) in [
            (validPolicy, "policies", "stateMachines"),
            (validMachine, "stateMachines", "policies")
        ] {
            let output = try compile(basePackage + "\n" + section)
            let ir = try normalizedIR(in: output)
            XCTAssertEqual(try XCTUnwrap(ir[populatedKey] as? [Any]).count, 1)
            XCTAssertEqual(try XCTUnwrap(ir[emptyKey] as? [Any]).count, 0)
        }
    }

    func testMalformedPresentSectionsAreRejected() throws {
        for key in ["policies", "stateMachines"] {
            for value in ["null", "[]", "[draft]", "draft", "7", "true"] {
                try assertRejected(basePackage + "\n  \(key): \(value)", code: "spec.required.type", path: "spec.\(key)")
            }
        }
    }

    func testLifecycleCannotReferenceAnAbsentMachine() throws {
        let bound = try basePackage.replacingOccurrences(of: "description: A local test declaration.", with: "description: A local test declaration.\n      lifecycle: Draft")
        for section in ["", "\n  stateMachines: {}"] {
            try assertRejected(bound + section, code: "class.lifecycle.unresolved", path: "spec.classes.Scenario.lifecycle")
        }
        _ = try compile(bound + "\n" + validMachine)
    }

    func testSuppliedPoliciesRetainValidation() throws {
        let package = try basePackage + "\n" + validPolicy
        try assertRejected(package.replacingOccurrences(of: "enforceability: manual", with: "enforceability: automatic"), code: "policy.enforceability.invalid")
        try assertRejected(package.replacingOccurrences(of: "appliesTo: [Scenario]", with: "appliesTo: [Missing]"), code: "policy.appliesTo.unresolved")
        try assertRejected(basePackage + "\n  policies:\n    Review: {}", code: "policy.extends.required")
    }

    func testSuppliedStateMachinesRetainValidation() throws {
        let package = try basePackage + "\n" + validMachine
        try assertRejected(package.replacingOccurrences(of: "states: [draft]", with: "states: []"), code: "state.states.empty")
        try assertRejected(package.replacingOccurrences(of: "transitions: [{from: draft, to: draft}]", with: "transitions: []"), code: "state.transitions.empty")
        try assertRejected(package.replacingOccurrences(of: "to: draft", with: "to: missing"), code: "state.transition.invalid_state")
        try assertRejected(basePackage + "\n  stateMachines:\n    Draft: {}", code: "state.states.required")
    }

    func testLocalRelationReferencesRemainValidated() throws {
        try assertRejected(basePackage.replacingOccurrences(of: "domain: Scenario", with: "domain: Missing"), code: "relation.domain.unresolved")
        try assertRejected(basePackage.replacingOccurrences(of: "range: CheckResult", with: "range: Missing"), code: "relation.range.unresolved")
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }

    private var basePackage: String {
        get throws {
            try String(contentsOf: repoRoot.appendingPathComponent("SPECS/ontology/fixtures/valid/local-model-omitted-sections.yaml"), encoding: .utf8)
        }
    }

    private var validPolicy: String {
        """
          policies:
            Review:
              extends: sg:Policy
              enforceability: manual
              appliesTo: [Scenario]
              text: Review this declaration.
        """
    }

    private var validMachine: String {
        """
          stateMachines:
            Draft:
              states: [draft]
              transitions: [{from: draft, to: draft}]
        """
    }

    private func compile(_ source: String) throws -> URL {
        let directory = try temporaryDirectory()
        let package = directory.appendingPathComponent("package.yaml")
        try source.write(to: package, atomically: true, encoding: .utf8)
        let output = directory.appendingPathComponent("generated")
        let result = try run(["compile", package.path, "--target", "typescript", "--out", output.path])
        XCTAssertEqual(result.status, 0, result.text)
        return output
    }

    private func assertRejected(_ source: String, code: String, path: String? = nil) throws {
        let directory = try temporaryDirectory()
        let package = directory.appendingPathComponent("package.yaml")
        try source.write(to: package, atomically: true, encoding: .utf8)
        let output = directory.appendingPathComponent("generated")
        let result = try run(["compile", package.path, "--target", "typescript", "--out", output.path])
        XCTAssertEqual(result.status, 1, result.text)
        XCTAssertTrue(result.text.contains(code), result.text)
        if let path { XCTAssertTrue(result.text.contains(path), result.text) }
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.path), result.text)
    }

    private func normalizedIR(in output: URL) throws -> [String: Any] {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: output.appendingPathComponent("ontology.normalized.json"))) as? [String: Any])
    }

    private func exportedJSON(_ name: String, file: String, in output: URL) throws -> Any {
        let text = try String(contentsOf: output.appendingPathComponent(file), encoding: .utf8)
        let start = try XCTUnwrap(text.range(of: "export const \(name) = "))
        let end = try XCTUnwrap(text.range(of: " as const;", range: start.upperBound ..< text.endIndex))
        return try JSONSerialization.jsonObject(with: Data(text[start.upperBound ..< end.lowerBound].utf8))
    }

    private func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("optional-package-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: directory) }
        return directory
    }

    private func run(_ arguments: [String]) throws -> (status: Int32, text: String) {
        let process = Process()
        process.executableURL = try ontologycTestBinary(in: repoRoot)
        process.arguments = arguments
        process.currentDirectoryURL = repoRoot
        let output = Pipe()
        process.standardOutput = output
        process.standardError = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, String(decoding: data, as: UTF8.self))
    }
}
