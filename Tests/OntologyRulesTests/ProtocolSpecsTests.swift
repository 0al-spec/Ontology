import OntologyRules
import XCTest

final class ProtocolSpecsTests: XCTestCase {
    func testObligationsDistinguishMissingFromUnverified() {
        let spec = ProtocolObligationDecisionSpec()
        XCTAssertEqual(spec.decide(.init(name: "cites", declaredNames: ["cites"], ancestryComplete: false)), .satisfied)
        XCTAssertEqual(spec.decide(.init(name: "cites", declaredNames: [], ancestryComplete: true)), .missing)
        XCTAssertEqual(spec.decide(.init(name: "cites", declaredNames: [], ancestryComplete: false)), .unverified)
    }

    func testProtocolCanNarrowOnlyTheBuiltinIdentity() {
        let spec = ProtocolBuiltinIdentitySpec()
        XCTAssertTrue(spec.isSatisfiedBy(.init(rawValue: "id")))
        XCTAssertFalse(spec.isSatisfiedBy(.init(rawValue: "trace")))
    }

    func testProtocolRelationConformanceSatisfied() {
        let context = ProtocolConformanceContext(
            protocolRequiredRelations: ["hasAuditLogEntry", "assignedTo"],
            classRelationDomains: ["hasAuditLogEntry", "assignedTo", "ownedBy"]
        )
        XCTAssertTrue(ProtocolRelationConformanceSpec().isSatisfiedBy(context))
    }

    func testProtocolRelationConformanceMissing() {
        let context = ProtocolConformanceContext(
            protocolRequiredRelations: ["hasAuditLogEntry"],
            classRelationDomains: ["assignedTo"]
        )
        XCTAssertFalse(ProtocolRelationConformanceSpec().isSatisfiedBy(context))
    }

    func testProtocolRelationConformancePartiallyMissing() {
        let context = ProtocolConformanceContext(
            protocolRequiredRelations: ["hasAuditLogEntry", "assignedTo"],
            classRelationDomains: ["hasAuditLogEntry"]
        )
        XCTAssertFalse(ProtocolRelationConformanceSpec().isSatisfiedBy(context))
    }

    func testProtocolRelationConformanceNoRequirements() {
        let context = ProtocolConformanceContext(
            protocolRequiredRelations: [],
            classRelationDomains: []
        )
        XCTAssertTrue(ProtocolRelationConformanceSpec().isSatisfiedBy(context))
    }

    func testProtocolRelationConformanceNoRequirementsWithDomains() {
        let context = ProtocolConformanceContext(
            protocolRequiredRelations: [],
            classRelationDomains: ["someRelation"]
        )
        XCTAssertTrue(ProtocolRelationConformanceSpec().isSatisfiedBy(context))
    }
}
