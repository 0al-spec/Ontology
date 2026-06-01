import OntologyRules
import XCTest

final class ProtocolSpecsTests: XCTestCase {
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
