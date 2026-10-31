import OntologyRules
import XCTest

final class DiagramSelectionSpecTests: XCTestCase {
    func testPlainViewsAndPairedRelationsAreAccepted() {
        for view in ["full", "relations"] {
            XCTAssertEqual(decide(view, imports: false, expanded: []), .valid)
        }
        XCTAssertEqual(decide("relations", imports: true, expanded: ["ev:Record"]), .valid)
    }

    func testExpansionRequiresRelationsViewThroughEitherInput() {
        XCTAssertEqual(decide("full", imports: true, expanded: []), .valid)
        XCTAssertEqual(decide("full", imports: false, expanded: ["ev:Record"]), .requiresRelationsView)
        XCTAssertEqual(decide("full", imports: true, expanded: ["ev:Record"]), .requiresRelationsView)
    }

    func testUnpairedAndEmptySelectorsHaveSharedDecisions() {
        XCTAssertEqual(decide("relations", imports: true, expanded: []), .unpairedSelection)
        XCTAssertEqual(decide("relations", imports: false, expanded: ["ev:Record"]), .unpairedSelection)
        XCTAssertEqual(decide("relations", imports: true, expanded: [""]), .emptySelector)
        XCTAssertEqual(decide("relations", imports: true, expanded: ["ev:Record", ""]), .emptySelector)
        XCTAssertTrue(DiagramSelectionDecision.unpairedSelection.message.contains("together"))
    }

    private func decide(_ view: String, imports: Bool, expanded: [String]) -> DiagramSelectionDecision? {
        DiagramSelectionSpec().decide(DiagramSelectionContext(view: view, hasImports: imports, expandedTypes: expanded))
    }
}
