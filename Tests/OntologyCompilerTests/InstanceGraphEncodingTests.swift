import Foundation
@testable import OntologyCompiler
import XCTest

extension InstanceGraphValidationTests {
    func testUnprovenEmptyEnrichmentIsAnExplicitStructuralLimitation() throws {
        // The profile has no snapshot provenance. This expected pass is a known
        // limitation, not evidence that the candidate's unknown states became known.
        let result = try OntologyCompiler().validateInstanceGraph(graphPath: fixture("limitation-unproven-empty-enrichment"), ontologyIRPath: ir)
        XCTAssertTrue(result.passed)
        let authority = try XCTUnwrap(result.report["authority"] as? [String: Bool])
        XCTAssertEqual(authority["structuralOnly"], true)
        XCTAssertEqual(authority["sourceTruthVerified"], false)
    }

    private func unsupportedEncodings(_ text: String) throws -> [(String, Data)] {
        let encodings: [(String, String.Encoding)] = [
            ("utf16", .utf16), ("utf16-le", .utf16LittleEndian), ("utf16-be", .utf16BigEndian),
            ("utf32", .utf32), ("utf32-le", .utf32LittleEndian), ("utf32-be", .utf32BigEndian)
        ]
        return try encodings.map { ($0.0, try XCTUnwrap(text.data(using: $0.1))) } + [
            ("utf8-bom", Data([0xEF, 0xBB, 0xBF]) + Data(text.utf8)),
            ("whitespace-then-bom", Data([32, 10, 0xEF, 0xBB, 0xBF]) + Data(text.utf8))
        ]
    }

    func testGraphAcceptsUTF8WhitespaceButRejectsBOMAndUTF16Or32() throws {
        let path = try temporary().appendingPathComponent("graph.json")
        let text = try String(contentsOf: fixture("source-only").url, encoding: .utf8)
        try (" \n\t" + text + " \r\n").write(to: path, atomically: true, encoding: .utf8)
        XCTAssertTrue(try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: path), ontologyIRPath: ir).passed)
        for (name, data) in try unsupportedEncodings(text) {
            try data.write(to: path)
            let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: path), ontologyIRPath: ir)
            XCTAssertFalse(result.passed, name)
            XCTAssertEqual(result.diagnostics.first?.code, "instanceGraph.input", name)
        }
    }

    func testDuplicateKeysCannotBypassCheckingThroughEncoding() throws {
        let path = try temporary().appendingPathComponent("graph.json")
        let text = try String(contentsOf: fixture("source-only").url, encoding: .utf8)
        let duplicate = text.replacingOccurrences(of: "\"profile\": \"eventcore-v1\",", with: "\"profile\": \"eventcore-v1\", \"profile\": \"eventcore-v1\",")
        XCTAssertNotEqual(duplicate, text)
        let inputs = try unsupportedEncodings(duplicate) + [("utf8", Data(duplicate.utf8)), ("utf8-whitespace", Data((" \n" + duplicate).utf8))]
        for (name, data) in inputs {
            try data.write(to: path)
            let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: path), ontologyIRPath: ir)
            XCTAssertFalse(result.passed, name)
            XCTAssertEqual(result.diagnostics.first?.code, "instanceGraph.input", name)
        }
    }

    func testKeyScannerRequiresRootObjectFullConsumptionAndDepthLimit() throws {
        for input in [Data("{} true".utf8), Data([0xEF, 0xBB, 0xBF]) + Data("{}".utf8)] {
            var scanner = InstanceJSONKeyCheck(bytes: Array(input))
            XCTAssertThrowsError(try scanner.validate())
        }
        var valid = InstanceJSONKeyCheck(bytes: Array(" \n{\"x\":[true,1,\"text\",null]} \n".utf8))
        XCTAssertNoThrow(try valid.validate())
        let deep = String(repeating: "{\"child\":", count: 70) + "{}" + String(repeating: "}", count: 70)
        var scanner = InstanceJSONKeyCheck(bytes: Array(deep.utf8))
        XCTAssertThrowsError(try scanner.validate()) { XCTAssertTrue(String(describing: $0).contains("input.depth")) }
    }
}
