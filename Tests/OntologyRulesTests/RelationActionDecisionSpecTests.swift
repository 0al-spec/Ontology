import OntologyRules
import XCTest

final class RelationActionDecisionSpecTests: XCTestCase {
    func testUsesIdentifiedFoundationRatherThanSymbolSpelling() {
        let spec = RelationActionDecisionSpec(
            packageNamespace: "pilot",
            classBases: [
                "Appoint": "base:Action", "Nominate": "pilot:Appoint",
                "Action": "base:DomainEntity", "Person": "Action",
                "External": "other:Action", "Loop": "pilot:Loop"
            ],
            foundations: ["base": .current, "old": .version010]
        )
        for ref in ["base:Action", "Appoint", "pilot:Nominate"] {
            XCTAssertEqual(spec.decide(ref), .action, ref)
        }
        for ref in ["Action", "pilot:Action", "Person", "base:Command", "Loop"] {
            XCTAssertEqual(spec.decide(ref), .wrongKind, ref)
        }
        for ref in ["Unknown", "other:Action", "External", "old:Action", "base::Action", ""] {
            XCTAssertEqual(spec.decide(ref), .unresolved, ref)
        }
    }
}
