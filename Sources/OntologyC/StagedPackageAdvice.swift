import Foundation
import OntologyCompiler

private func gitOutput(_ arguments: [String]) throws -> Data {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = ["git"] + arguments
    var environment = ProcessInfo.processInfo.environment
    environment["GIT_NO_LAZY_FETCH"] = "1"
    process.environment = environment
    process.standardInput = FileHandle.nullDevice
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let bytes = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
        throw OntologyCompilerError.invalidArgument("git \(arguments[0]) exited \(process.terminationStatus)")
    }
    return bytes
}

private struct StagedYAML {
    let path: String
    let blob: String
    let previousBlob: String?

    init?(header: Data.SubSequence, path: Data.SubSequence) {
        // --raw --no-renames -z gives one mode/OID/status header and one path per entry.
        let fields = String(decoding: header, as: UTF8.self).split(separator: " ")
        guard fields.count == 5, fields[1].hasPrefix("100") else { return nil }
        self.path = String(decoding: path, as: UTF8.self)
        blob = String(fields[3])
        previousBlob = fields[0].hasPrefix(":100") ? String(fields[2]) : nil
    }

    var hasPackageFilename: Bool {
        let stem = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent.lowercased()
        return stem == "domain-ontology-package" || stem == "domain-ontology-package-draft" || stem.hasSuffix(".ontology")
    }

    private func readSource(_ oid: String) throws -> String? {
        let sizeText = try String(decoding: gitOutput(["cat-file", "-s", oid]), as: UTF8.self)
        guard let size = Int(sizeText.trimmingCharacters(in: .whitespacesAndNewlines)), size <= 4 * 1024 * 1024 else {
            throw OntologyCompilerError.invalidArgument("blob exceeds the 4 MiB advisory limit; use ontologyc check for the full file")
        }
        return try String(data: gitOutput(["cat-file", "blob", oid]), encoding: .utf8)
    }

    func report(using compiler: OntologyCompiler) throws {
        let source = try readSource(blob)
        if !hasPackageFilename, !(source.map(compiler.declaresPackage) ?? false) {
            guard let previousBlob,
                  let previous = try readSource(previousBlob),
                  compiler.declaresPackage(previous) else { return }
        }
        guard let source else {
            writeDiagnostic("[ontology advice] \(path.debugDescription) could not be checked: expected UTF-8 YAML\n")
            return
        }
        for finding in compiler.check(source: source, path: OntologySourcePath(path: path)) {
            writeDiagnostic("[ontology advice] \(path.debugDescription) \(finding.severity) \(finding.code) at \(finding.path.debugDescription): \(finding.message.debugDescription)\n")
        }
    }
}

func runStagedPackageAdvice(_ compiler: OntologyCompiler) {
    do {
        let diff = try gitOutput([
            "diff", "--cached", "--raw", "--no-abbrev", "--no-renames", "--no-ext-diff", "--no-textconv",
            "--no-color", "--no-relative", "--ignore-submodules=all", "--diff-filter=AMT", "-z", "--",
            ":(top,icase,glob)**/*.yaml", ":(top,icase,glob)**/*.yml"
        ])
        let records = diff.split(separator: 0)
        var entries = records.makeIterator()
        while let header = entries.next(), let path = entries.next() {
            guard let file = StagedYAML(header: header, path: path) else { continue }
            do {
                try file.report(using: compiler)
            } catch {
                writeDiagnostic("[ontology advice] \(file.path.debugDescription) could not be checked: \(error)\n")
            }
        }
    } catch {
        writeDiagnostic("[ontology advice] staged packages could not be checked: \(error)\n")
    }
}
