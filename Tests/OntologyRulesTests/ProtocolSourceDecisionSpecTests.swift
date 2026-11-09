import XCTest
@testable import OntologyRules

final class ProtocolSourceDecisionSpecTests: XCTestCase {
    func testRequiresOneExactSourceContainingTheProtocol() {
        let expected = DiagramPackageIdentity(id: "example.protocols", version: "1.0.0")
        let otherVersion = DiagramPackageIdentity(id: "example.protocols", version: "2.0.0")
        let otherPackage = DiagramPackageIdentity(id: "example.other", version: "1.0.0")
        let valid = ProtocolSourceCandidate(identity: expected, protocolNames: ["Tracked"])
        let wrongVersion = ProtocolSourceCandidate(identity: otherVersion, protocolNames: ["Tracked"])
        let wrongPackage = ProtocolSourceCandidate(identity: otherPackage, protocolNames: ["Tracked"])
        let missing = ProtocolSourceCandidate(identity: expected, protocolNames: ["Different"])
        let spec = ProtocolSourceDecisionSpec()
        func decide(_ candidates: [ProtocolSourceCandidate]) -> ProtocolSourceDecision? {
            spec.decide(.init(identity: expected, protocolName: "Tracked", candidates: candidates))
        }
        XCTAssertEqual(decide([wrongVersion, wrongPackage]), .missingSource)
        XCTAssertEqual(decide([missing]), .missingProtocol)
        XCTAssertEqual(decide([valid, valid]), .ambiguousSource)
        XCTAssertEqual(decide([wrongVersion, valid, wrongPackage]), .resolved)
    }
}
