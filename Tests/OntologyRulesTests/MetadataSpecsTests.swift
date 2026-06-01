import OntologyRules
import XCTest

final class MetadataSpecsTests: XCTestCase {
    func testMetadataPatternSpecs() {
        XCTAssertTrue(OntologyIdPatternSpec().isSatisfiedBy("org.0al.examcalc"))
        XCTAssertFalse(OntologyIdPatternSpec().isSatisfiedBy("ExamCalc"))

        XCTAssertTrue(OntologyNamespacePatternSpec().isSatisfiedBy("examcalc"))
        XCTAssertFalse(OntologyNamespacePatternSpec().isSatisfiedBy("exam_calc"))

        XCTAssertTrue(OntologySemVerPatternSpec().isSatisfiedBy("1.0.0"))
        XCTAssertTrue(OntologySemVerPatternSpec().isSatisfiedBy("1.0.0-beta"))
        XCTAssertFalse(OntologySemVerPatternSpec().isSatisfiedBy("1"))
    }

    func testSymbolAndReferencePatternSpecs() {
        XCTAssertTrue(OntologySymbolNameSpec().isSatisfiedBy("ExamModeSession"))
        XCTAssertFalse(OntologySymbolNameSpec().isSatisfiedBy("exam-mode"))

        XCTAssertTrue(OntologyStateNameSpec().isSatisfiedBy("pending_device_verification"))
        XCTAssertFalse(OntologyStateNameSpec().isSatisfiedBy("Pending"))

        XCTAssertTrue(OntologyConceptRefPatternSpec().isSatisfiedBy("Exam"))
        XCTAssertTrue(OntologyConceptRefPatternSpec().isSatisfiedBy("foundation:Policy"))
        XCTAssertFalse(OntologyConceptRefPatternSpec().isSatisfiedBy("bad-ref"))
    }

    func testPackageShapeSpecs() {
        XCTAssertTrue(ExpectedOntologyApiVersionSpec().isSatisfiedBy("ontology.specgraph.io/v1alpha1"))
        XCTAssertFalse(ExpectedOntologyApiVersionSpec().isSatisfiedBy("v1"))

        XCTAssertTrue(ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy("DomainOntologyPackage"))
        XCTAssertFalse(ExpectedDomainOntologyPackageKindSpec().isSatisfiedBy("Other"))
    }
}
