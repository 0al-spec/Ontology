import Foundation
import XCTest
@testable import OntologyCompiler

final class LocalRegistryTransportTests: XCTestCase {
    func testLocalRegistryPublishPullAndCompatCheckRoundTrip() throws {
        let registryRoot = try makeTemporaryDirectory(name: "ontology-local-registry")
        let pullOutput = try makeTemporaryDirectory(name: "ontology-local-registry-pull")
        let report = try makeTemporaryDirectory(name: "ontology-local-registry-compat")
            .appendingPathComponent("compatibility-report.yaml")
        let registry = try XCTUnwrap(RegistryBaseURL(url: registryRoot))
        let compiler = OntologyCompiler()

        let publish = try compiler.publishPackage(
            path: examcalcPackage,
            registry: registry,
            token: nil,
            channel: .candidate
        )

        XCTAssertEqual(publish.packageRef.rawValue, "edu.university.examcalc@0.1.0")
        let artifact = registryRoot
            .appendingPathComponent("ontologies", isDirectory: true)
            .appendingPathComponent("edu.university.examcalc", isDirectory: true)
            .appendingPathComponent("0.1.0", isDirectory: true)
            .appendingPathComponent("ontology.normalized.json")
        let entry = artifact.deletingLastPathComponent().appendingPathComponent("registry-entry.yaml")
        let channelEntry = registryRoot
            .appendingPathComponent("channels", isDirectory: true)
            .appendingPathComponent("candidate", isDirectory: true)
            .appendingPathComponent("edu.university.examcalc", isDirectory: true)
            .appendingPathComponent("0.1.0.yaml")

        XCTAssertEqual(try Data(contentsOf: artifact), try Data(contentsOf: examcalcGeneratedIR))
        XCTAssertTrue(try String(contentsOf: entry).contains("kind: OntologyRegistryEntry"))
        XCTAssertTrue(try String(contentsOf: channelEntry).contains("channel: candidate"))

        try compiler.pullPackage(
            ref: try XCTUnwrap(OntologyPackageReference(rawValue: "edu.university.examcalc@0.1.0")),
            registry: registry,
            token: nil,
            outDirectory: OntologyOutputDirectory(url: pullOutput)
        )

        let pulled = pullOutput.appendingPathComponent("edu-university-examcalc-0.1.0.normalized.json")
        XCTAssertEqual(try Data(contentsOf: pulled), try Data(contentsOf: artifact))

        let compatible = try compiler.compatCheckPackage(
            path: examcalcPackage,
            against: try XCTUnwrap(OntologyPackageReference(rawValue: "edu.university.examcalc@0.1.0")),
            registry: registry,
            token: nil,
            outPath: OntologyOutputPath(url: report)
        )

        XCTAssertTrue(compatible)
        XCTAssertTrue(try String(contentsOf: report).contains("compatible: true"))
    }

    func testTrustedLocalPublishRejectsBeforeWritingWithoutDecision() throws {
        let registryRoot = try makeTemporaryDirectory(name: "ontology-local-registry-governance")
        let registry = try XCTUnwrap(RegistryBaseURL(url: registryRoot))

        XCTAssertThrowsError(try OntologyCompiler().publishPackage(
            path: examcalcPackage,
            registry: registry,
            token: nil,
            channel: .trusted,
            governanceDecisionPath: nil
        )) { error in
            guard case OntologyCompilerError.packageError(let diagnostics) = error else {
                return XCTFail("Expected governance diagnostics, got \(error)")
            }
            XCTAssertTrue(diagnostics.contains { $0.code == "registry.publish.governanceDecision.required" })
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: registryRoot.appendingPathComponent("ontologies").path))
    }

    private var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private var examcalcPackage: OntologySourcePath {
        OntologySourcePath(url: repoRoot.appendingPathComponent(
            "SPECS/ontology/packages/examcalc/domain-ontology-package.yaml"
        ))
    }

    private var examcalcGeneratedIR: URL {
        repoRoot.appendingPathComponent("SPECS/ontology/packages/examcalc/generated/ontology.normalized.json")
    }

    private func makeTemporaryDirectory(name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
