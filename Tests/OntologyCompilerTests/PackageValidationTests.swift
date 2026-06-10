import Foundation
import XCTest
@testable import OntologyCompiler

final class PackageValidationTests: XCTestCase {
    func testLoadedPackageStoresTypedMetadata() throws {
        let packageURL = try writePackage("""
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.metadata
          namespace: test
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          classes:
            Document:
              extends: sg:DomainEntity
              description: Document.
          relations:
            owner:
              domain: Document
              range: sg:DomainEntity
              description: Owner relation.
          policies:
            AllowDocument:
              extends: sg:Policy
              enforceability: runtime
              appliesTo:
                - Document
              text: Documents are allowed.
          stateMachines:
            DocumentState:
              states:
                - draft
                - approved
              transitions:
                - from: draft
                  to: approved
        """)

        let package = try XCTUnwrap(OntologyCompiler().load(path: packageURL.path))

        XCTAssertEqual(package.packageMetadata.id.rawValue, "test.metadata")
        XCTAssertEqual(package.packageMetadata.namespace.rawValue, "test")
        XCTAssertEqual(package.packageMetadata.version.rawValue, "0.1.0")
    }

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

        let diagnostics = OntologyCompiler().check(path: OntologySourcePath(url: packageURL))

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
        let diagnostics = compiler.check(path: OntologySourcePath(url: packageURL))

        XCTAssertFalse(compiler.hasErrors(diagnostics), "Imported protocol refs should remain resolvable: \(diagnostics)")
        XCTAssertTrue(
            diagnostics.contains { $0.code == "protocol.imported.emit_unsupported" && $0.severity == "warning" },
            "Expected imported protocol warning, got \(diagnostics)"
        )
    }

    func testClassFieldsValidateSupportedShape() throws {
        let packageURL = try writePackage("""
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.fields
          namespace: test
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          classes:
            Exam:
              extends: sg:DomainEntity
              description: Field-bearing exam.
              fields:
                title:
                  type: string
                  required: true
                durationMinutes:
                  type: integer
                  required: false
          relations:
            owner:
              domain: Exam
              range: sg:DomainEntity
              description: Owner relation.
          policies:
            AllowExam:
              extends: sg:Policy
              enforceability: runtime
              appliesTo:
                - Exam
              text: Exams are allowed.
          stateMachines:
            ExamState:
              states:
                - draft
                - approved
              transitions:
                - from: draft
                  to: approved
        """)

        let compiler = OntologyCompiler()
        let diagnostics = compiler.check(path: OntologySourcePath(url: packageURL))

        XCTAssertFalse(compiler.hasErrors(diagnostics), "Expected valid fields, got \(diagnostics)")
    }

    func testClassFieldsRejectInvalidShape() throws {
        let packageURL = try writePackage("""
        apiVersion: ontology.specgraph.io/v1alpha1
        kind: DomainOntologyPackage
        metadata:
          id: test.fields
          namespace: test
          version: 0.1.0
        spec:
          imports:
            - id: specgraph.foundation
              namespace: sg
              version: 0.1.0
          classes:
            Exam:
              extends: sg:DomainEntity
              description: Invalid field-bearing exam.
              fields:
                Invalid-Field:
                  type: date-time
                  required: "yes"
                id:
                  type: string
                  required: false
          relations:
            owner:
              domain: Exam
              range: sg:DomainEntity
              description: Owner relation.
          policies:
            AllowExam:
              extends: sg:Policy
              enforceability: runtime
              appliesTo:
                - Exam
              text: Exams are allowed.
          stateMachines:
            ExamState:
              states:
                - draft
                - approved
              transitions:
                - from: draft
                  to: approved
        """)

        let diagnostics = OntologyCompiler().check(path: OntologySourcePath(url: packageURL))

        XCTAssertTrue(diagnostics.contains { $0.code == "class.field.name.invalid" }, "\(diagnostics)")
        XCTAssertTrue(diagnostics.contains { $0.code == "class.field.name.reserved" }, "\(diagnostics)")
        XCTAssertTrue(diagnostics.contains { $0.code == "class.field.type.unsupported" }, "\(diagnostics)")
        XCTAssertTrue(diagnostics.contains { $0.code == "class.field.required.required.type" }, "\(diagnostics)")
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
