import OntologyRules
import XCTest

final class DiagramImportBindingSpecTests: XCTestCase {
    private let imported = DiagramImportDeclaration(id: "example.events", version: "0.2.0", namespace: "ev")

    func testExactIdentityBindsAlias() {
        XCTAssertEqual(decide([imported]), .matched(namespace: "ev"))
    }

    func testWrongVersionOrIdentityCannotBindByNamespace() {
        XCTAssertEqual(decide([DiagramImportDeclaration(id: imported.id.rawValue, version: "0.1.0", namespace: "ev")]), .missing)
        XCTAssertEqual(decide([DiagramImportDeclaration(id: "other.events", version: imported.version.rawValue, namespace: "ev")]), .missing)
    }

    func testDuplicateIdentitiesAndSharedAliasesAreAmbiguous() {
        XCTAssertEqual(decide([imported, imported]), .ambiguous)
        XCTAssertEqual(decide([imported, DiagramImportDeclaration(id: "other.events", version: "0.2.0", namespace: "ev")]), .ambiguous)
    }

    func testMissingInvalidAndRootShadowingAliasesFail() {
        for alias in ["", "bad_alias", "root"] {
            XCTAssertEqual(decide([DiagramImportDeclaration(id: imported.id.rawValue, version: imported.version.rawValue, namespace: alias)]), .invalidNamespace)
        }
    }

    func testImportedScopeRejectsAliasShadowingButAllowsUnaliasedUnusedImports() {
        let scope = DiagramImportScopeSpec()
        XCTAssertTrue(scope.isSatisfiedBy(context([imported])))
        XCTAssertFalse(scope.isSatisfiedBy(context([imported, imported])))
        XCTAssertFalse(scope.isSatisfiedBy(context([DiagramImportDeclaration(id: "other", version: "1.0.0", namespace: "root")])))
        XCTAssertTrue(scope.isSatisfiedBy(context([DiagramImportDeclaration(id: "other", version: "1.0.0", namespace: "")])))
    }

    private func decide(_ imports: [DiagramImportDeclaration]) -> DiagramImportBindingDecision? {
        DiagramImportBindingSpec().decide(context(imports))
    }

    private func context(_ imports: [DiagramImportDeclaration]) -> DiagramImportBindingContext {
        DiagramImportBindingContext(packageId: imported.id.rawValue, version: imported.version.rawValue, rootNamespace: "root", imports: imports)
    }
}
