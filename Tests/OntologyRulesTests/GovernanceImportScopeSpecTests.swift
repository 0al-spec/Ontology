import OntologyRules
import XCTest

final class GovernanceImportScopeSpecTests: XCTestCase {
    func testImportsRequireAnOwningPackage() {
        let spec = GovernanceImportScopeSpec()
        XCTAssertTrue(spec.isSatisfiedBy(.init(hasPackage: false, hasImports: false)))
        XCTAssertTrue(spec.isSatisfiedBy(.init(hasPackage: true, hasImports: false)))
        XCTAssertTrue(spec.isSatisfiedBy(.init(hasPackage: true, hasImports: true)))
        XCTAssertFalse(spec.isSatisfiedBy(.init(hasPackage: false, hasImports: true)))
    }
}
