import OntologyRules
import XCTest

final class SecuritySpecsTests: XCTestCase {
    func testUnsafeYamlKeySpec() {
        XCTAssertTrue(UnsafeYamlKeySpec().isSatisfiedBy(YamlMappingKey(rawValue: "script")))
        XCTAssertTrue(UnsafeYamlKeySpec().isSatisfiedBy(YamlMappingKey(rawValue: "Hooks")))
        XCTAssertFalse(UnsafeYamlKeySpec().isSatisfiedBy(YamlMappingKey(rawValue: "description")))
    }

    func testExecutableLookingYamlValueSpec() {
        XCTAssertTrue(ExecutableLookingYamlValueSpec().isSatisfiedBy(YamlScalarText(rawValue: "$(rm -rf tmp)")))
        XCTAssertTrue(ExecutableLookingYamlValueSpec().isSatisfiedBy(YamlScalarText(rawValue: "child_process.exec")))
        XCTAssertFalse(ExecutableLookingYamlValueSpec().isSatisfiedBy(YamlScalarText(rawValue: "Exam mode policy text")))
    }

    func testUnsafeYamlTagSpec() {
        XCTAssertTrue(UnsafeYamlTagSpec().isSatisfiedBy(YamlSourceLine(rawValue: "!!ruby/object")))
        XCTAssertTrue(UnsafeYamlTagSpec().isSatisfiedBy(YamlSourceLine(rawValue: "!<tag:yaml.org,2002:js/function>")))
        XCTAssertFalse(UnsafeYamlTagSpec().isSatisfiedBy(YamlSourceLine(rawValue: "kind: DomainOntologyPackage")))
    }
}
