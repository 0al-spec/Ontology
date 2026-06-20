import Foundation
import XCTest
@testable import OntologyCompiler

final class OntologyLayerPackageValidationTests: XCTestCase {
    func testOntologyLayersValidateAndNormalize() throws {
        let packageURL = try writePackage(layeredPackageYAML)
        let compiler = OntologyCompiler()
        let diagnostics = compiler.check(path: OntologySourcePath(url: packageURL))
        XCTAssertFalse(compiler.hasErrors(diagnostics), "Expected valid layers, got \(diagnostics)")

        let package = try XCTUnwrap(compiler.load(path: packageURL.path))
        let ir = compiler.normalize(package)
        let classes = try XCTUnwrap(ir["classes"] as? [[String: Any]])
        let protocols = try XCTUnwrap(ir["protocols"] as? [[String: Any]])
        let relations = try XCTUnwrap(ir["relations"] as? [[String: Any]])
        let policies = try XCTUnwrap(ir["policies"] as? [[String: Any]])
        let stateMachines = try XCTUnwrap(ir["stateMachines"] as? [[String: Any]])

        XCTAssertEqual(classes.first { $0["id"] as? String == "ProductGoal" }?["layer"] as? String, "objective")
        XCTAssertEqual(classes.first { $0["id"] as? String == "DeterministicRule" }?["layer"] as? String, "mechanics")
        XCTAssertEqual(classes.first { $0["id"] as? String == "OfflineConstraint" }?["layer"] as? String, "execution")
        XCTAssertEqual(classes.first { $0["id"] as? String == "OntologyDelta" }?["layer"] as? String, "meta")
        XCTAssertEqual(classes.first { $0["id"] as? String == "AdaptiveActor" }?["layer"] as? String, "multi_agent")
        XCTAssertEqual(protocols.first?["layer"] as? String, "mechanics")
        XCTAssertEqual(relations.first?["layer"] as? String, "objective")
        XCTAssertEqual(policies.first?["layer"] as? String, "execution")
        XCTAssertEqual(stateMachines.first?["layer"] as? String, "meta")
    }

    func testOntologyLayersRejectUnknownValues() throws {
        let packageURL = try writePackage(layeredPackageYAML.replacingOccurrences(of: "layer: objective", with: "layer: strategic"))
        let diagnostics = OntologyCompiler().check(path: OntologySourcePath(url: packageURL))

        XCTAssertTrue(diagnostics.contains { $0.code == "ontology.layer.invalid" }, "\(diagnostics)")
    }

    private var layeredPackageYAML: String {
        """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.layers
          namespace: layers
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          protocols:
            Auditable:
              layer: mechanics
              description: Requires audit semantics.
          classes:
            ProductGoal:
              layer: objective
              extends: sg:DomainEntity
              description: Product goal.
            DeterministicRule:
              layer: mechanics
              extends: sg:DomainEntity
              description: Deterministic rule.
            OfflineConstraint:
              layer: execution
              extends: sg:DomainEntity
              description: Offline execution constraint.
            OntologyDelta:
              layer: meta
              extends: sg:DomainEntity
              description: Ontology delta.
            AdaptiveActor:
              layer: multi_agent
              extends: sg:DomainEntity
              description: Adaptive actor.
          relations:
            supportsGoal:
              layer: objective
              domain: DeterministicRule
              range: ProductGoal
              description: Rule supports goal.
          policies:
            OfflineReviewPolicy:
              layer: execution
              extends: sg:Policy
              enforceability: manual
              appliesTo:
                - OfflineConstraint
              text: Offline constraints require review.
          stateMachines:
            OntologyDeltaState:
              layer: meta
              states:
                - draft
                - reviewed
              transitions:
                - from: draft
                  to: reviewed
        """
    }

    private func writePackage(_ text: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ontology-layer-package-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("package.yaml")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
