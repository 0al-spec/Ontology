import OntologyRules
import XCTest

final class RelationEndpointNamesSpecTests: XCTestCase {
    func testNamesFollowTheDeclarationEvenWhenAPartnerIsMissing() {
        let spec = RelationEndpointNamesSpec()
        XCTAssertEqual(spec.decide(["subject", "action", "object"]), .acting)
        XCTAssertEqual(spec.decide(["action"]), .acting)
        XCTAssertEqual(spec.decide(["object"]), .acting)
        XCTAssertEqual(spec.decide(["domain", "range", "action"]), .binary)
        XCTAssertEqual(spec.decide(["range"]), .binary)
        XCTAssertNil(spec.decide(["subject", "action", "range"]))
        XCTAssertNil(spec.decide(["subject", "object", "domain", "range", "action"]))
    }
}
