import OntologyRules
import XCTest

final class OntologyRulesScaffoldTests: XCTestCase {
    func testOntologyRulesTargetUsesSpecificationCore() {
        let spec = OntologyRulesScaffold.nonEmptyStringSpec()

        XCTAssertTrue(spec.isSatisfiedBy("examcalc"))
        XCTAssertFalse(spec.isSatisfiedBy(""))
    }
}
