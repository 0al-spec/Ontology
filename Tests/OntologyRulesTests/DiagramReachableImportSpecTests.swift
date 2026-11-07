import OntologyRules
import XCTest

final class DiagramReachableImportSpecTests: XCTestCase {
    func testReachabilityUsesBothPackageIdentityAndExactVersion() {
        let reachable = Set([DiagramPackageIdentity(id: "example.core", version: "1.0.0")])
        let spec = DiagramReachableImportSpec()
        XCTAssertTrue(spec.isSatisfiedBy(.init(supplied: .init(id: "example.core", version: "1.0.0"), reachable: reachable)))
        XCTAssertFalse(spec.isSatisfiedBy(.init(supplied: .init(id: "example.core", version: "2.0.0"), reachable: reachable)))
        XCTAssertFalse(spec.isSatisfiedBy(.init(supplied: .init(id: "example.other", version: "1.0.0"), reachable: reachable)))
    }
}
