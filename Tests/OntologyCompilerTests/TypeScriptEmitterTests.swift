import XCTest
@testable import OntologyCompiler

final class TypeScriptEmitterTests: XCTestCase {
    func testEmitTypesImportsLocalProtocolInterfaces() {
        let ir: [String: Any] = [
            "protocols": [
                [
                    "id": "Signable",
                    "fqid": "examcalc:Signable",
                    "requiredFields": ["signature"]
                ] as [String: Any],
                [
                    "id": "Auditable",
                    "fqid": "examcalc:Auditable",
                    "requiredFields": ["auditId"]
                ] as [String: Any]
            ],
            "classes": [
                [
                    "id": "Exam",
                    "fqid": "examcalc:Exam",
                    "implements": ["examcalc:Signable", "examcalc:Auditable"]
                ] as [String: Any]
            ]
        ]

        let types = OntologyCompiler().emitTypes(ir)

        XCTAssertTrue(
            types.contains("import type { Auditable, Signable } from \"./protocols\";"),
            types
        )
        XCTAssertTrue(types.contains("export interface Exam extends Signable, Auditable"), types)
    }

    func testJsonTextRejectsInvalidJSONWithoutForceCast() {
        let valid = OntologyCompiler().jsonText(["id": "examcalc"] as [String: Any])
        XCTAssertTrue(valid.contains("\"id\" : \"examcalc\""), valid)
    }

    func testEmitTypesSurfacesImportedProtocolRefs() {
        let ir: [String: Any] = [
            "protocols": [] as [Any],
            "classes": [
                [
                    "id": "Exam",
                    "fqid": "examcalc:Exam",
                    "implements": ["external:Signable"]
                ] as [String: Any]
            ]
        ]

        let types = OntologyCompiler().emitTypes(ir)

        XCTAssertTrue(
            types.contains("Warning: imported protocol refs are not emitted as local TypeScript interfaces: external:Signable."),
            types
        )
        XCTAssertTrue(types.contains("export interface Exam {"), types)
    }
}
