import Foundation
import XCTest
@testable import OntologyCompiler

final class PackageValidationTests: XCTestCase {
    func testProtocolRequiredFieldsMustBeClassRelationDomains() throws {
        let packageURL = try writePackage("""
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.protocols
          namespace: test
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          protocols:
            Signable:
              description: Requires a signature field.
              requiredFields:
                - signature
          classes:
            SignedDocument:
              extends: sg:DomainEntity
              implements:
                - Signable
              description: Document that claims protocol conformance.
          relations:
            owner:
              domain: SignedDocument
              range: sg:DomainEntity
              description: Owner relation.
          policies:
            AllowSignedDocument:
              extends: sg:Policy
              enforceability: runtime
              appliesTo:
                - SignedDocument
              text: Signed documents are allowed.
          stateMachines:
            DocumentState:
              states:
                - draft
                - signed
              transitions:
                - from: draft
                  to: signed
        """)

        let diagnostics = OntologyCompiler().check(path: packageURL.path)

        XCTAssertTrue(
            diagnostics.contains { $0.code == "protocol.field.missing" },
            "Expected missing required field diagnostic, got \(diagnostics)"
        )
    }

    func testImportedProtocolRefsProduceWarningNotError() throws {
        let packageURL = try writePackage("""
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.protocols
          namespace: test
          version: 0.1.0
        spec:
          imports:
            - id: external.protocols
              namespace: external
              version: 1.0.0
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          classes:
            SignedDocument:
              extends: sg:DomainEntity
              implements:
                - external:Signable
              description: Document that implements an imported protocol.
          relations:
            owner:
              domain: SignedDocument
              range: sg:DomainEntity
              description: Owner relation.
          policies:
            AllowSignedDocument:
              extends: sg:Policy
              enforceability: runtime
              appliesTo:
                - SignedDocument
              text: Signed documents are allowed.
          stateMachines:
            DocumentState:
              states:
                - draft
                - signed
              transitions:
                - from: draft
                  to: signed
        """)

        let compiler = OntologyCompiler()
        let diagnostics = compiler.check(path: packageURL.path)

        XCTAssertFalse(compiler.hasErrors(diagnostics), "Imported protocol refs should remain resolvable: \(diagnostics)")
        XCTAssertTrue(
            diagnostics.contains { $0.code == "protocol.imported.emit_unsupported" && $0.severity == "warning" },
            "Expected imported protocol warning, got \(diagnostics)"
        )
    }

    private func writePackage(_ text: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ontology-package-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("package.yaml")
        try text.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
