import OntologyRules
import XCTest

final class SecuritySpecsTests: XCTestCase {
    func testUnsafeYamlKeySpec() {
        XCTAssertTrue(UnsafeYamlKeySpec().isSatisfiedBy("script"))
        XCTAssertTrue(UnsafeYamlKeySpec().isSatisfiedBy("Hooks"))
        XCTAssertFalse(UnsafeYamlKeySpec().isSatisfiedBy("description"))
    }

    func testExecutableLookingYamlValueSpec() {
        XCTAssertTrue(ExecutableLookingYamlValueSpec().isSatisfiedBy("$(rm -rf tmp)"))
        XCTAssertTrue(ExecutableLookingYamlValueSpec().isSatisfiedBy("child_process.exec"))
        XCTAssertFalse(ExecutableLookingYamlValueSpec().isSatisfiedBy("Exam mode policy text"))
    }

    func testUnsafeYamlTagSpec() {
        XCTAssertTrue(UnsafeYamlTagSpec().isSatisfiedBy("!!ruby/object"))
        XCTAssertTrue(UnsafeYamlTagSpec().isSatisfiedBy("!<tag:yaml.org,2002:js/function>"))
        XCTAssertFalse(UnsafeYamlTagSpec().isSatisfiedBy("kind: DomainOntologyPackage"))
    }
}
