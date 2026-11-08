import OntologyRules
import XCTest

final class ImportedTypedRefDecisionSpecTests: XCTestCase {
    func testResolutionNeedsAnExplicitClassAndDetectsAmbiguousTypeIdentity() {
        func context(_ reference: String, localNamespace: String = "local",
                     classes: [String: Set<String>] = ["shared": ["Item"]],
                     namespaces: [String: String] = ["shared": "canonical"],
                     identities: [String: String] = ["shared": "example.shared@1.0.0"]) -> ImportedTypedRefContext {
            ImportedTypedRefContext(reference: reference, localNames: ["Item"], localNamespace: localNamespace,
                                    declaredAliases: ["shared", "other"], classesByAlias: classes,
                                    namespacesByAlias: namespaces, identitiesByAlias: identities)
        }
        let spec = ImportedTypedRefDecisionSpec()
        XCTAssertEqual(spec.decide(context("Item")), .local)
        XCTAssertEqual(spec.decide(context("shared:Item")), .imported)
        XCTAssertEqual(spec.decide(context("shared:Missing")), .unresolved)
        XCTAssertEqual(spec.decide(context("unknown:Item")), .unresolved)
        XCTAssertEqual(spec.decide(context("shared:Item", classes: [:])), .unresolved)
        XCTAssertEqual(spec.decide(context("shared:Item", localNamespace: "canonical")), .namespaceConflict)
        XCTAssertEqual(spec.decide(context("shared:Item", classes: ["shared": ["Item"], "other": ["Item"]],
                                           namespaces: ["shared": "canonical", "other": "canonical"],
                                           identities: ["shared": "example.shared@1.0.0", "other": "example.other@1.0.0"])),
                       .namespaceConflict)
    }
}
