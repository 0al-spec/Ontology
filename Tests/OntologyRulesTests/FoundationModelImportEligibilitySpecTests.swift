import OntologyRules
import XCTest

final class FoundationImportEligibilitySpecTests: XCTestCase {
    func testMatchesOnlyReachableFoundationIdentitiesWithExactVersion() {
        let spec = FoundationModelImportEligibilitySpec()
        let legacy = DiagramImportDeclaration(id: "specgraph.foundation", version: "0.1.0", namespace: "sg")
        let canonicalOld = DiagramImportDeclaration(id: "ontology.foundation", version: "0.1.0", namespace: "ont")
        let current = DiagramImportDeclaration(id: "ontology.foundation", version: "0.2.0", namespace: "ont")
        let unrelated = DiagramImportDeclaration(id: "example.other", version: "0.1.0", namespace: "other")
        let nonexistent = DiagramImportDeclaration(id: "specgraph.foundation", version: "0.2.0", namespace: "sg")
        XCTAssertTrue(spec.isSatisfiedBy(.init(version: "0.1.0", imports: [legacy])))
        XCTAssertTrue(spec.isSatisfiedBy(.init(version: "0.1.0", imports: [canonicalOld])))
        XCTAssertTrue(spec.isSatisfiedBy(.init(version: "0.2.0", imports: [legacy, current])))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.2.0", imports: [legacy])))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.1.0", imports: [unrelated])))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.2.0", imports: [nonexistent])))
        XCTAssertFalse(spec.isSatisfiedBy(.init(version: "0.1.0", imports: [])))
    }
}
