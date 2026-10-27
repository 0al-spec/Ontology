import Foundation
@testable import OntologyCompiler
import XCTest

extension SnapshotProvenanceTests {
    func changeAuthority(_ authority: inout Object, _ key: String, _ transform: (inout [Object]) -> Void) throws {
        var entries = try XCTUnwrap(authority[key] as? [Object])
        transform(&entries)
        authority[key] = entries
    }

    func testAuthorityCapabilitiesScopesTargetsAndStrictShape() throws {
        let graph = try fixture("confirmed-source")
        for (key, value, code): (String, Any, String) in [
            ("capabilities", ["confirm-unknown"], "provenance.authority.capability"),
            ("projectionKeys", ["other-projection"], "provenance.confirmation.authority"),
            ("scopeKeys", ["*"], "provenance.authority.shape"),
            ("capabilities", ["confirm-source", "confirm-source"], "provenance.authority.shape"),
            ("authorityKey", "unknown-reviewer", "provenance.confirmation.authority")
        ] {
            var authority = try fixture("confirmed-source-authority")
            try changeAuthority(&authority, "grants") { $0[0][key] = value }
            assertCode(try evaluate(graph, authority: authority), code)
        }
        var authority = try fixture("confirmed-source-authority")
        try changeAuthority(&authority, "grants") { $0.append($0[0]) }
        assertCode(try evaluate(graph, authority: authority), "provenance.authority.duplicate")
        authority = try fixture("confirmed-source-authority")
        authority["selfAuthorized"] = true
        assertCode(try evaluate(graph, authority: authority), "provenance.authority.shape")
        authority = try fixture("confirmed-source-authority")
        try changeAuthority(&authority, "confirmations") { $0[0]["rationale"] = "  " }
        assertCode(try evaluate(graph, authority: authority), "provenance.authority.shape")
        authority = try fixture("confirmed-source-authority")
        authority["grants"] = NSNull()
        assertCode(try evaluate(graph, authority: authority), "provenance.authority.shape")
    }

    func testOriginIdentityCaptureAndOperatorRationale() throws {
        for (kind, node, key, value, code): (String, String, String, Any, String) in [
            ("source", "letter", "sourceDigest", "unhashed", "provenance.origin.sourceDigest"),
            ("source", "claimed-after-origin", "originKey", "claimed-before-origin", "provenance.origin.duplicate"),
            ("source", "claimed-before-origin", "extractionMethod", "  ", "provenance.origin.blank"),
            ("direct", "claimed-before-origin", "artifactDigest", "forged", "provenance.origin.capture"),
            ("direct", "claimed-before-origin", "observedAt", -1, "provenance.origin.capture"),
            ("direct", "claimed-before-origin", "clockKey", "other-clock", "provenance.capture.boundary"),
            ("operator", "claimed-before-origin", "rationale", "  ", "provenance.origin.rationale")
        ] {
            var graph = try fixture("confirmed-\(kind)")
            try field(&graph, node, key, value)
            assertCode(try evaluate(graph, authority: fixture("confirmed-\(kind)-authority")), code)
        }
    }

    func testDigestFormatRequiresTheEntireUnmodifiedString() throws {
        let suffixes = ["\n", "\r", "\r\n", "\u{0085}", "\u{2028}", "\u{2029}", "x"]
        for (kind, node, key, code) in [
            ("source", "letter", "sourceDigest", "provenance.origin.sourceDigest"),
            ("direct", "claimed-before-origin", "artifactDigest", "provenance.origin.capture")
        ] {
            let valid = try fixture("confirmed-\(kind)")
            let nodes = try XCTUnwrap(valid["nodes"] as? [Object])
            let fields = try XCTUnwrap(nodes.first { $0["id"] as? String == node }?["fields"] as? Object)
            let original = try XCTUnwrap(fields[key] as? String)
            for malformed in suffixes.map({ original + $0 }) + ["\n" + original, String(original.dropLast())] {
                var graph = valid
                try field(&graph, node, key, malformed)
                // Resupply the trusted graph binding to isolate digest validation.
                let result = try evaluate(graph, authority: fixture("confirmed-\(kind)-authority"))
                assertCode(result, code)
                XCTAssertEqual((result.report["provenance"] as? Object)?["confirmationStatus"] as? String, "not-confirmed")
            }
        }
    }

    func testUnreferencedSnapshotAndOrphanOriginCannotAvoidAdmission() throws {
        var graph = try fixture("confirmed-source")
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        var snapshot = try XCTUnwrap(nodes.first { $0["id"] as? String == "claimed-before" })
        snapshot["id"] = "unreferenced-state"
        nodes.append(snapshot)
        graph["nodes"] = nodes
        assertCode(try evaluate(graph, authority: fixture("confirmed-source-authority")), "provenance.origin.required")
        graph = try fixture("confirmed-source")
        nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        var origin = try XCTUnwrap(nodes.first { $0["id"] as? String == "claimed-before-origin" })
        origin["id"] = "orphan-origin"
        origin["fields"] = ["originKey": "orphan", "extractionMethod": "synthetic-v1"]
        nodes.append(origin)
        graph["nodes"] = nodes
        try appendEdge(&graph, "originCitesAssertion", "orphan-origin", "letter")
        assertCode(try evaluate(graph, authority: fixture("confirmed-source-authority")), "provenance.origin.owner")
    }

