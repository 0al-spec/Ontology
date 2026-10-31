import Foundation
import XCTest

extension OntologyVizCLITests {
    func testProfileReproducesSavedMotivationDOTFromAnotherWorkingDirectory() throws {
        try inTemporaryDirectory { temp in
            let result = try run(["--profile", motivationProfile.path, "--out", "diagrams"], directory: temp)
            XCTAssertEqual(result.status, 0, result.stderr)
            let output = temp.appendingPathComponent("diagrams")
            let dot = try String(contentsOf: output.appendingPathComponent("ontology.dot"), encoding: .utf8)
            let expected = try String(contentsOf: root.appendingPathComponent("Examples/package-visualization/motivation-relations.dot"), encoding: .utf8)
            XCTAssertEqual(dot, expected)
            let svg = try String(contentsOf: output.appendingPathComponent("ontology.svg"), encoding: .utf8)
            XCTAssertTrue(svg.contains("eventcore:deltaOfRecord"))
            let png = try Data(contentsOf: output.appendingPathComponent("ontology.png"))
            XCTAssertEqual(Array(png.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
        }
    }

    func testProfileDirectionOverrideAndRuntimeFormat() throws {
        try inTemporaryDirectory { output in
            let original = try Data(contentsOf: motivationProfile)
            let result = try run(["--direction", "TB", "--profile", motivationProfile.path, "--format", "dot", "--out", output.path])
            XCTAssertEqual(result.status, 0, result.stderr)
            let dot = try String(contentsOf: output.appendingPathComponent("ontology.dot"), encoding: .utf8)
            XCTAssertTrue(dot.contains("rankdir=TB"))
            XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: output.path), ["ontology.dot"])
            XCTAssertEqual(try Data(contentsOf: motivationProfile), original)
        }
    }

    func testProfileDefaultsAndSymlinkUseTheActualProfileDirectory() throws {
        try inTemporaryDirectory { temp in
            let actual = temp.appendingPathComponent("actual")
            let links = temp.appendingPathComponent("links")
            for directory in [actual, links] { try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true) }
            try FileManager.default.copyItem(at: example, to: actual.appendingPathComponent("package.yaml"))
            let profile = actual.appendingPathComponent("profile.json")
            try writeProfile(["schemaVersion": 1, "package": "package.yaml"], to: profile)
            let link = links.appendingPathComponent("profile.json")
            try FileManager.default.createSymbolicLink(at: link, withDestinationURL: profile)
            let result = try run(["--profile", link.path, "--format", "dot", "--out", "output"], directory: temp)
            XCTAssertEqual(result.status, 0, result.stderr)
            let dot = try String(contentsOf: temp.appendingPathComponent("output/ontology.dot"), encoding: .utf8)
            XCTAssertTrue(dot.contains("rankdir=LR"))
            XCTAssertTrue(dot.contains("appliesTo"))
            XCTAssertTrue(dot.contains("lifecycle"))
        }
    }

    func testInvalidProfileShapeVersionAndChoicesCreateNoOutput() throws {
        try inTemporaryDirectory { temp in
            let base: [String: Any] = ["schemaVersion": 1, "package": example.path]
            let invalid: [[String: Any]] = [
                ["package": example.path], ["schemaVersion": 2, "package": example.path],
                ["schemaVersion": true, "package": example.path], ["schemaVersion": 1, "package": 7],
                ["schemaVersion": 1, "package": "   "], base.merging(["unknown": true]) { _, new in new },
                base.merging(["view": "unknown"]) { _, new in new },
                base.merging(["direction": "diagonal"]) { _, new in new },
                base.merging(["imports": [7]]) { _, new in new },
                base.merging(["expand": "ev:Example"]) { _, new in new }
            ] + ["view", "direction", "imports", "expand", "$schema"].map { key in
                base.merging([key: NSNull()]) { _, new in new }
            }
            for fields in invalid {
                let profile = temp.appendingPathComponent("profile.json")
                try writeProfile(fields, to: profile)
                let output = temp.appendingPathComponent("output")
                let result = try run(["--profile", profile.path, "--out", output.path])
                XCTAssertEqual(result.status, 2, result.stderr)
                XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            }
        }
    }

    func testMissingOrMalformedProfileFailsAsConfigurationError() throws {
        try inTemporaryDirectory { temp in
            let profile = temp.appendingPathComponent("profile.json")
            let output = temp.appendingPathComponent("output")
            XCTAssertEqual(try run(["--profile", profile.path, "--out", output.path]).status, 2)
            for json in ["{", "[]"] {
                try json.write(to: profile, atomically: true, encoding: .utf8)
                let result = try run(["--profile", profile.path, "--out", output.path])
                XCTAssertEqual(result.status, 2)
                XCTAssertTrue(result.stderr.contains(profile.path))
                XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            }
        }
    }

    func testProfileRejectsSelectionConflictsAndDuplicateProfileFlag() throws {
        try inTemporaryDirectory { temp in
            for extra in [[example.path], ["--view", "full"], ["--import", example.path],
                          ["--expand", "ev:Example"], ["--profile", motivationProfile.path]] {
                let output = temp.appendingPathComponent("output")
                let result = try run(["--profile", motivationProfile.path, "--out", output.path] + extra)
                XCTAssertEqual(result.status, 2, result.stderr)
                XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            }
        }
    }

    func testProfileIsProtectedFromOutputReplacement() throws {
        try inTemporaryDirectory { output in
            let profile = output.appendingPathComponent("ontology.dot")
            try writeProfile(["schemaVersion": 1, "package": example.path], to: profile)
            let original = try Data(contentsOf: profile)
            let result = try run(["--profile", profile.path, "--out", output.path, "--format", "dot"])
            XCTAssertEqual(result.status, 1)
            XCTAssertTrue(result.stderr.contains("overwrite input"))
            XCTAssertEqual(try Data(contentsOf: profile), original)
        }
    }

    private func writeProfile(_ fields: [String: Any], to path: URL) throws {
        try JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys]).write(to: path)
    }

    private var motivationProfile: URL {
        root.appendingPathComponent("Examples/package-visualization/motivation-relations.profile.json")
    }
}
