import OntologyRules
import XCTest

final class MetadataSpecsTests: XCTestCase {
    func testMetadataPatternSpecs() {
        XCTAssertTrue(OntologyIdPatternSpec().isSatisfiedBy(OntologyPackageId(rawValue: "org.0al.examcalc")))
        XCTAssertFalse(OntologyIdPatternSpec().isSatisfiedBy(OntologyPackageId(rawValue: "ExamCalc")))

        XCTAssertTrue(OntologyNamespacePatternSpec().isSatisfiedBy(OntologyNamespace(rawValue: "examcalc")))
        XCTAssertFalse(OntologyNamespacePatternSpec().isSatisfiedBy(OntologyNamespace(rawValue: "exam_calc")))

        XCTAssertTrue(OntologySemVerPatternSpec().isSatisfiedBy(OntologySemanticVersion(rawValue: "1.0.0")))
        XCTAssertTrue(OntologySemVerPatternSpec().isSatisfiedBy(OntologySemanticVersion(rawValue: "1.0.0-beta")))
        XCTAssertFalse(OntologySemVerPatternSpec().isSatisfiedBy(OntologySemanticVersion(rawValue: "1")))
    }

    func testSymbolAndReferencePatternSpecs() {
        XCTAssertTrue(OntologySymbolNameSpec().isSatisfiedBy(OntologySymbolName(rawValue: "ExamModeSession")))
        XCTAssertFalse(OntologySymbolNameSpec().isSatisfiedBy(OntologySymbolName(rawValue: "exam-mode")))

        XCTAssertTrue(OntologyStateNameSpec().isSatisfiedBy(OntologyStateName(rawValue: "pending_device_verification")))
        XCTAssertFalse(OntologyStateNameSpec().isSatisfiedBy(OntologyStateName(rawValue: "Pending")))

        XCTAssertTrue(OntologyConceptRefPatternSpec().isSatisfiedBy(OntologyConceptReferenceLiteral(rawValue: "Exam")))
        XCTAssertTrue(OntologyConceptRefPatternSpec().isSatisfiedBy(OntologyConceptReferenceLiteral(rawValue: "foundation:Policy")))
        XCTAssertFalse(OntologyConceptRefPatternSpec().isSatisfiedBy(OntologyConceptReferenceLiteral(rawValue: "bad-ref")))
    }

    func testFieldNameAndTypeSpecs() {
        XCTAssertTrue(OntologyFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "durationMinutes")))
        XCTAssertTrue(OntologyFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "duration_minutes")))
        XCTAssertFalse(OntologyFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "DurationMinutes")))
        XCTAssertFalse(OntologyFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "duration-minutes")))
        XCTAssertTrue(ReservedOntologyClassFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "id")))
        XCTAssertFalse(ReservedOntologyClassFieldNameSpec().isSatisfiedBy(OntologyFieldName(rawValue: "title")))

        XCTAssertTrue(OntologyFieldTypeSpec().isSatisfiedBy(OntologyFieldType(rawValue: "string")))
        XCTAssertTrue(OntologyFieldTypeSpec().isSatisfiedBy(OntologyFieldType(rawValue: "integer")))
        XCTAssertFalse(OntologyFieldTypeSpec().isSatisfiedBy(OntologyFieldType(rawValue: "date-time")))
    }

    func testPackageShapeSpecs() {
        XCTAssertTrue(ExpectedOntologyApiVersionSpec().isSatisfiedBy(OntologyApiVersion(rawValue: "ontology.specgraph.io/v1alpha1")))
        XCTAssertFalse(ExpectedOntologyApiVersionSpec().isSatisfiedBy(OntologyApiVersion(rawValue: "v1")))

        XCTAssertTrue(ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy(OntologyPackageKind(rawValue: "DomainOntologyPackage")))
        XCTAssertFalse(ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy(OntologyPackageKind(rawValue: "Other")))
    }
}