    func testKnownSnapshotMustBePreservedDuringEnrichment() throws {
        var graph = try fixture("confirmed-source")
        try field(&graph, "unknown-before", "availability", "known")
        try appendEdge(&graph, "observationSnapshot", "unknown-before", "claimed-before")
        XCTAssertTrue(try evaluate(graph, authority: fixture("confirmed-source-authority")).passed)
        var edges = try XCTUnwrap(graph["edges"] as? [Object])
        edges.removeAll { $0["relation"] as? String == "eventcore:observationSnapshot" }
        graph["edges"] = edges
        try appendEdge(&graph, "observationSnapshot", "unknown-before", "claimed-after")
        assertCode(try evaluate(graph, authority: fixture("confirmed-source-authority")), "provenance.enrichment.known")
    }

    func testPartialFactsRetainPolarityRatherThanBecomingEmpty() throws {
        var graph = try fixture("confirmed-source")
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "partial-fact", "type": "eventcore:Fact", "fields": ["propositionKey": "on-road", "polarity": "negative"]])
        graph["nodes"] = nodes
        try field(&graph, "unknown-before", "availability", "partial")
        try appendEdge(&graph, "observationSuppliesFact", "unknown-before", "partial-fact")
        assertCode(try evaluate(graph, authority: fixture("confirmed-source-authority")), "provenance.enrichment.partial")
        try appendEdge(&graph, "snapshotContainsFact", "claimed-before", "partial-fact")
        try appendEdge(&graph, "deltaRemovesFact", "claimed-empty-delta", "partial-fact")
        XCTAssertTrue(try evaluate(graph, authority: fixture("confirmed-source-authority")).passed)
    }

    func testResolvedInterpretationNeedsTheAdmittedEventLink() throws {
        var graph = try fixture("confirmed-source")
        var nodes = try XCTUnwrap(graph["nodes"] as? [Object])
        nodes.append(["id": "resolved-view", "type": "eventcore:Interpretation", "fields": ["interpretationKey": "resolved"]])
        graph["nodes"] = nodes
        try appendEdge(&graph, "interpretsRecord", "resolved-view", "claimed-record")
        try appendEdge(&graph, "candidateResolvedAsInterpretation", "letter-view", "resolved-view")
        XCTAssertTrue(try evaluate(graph, authority: fixture("confirmed-source-authority")).passed)
        var authority = try fixture("confirmed-source-authority")
        authority["enrichments"] = []
        assertCode(try evaluate(graph, authority: authority), "provenance.enrichment.required")
        authority = try fixture("confirmed-source-authority")
        try changeAuthority(&authority, "enrichments") { $0[0]["recordId"] = "letter" }
        assertCode(try evaluate(graph, authority: authority), "provenance.enrichment.target")
    }

    func testAuthorityBytesRejectBOMAndDuplicateKeys() throws {
        let directory = try temporary()
        let path = directory.appendingPathComponent("authority.json")
        let original = try Data(contentsOf: fixtures.appendingPathComponent("confirmed-source-authority.json"))
        let invalid = [Data([0xEF, 0xBB, 0xBF]) + original, Data("{\"kind\":1,\"kind\":2}".utf8)]
        for data in invalid {
            try data.write(to: path)
            let result = try OntologyCompiler().validateInstanceGraph(graphPath: .init(url: fixtures.appendingPathComponent("confirmed-source.json")), ontologyIRPath: ir, profile: profile, provenanceAuthorityPath: .init(url: path))
            XCTAssertFalse(result.passed)
            XCTAssertEqual(result.diagnostics.first?.code, "instanceGraph.input")
            let provenance = try XCTUnwrap(result.report["provenance"] as? Object)
            XCTAssertEqual(provenance["authorityInputSHA256"] as? String, digest(data))
        }
    }

    func testRealCLIRequiresExplicitProfileAndTrustedAuthority() throws {
        let compiler = ProcessInfo.processInfo.environment["ONTOLOGYC_TEST_BINARY_PATH"] ?? root.appendingPathComponent(".build/debug/ontologyc").path
        let output = try temporary()
        let report = output.appendingPathComponent("report.json")
        func cli(_ additional: [String]) throws -> Int32 {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: compiler)
            process.arguments = ["validate-instances", fixtures.appendingPathComponent("confirmed-operator.json").path, "--ontology-ir", ir.path, "--out", report.path] + additional
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            try process.run()
            _ = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return process.terminationStatus
        }
        XCTAssertEqual(try cli([]), 1)
        XCTAssertEqual(try cli(["--profile", profile]), 1)
        XCTAssertEqual(try cli(["--profile", profile, "--provenance-authority", fixtures.appendingPathComponent("confirmed-operator-authority.json").path]), 0)
        let value = try read(report)
        XCTAssertEqual(value["profile"] as? String, profile)
        XCTAssertEqual((value["provenance"] as? Object)?["confirmationStatus"] as? String, "confirmed-under-supplied-authority")
    }
}
