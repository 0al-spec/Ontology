import Foundation
#if canImport(FoundationXML)
import FoundationXML
#endif
import XCTest

final class OntologyVizCLITests: XCTestCase {
    func testHelpAndInvalidArguments() throws {
        let help = try run(["--help"])
        XCTAssertEqual(help.status, 0)
        XCTAssertTrue(help.stdout.contains("Graphviz"))
        for arguments in [
            [], [example.path], [example.path, "--out"],
            [example.path, "--out", "x", "--format", "jpeg"],
            [example.path, "--out", "x", "--direction", "sideways"],
            [example.path, "--out", "x", "--out", "y"],
            [example.path, "--out", "x", "--unknown", "value"],
            [example.path, example.path, "--out", "x"]
        ] {
            let result = try run(arguments)
            XCTAssertEqual(result.status, 2, "\(arguments)\n\(result.stderr)")
        }
    }

    func testDOTNeedsNoRendererAndOptionsCanPrecedeInput() throws {
        try inTemporaryDirectory { temp in
            let output = temp.appendingPathComponent("path with spaces")
            let result = try run(["--format", "dot", "--out", output.path, "--direction", "TB", example.path], path: "")
            XCTAssertEqual(result.status, 0, result.stderr)
            let dot = try String(contentsOf: output.appendingPathComponent("ontology.dot"), encoding: .utf8)
            XCTAssertTrue(dot.contains("rankdir=TB"))
            XCTAssertFalse(FileManager.default.fileExists(atPath: output.appendingPathComponent("ontology.png").path))
        }
    }

    func testRealRendererProducesSVGAndPNGWithConsistentGraphLabels() throws {
        try inTemporaryDirectory { output in
            let result = try run([example.path, "--out", output.path])
            XCTAssertEqual(result.status, 0, result.stderr)
            let svg = try Data(contentsOf: output.appendingPathComponent("ontology.svg"))
            let parser = XMLParser(data: svg)
            XCTAssertTrue(parser.parse(), "\(String(describing: parser.parserError))")
            let text = String(decoding: svg, as: UTF8.self)
            for label in ["review:Proposal", "review:Evidence", "review:Reviewable", "cites", "review:Approve"] {
                XCTAssertTrue(text.contains(label), label)
            }
            let png = try Data(contentsOf: output.appendingPathComponent("ontology.png"))
            XCTAssertEqual(Array(png.prefix(8)), [137, 80, 78, 71, 13, 10, 26, 10])
            XCTAssertGreaterThan(png.count, 24)
            guard png.count > 24 else { return }
            XCTAssertTrue(png[16 ..< 20].contains { $0 != 0 }, "PNG width must be positive")
            XCTAssertTrue(png[20 ..< 24].contains { $0 != 0 }, "PNG height must be positive")
        }
    }

    func testSingleFormatsAndExplicitRenderer() throws {
        let executable = try graphvizExecutable()
        for format in ["svg", "png"] {
            try inTemporaryDirectory { output in
                let result = try run(["--format", format, example.path, "--out", output.path, "--dot", executable.path], path: "")
                XCTAssertEqual(result.status, 0, result.stderr)
                let files = try FileManager.default.contentsOfDirectory(atPath: output.path)
                XCTAssertEqual(Set(files), Set(["ontology.dot", "ontology.\(format)"]))
            }
        }
    }

    func testRendererFailurePreservesPreviousArtifactsEvenAfterFirstFormatSucceeded() throws {
        try inTemporaryDirectory { temp in
            let output = temp.appendingPathComponent("previous")
            try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
            let names = ["ontology.dot", "ontology.svg", "ontology.png"]
            for name in names { try Data("previous \(name)".utf8).write(to: output.appendingPathComponent(name)) }
            let renderer = temp.appendingPathComponent("fake dot")
            try """
            #!/bin/sh
            case "$1" in
              -Tsvg) printf '<svg/>' > "$3" ;;
              *) printf 'synthetic PNG failure' >&2; exit 9 ;;
            esac
            """.write(to: renderer, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: renderer.path)
            let result = try run([example.path, "--out", output.path, "--dot", renderer.path])
            XCTAssertEqual(result.status, 1)
            XCTAssertTrue(result.stderr.contains("synthetic PNG failure"))
            for name in names {
                XCTAssertEqual(try String(contentsOf: output.appendingPathComponent(name), encoding: .utf8), "previous \(name)")
            }
        }
    }

    func testMissingRendererAndInvalidPackageCreateNoOutput() throws {
        try inTemporaryDirectory { temp in
            for arguments in [
                [example.path], [example.path, "--dot", temp.appendingPathComponent("missing").path],
                [temp.appendingPathComponent("missing.yaml").path, "--format", "dot"]
            ] {
                let output = temp.appendingPathComponent(UUID().uuidString)
                let result = try run(arguments + ["--out", output.path], path: "")
                XCTAssertEqual(result.status, 1, result.stderr)
                XCTAssertFalse(FileManager.default.fileExists(atPath: output.path))
            }
        }
    }

    func testOutputCannotOverwriteItsSourcePackage() throws {
        try inTemporaryDirectory { output in
            let source = output.appendingPathComponent("ontology.dot")
            let original = try Data(contentsOf: example)
            try original.write(to: source)
            let result = try run([source.path, "--out", output.path, "--format", "dot"])
            XCTAssertEqual(result.status, 1)
            XCTAssertTrue(result.stderr.contains("overwrite input"))
            XCTAssertEqual(try Data(contentsOf: source), original)
        }
    }

    private func graphvizExecutable() throws -> URL {
        let searchPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        let urls = searchPath.split(separator: ":").map { URL(fileURLWithPath: String($0)).appendingPathComponent("dot") }
        return try XCTUnwrap(urls.first { FileManager.default.isExecutableFile(atPath: $0.path) }, "Install Graphviz for real rendering tests")
    }

    private func run(_ arguments: [String], path: String? = nil) throws -> (status: Int32, stdout: String, stderr: String) {
        try inTemporaryDirectory { temp in
            let stdout = temp.appendingPathComponent("stdout")
            let stderr = temp.appendingPathComponent("stderr")
            try Data().write(to: stdout)
            try Data().write(to: stderr)
            let outHandle = try FileHandle(forWritingTo: stdout)
            let errHandle = try FileHandle(forWritingTo: stderr)
            defer {
                try? outHandle.close()
                try? errHandle.close()
            }
            let process = Process()
            process.executableURL = try ontologycTestBinary(in: root).deletingLastPathComponent().appendingPathComponent("ontologyviz")
            process.arguments = arguments
            process.currentDirectoryURL = root
            var environment = ProcessInfo.processInfo.environment
            if let path { environment["PATH"] = path }
            process.environment = environment
            process.standardOutput = outHandle
            process.standardError = errHandle
            try process.run()
            process.waitUntilExit()
            return (process.terminationStatus, try String(contentsOf: stdout, encoding: .utf8),
                    try String(contentsOf: stderr, encoding: .utf8))
        }
    }

    private func inTemporaryDirectory<Result>(_ body: (URL) throws -> Result) throws -> Result {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("ontologyviz-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url) }
        return try body(url)
    }

    private var example: URL { root.appendingPathComponent("Examples/package-visualization/domain-ontology-package.yaml") }

    private var root: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
}
