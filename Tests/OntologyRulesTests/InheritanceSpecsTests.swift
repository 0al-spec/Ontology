import OntologyRules
import XCTest

final class InheritanceSpecsTests: XCTestCase {
    func testCycleUsesThePackageQualifiedIdentity() {
        let spec = AcyclicInheritanceSpec()
        XCTAssertTrue(spec.isSatisfiedBy(.init(candidate: "a@1:Node", visited: ["b@1:Node"])))
        XCTAssertFalse(spec.isSatisfiedBy(.init(candidate: "a@1:Node", visited: ["a@1:Node"])))
    }

    func testFieldCompatibilityIncludesTypeRequirednessAndTarget() {
        let spec = CompatibleInheritedFieldSpec()
        let field = InheritedFieldSignature(type: "ref", required: true, target: "shared:Item")
        XCTAssertTrue(spec.isSatisfiedBy((field, field)))
        XCTAssertFalse(spec.isSatisfiedBy((field, .init(type: "string", required: true, target: nil))))
        XCTAssertFalse(spec.isSatisfiedBy((field, .init(type: "ref", required: false, target: "shared:Item"))))
        XCTAssertFalse(spec.isSatisfiedBy((field, .init(type: "ref", required: true, target: "other:Item"))))
    }
}
