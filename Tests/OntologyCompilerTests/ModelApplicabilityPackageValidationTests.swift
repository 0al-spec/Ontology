import Foundation
import XCTest
@testable import OntologyCompiler

final class ModelApplicabilityPackageValidationTests: XCTestCase {
    func testModelApplicabilityValidatesAndNormalizes() throws {
        let packageURL = try writePackage(modelApplicabilityPackageYAML)
        let compiler = OntologyCompiler()
        let diagnostics = compiler.check(path: OntologySourcePath(url: packageURL))

        XCTAssertFalse(compiler.hasErrors(diagnostics), "Expected valid model applicability, got \(diagnostics)")

        let package = try XCTUnwrap(compiler.load(path: packageURL.path))
        let ir = compiler.normalize(package)
        let profile = try XCTUnwrap(ir["modelApplicability"] as? [String: Any])
        let appliesTo = try XCTUnwrap(profile["appliesTo"] as? [String: Any])
        let assumptions = try XCTUnwrap(profile["assumptions"] as? [[String: Any]])
        let triggers = try XCTUnwrap(profile["invalidationTriggers"] as? [[String: Any]])

        XCTAssertEqual(appliesTo["domains"] as? [String], ["specgraph_core"])
        XCTAssertEqual(appliesTo["agentTypes"] as? [String], ["SpecAuthorAgent"])
        XCTAssertEqual(assumptions.first?["id"] as? String, "human_review_required")
        XCTAssertEqual(assumptions.first?["layer"] as? String, "execution")
        XCTAssertEqual(triggers.first?["id"] as? String, "package_layer_contract_changed")
        XCTAssertEqual(triggers.first?["layer"] as? String, "meta")
    }

    func testModelApplicabilityRejectsInvalidShapeAndLayer() throws {
        let packageURL = try writePackage(modelApplicabilityPackageYAML
            .replacingOccurrences(of: "domains:\n        - specgraph_core", with: "domains: specgraph_core")
            .replacingOccurrences(of: "layer: execution", with: "layer: strategic"))
        let diagnostics = OntologyCompiler().check(path: OntologySourcePath(url: packageURL))

        XCTAssertTrue(diagnostics.contains { $0.code == "modelApplicability.scope.array" }, "\(diagnostics)")
        XCTAssertTrue(diagnostics.contains { $0.code == "ontology.layer.invalid" }, "\(diagnostics)")
    }

    private var modelApplicabilityPackageYAML: String {
        """
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.applicability
          namespace: applicability
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          modelApplicability:
            appliesTo:
              domains:
                - specgraph_core
              lifecyclePhases:
                - draft_spec_authoring
              agentTypes:
                - SpecAuthorAgent
            excludes:
              domains:
                - unrelated_product_domain
            assumptions:
              - id: human_review_required
                layer: execution
                text: Generated ontology changes require owner review before acceptance.
            invalidationTriggers:
              - id: package_layer_contract_changed
                layer: meta
                text: Re-review applicability when the layer vocabulary changes.
          classes:
            Spec:
              layer: objective
              extends: sg:DomainEntity
              description: Specification artifact.
          relations:
            definesRequirement:
              layer: mechanics
              domain: Spec
              range: sg:DomainEntity
              description: Spec defines a requirement.
          policies:
            ReviewPolicy:
              layer: execution
              extends: sg:Policy
              enforceability: manual
              appliesTo:
                - Spec
              text: Specs require review.
          stateMachines:
            SpecState:
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
            .appendingPathComponent("model-applicability-package-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("package.yaml")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
