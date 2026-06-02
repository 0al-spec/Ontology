import Foundation
import OntologyRules
import XCTest
@testable import OntologyCompiler

final class CompilerArgumentTypesTests: XCTestCase {
    func testSourcePathPreservesRelativePathString() {
        let path = OntologySourcePath(path: "SPECS/example.yaml")

        XCTAssertEqual(path.path, "SPECS/example.yaml")
        XCTAssertTrue(path.url.path.hasSuffix("SPECS/example.yaml"))
    }

    func testRegistryBaseURLRequiresAbsoluteURL() throws {
        XCTAssertNotNil(RegistryBaseURL(string: "https://registry.example.com"))
        XCTAssertNotNil(RegistryBaseURL(url: try XCTUnwrap(URL(string: "https://registry.example.com"))))
        XCTAssertNil(RegistryBaseURL(string: "registry.example.com"))
        XCTAssertNil(RegistryBaseURL(url: URL(fileURLWithPath: "registry.example.com")))
    }

    func testPackageReferenceParsesIdAndVersion() throws {
        let reference = try XCTUnwrap(OntologyPackageReference(rawValue: "org.0al.examcalc@1.0.0"))

        XCTAssertEqual(reference.id, "org.0al.examcalc")
        XCTAssertEqual(reference.version, "1.0.0")
        XCTAssertEqual(reference.packageId, OntologyPackageId(rawValue: "org.0al.examcalc"))
        XCTAssertEqual(reference.semanticVersion, OntologySemanticVersion(rawValue: "1.0.0"))
        XCTAssertEqual(reference.rawValue, "org.0al.examcalc@1.0.0")
        XCTAssertNil(OntologyPackageReference(rawValue: "org.0al.examcalc"))
    }
}
