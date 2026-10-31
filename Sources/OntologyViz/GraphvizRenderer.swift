import Foundation

struct GraphvizRenderer {
    private let fileManager = FileManager.default

    func writeJSON(_ json: String, arguments: VizArguments) throws -> [String] {
        let staging = fileManager.temporaryDirectory.appendingPathComponent("ontologyviz-\(UUID().uuidString)")
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }
        let name = "ontology.graph.json"
        try json.write(to: staging.appendingPathComponent(name), atomically: true, encoding: .utf8)
        try publish([name], from: staging, arguments: arguments)
        return [name]
    }

    func render(dot: String, arguments: VizArguments) throws -> [String] {
        let formats = arguments.format.renderedFormats
        let executable = try formats.isEmpty ? nil : resolveExecutable(arguments.dotPath)
        let staging = fileManager.temporaryDirectory.appendingPathComponent("ontologyviz-\(UUID().uuidString)")
        try fileManager.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: staging) }
        let source = staging.appendingPathComponent("ontology.dot")
        try dot.write(to: source, atomically: true, encoding: .utf8)
        if let executable {
            for format in formats {
                try run(executable, source: source, format: format, directory: staging)
            }
        }
        let names = ["ontology.dot"] + formats.map { "ontology.\($0)" }
        try publish(names, from: staging, arguments: arguments)
        return names
    }

    private func resolveExecutable(_ explicit: String?) throws -> URL {
        if let explicit {
            let url = URL(fileURLWithPath: explicit)
            guard fileManager.isExecutableFile(atPath: url.path) else {
                throw VizFailure(description: "Graphviz dot is not executable at \(url.path)")
            }
            return url
        }
        let searchPath = ProcessInfo.processInfo.environment["PATH"] ?? ""
        for directory in searchPath.split(separator: ":", omittingEmptySubsequences: false) {
            let url = URL(fileURLWithPath: directory.isEmpty ? "." : String(directory)).appendingPathComponent("dot")
            if fileManager.isExecutableFile(atPath: url.path) { return url }
        }
        throw VizFailure(description: "Graphviz dot was not found in PATH. Install graphviz or use --dot; --format dot needs no renderer.")
    }

    private func run(_ executable: URL, source: URL, format: String, directory: URL) throws {
        let output = directory.appendingPathComponent("ontology.\(format)")
        let errorFile = directory.appendingPathComponent("renderer.stderr")
        try Data().write(to: errorFile)
        let errorHandle = try FileHandle(forWritingTo: errorFile)
        defer { try? errorHandle.close() }
        let process = Process()
        process.executableURL = executable
        process.arguments = ["-T\(format)", "-o", output.path, source.path]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = errorHandle
        try process.run()
        process.waitUntilExit()
        let stderr = try String(contentsOf: errorFile, encoding: .utf8)
        guard process.terminationStatus == 0 else {
            throw VizFailure(description: "Graphviz \(format) failed (exit \(process.terminationStatus)): \(stderr)")
        }
        let data = try Data(contentsOf: output)
        guard !data.isEmpty else { throw VizFailure(description: "Graphviz returned an empty \(format) artifact") }
    }

    private func publish(_ names: [String], from staging: URL, arguments: VizArguments) throws {
        let sources = arguments.sourceURLs.map { $0.resolvingSymlinksInPath().standardizedFileURL }
        for name in names {
            let target = arguments.output.appendingPathComponent(name).resolvingSymlinksInPath().standardizedFileURL
            guard !sources.contains(target) else { throw VizFailure(description: "Output would overwrite input package \(target.path)") }
        }
        let artifacts = try names.map { try Data(contentsOf: staging.appendingPathComponent($0)) }
        try fileManager.createDirectory(at: arguments.output, withIntermediateDirectories: true)
        for (name, data) in zip(names, artifacts) {
            try data.write(to: arguments.output.appendingPathComponent(name), options: .atomic)
        }
    }
}
