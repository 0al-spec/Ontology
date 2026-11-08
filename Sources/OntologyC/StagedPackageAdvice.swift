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

private func gitBlobSource(_ oid: String) throws -> String? {
    let sizeText = try String(decoding: gitOutput(["cat-file", "-s", oid]), as: UTF8.self)
    guard let size = Int(sizeText.trimmingCharacters(in: .whitespacesAndNewlines)), size <= 4 * 1024 * 1024 else {
        throw OntologyCompilerError.invalidArgument("blob exceeds the 4 MiB advisory limit; use ontologyc check for the full file")
    }
    return try String(data: gitOutput(["cat-file", "blob", oid]), encoding: .utf8)
}

private func stagedImport(_ path: String) throws -> OntologySourceSnapshot {
    guard !path.isEmpty, !path.hasPrefix("/"), !path.split(separator: "/").contains("..") else {
        throw OntologyCompilerError.invalidArgument("import \(path.debugDescription) must be repository-root-relative")
    }
    let data = try gitOutput(["ls-files", "--stage", "--full-name", "-z", "--", ":(top,literal)\(path)"])
    let records = data.split(separator: 0)
    guard records.count == 1, let record = records.first, let tab = record.firstIndex(of: 9) else {
        throw OntologyCompilerError.invalidArgument("import \(path.debugDescription) is missing or unmerged in the active index")
    }
    let fields = String(decoding: record[..<tab], as: UTF8.self).split(separator: " ")
    let indexedPath = String(decoding: record[record.index(after: tab)...], as: UTF8.self)
    guard fields.count == 3, fields[0].hasPrefix("100"), fields[2] == "0", indexedPath == path else {
        throw OntologyCompilerError.invalidArgument("import \(path.debugDescription) is not a resolved regular index file")
    }
    guard let source = try gitBlobSource(String(fields[1])) else {
        throw OntologyCompilerError.invalidArgument("import \(path.debugDescription) is not UTF-8")
    }
    return OntologySourceSnapshot(source: source, path: OntologySourcePath(path: path))
}

private struct StagedFindingKey: Hashable {
    let source: String
    let severity: String
    let code: String
    let location: String
    let message: String
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

    func packageSource(using compiler: OntologyCompiler) throws -> String? {
        let source = try gitBlobSource(blob)
        if !hasPackageFilename, !(source.map(compiler.declaresPackage) ?? false) {
            guard let previousBlob,
                  let previous = try gitBlobSource(previousBlob),
                  compiler.declaresPackage(previous) else { return nil }
        }
        guard let source else {
            writeDiagnostic("[ontology advice] \(path.debugDescription) could not be checked: expected UTF-8 YAML\n")
            return nil
        }
        return source
    }

    func report(_ source: String, using compiler: OntologyCompiler, imports: [OntologySourceSnapshot], seen: inout Set<StagedFindingKey>) {
        let snapshot = OntologySourceSnapshot(source: source, path: OntologySourcePath(path: path))
        for result in compiler.checkSources(source: snapshot, imports: imports) {
            let finding = result.diagnostic
            let key = StagedFindingKey(source: result.source.path, severity: finding.severity, code: finding.code,
                                       location: finding.path, message: finding.message)
            guard seen.insert(key).inserted else { continue }
            writeDiagnostic("[ontology advice] \(result.source.path.debugDescription) \(finding.severity) \(finding.code) at \(finding.path.debugDescription): \(finding.message.debugDescription)\n")
        }
    }
}

func runStagedPackageAdvice(_ compiler: OntologyCompiler, imports: [String]) {
    do {
        let diff = try gitOutput([
            "diff", "--cached", "--raw", "--no-abbrev", "--no-renames", "--no-ext-diff", "--no-textconv",
            "--no-color", "--no-relative", "--ignore-submodules=all", "--diff-filter=AMT", "-z", "--",
            ":(top,icase,glob)**/*.yaml", ":(top,icase,glob)**/*.yml"
        ])
        let records = diff.split(separator: 0)
        var entries = records.makeIterator()
        var snapshots: [OntologySourceSnapshot]?
        var seen = Set<StagedFindingKey>()
        while let header = entries.next(), let path = entries.next() {
            guard let file = StagedYAML(header: header, path: path) else { continue }
            do {
                guard let source = try file.packageSource(using: compiler) else { continue }
                if snapshots == nil { snapshots = try imports.map(stagedImport) }
                file.report(source, using: compiler, imports: snapshots ?? [], seen: &seen)
            } catch {
                writeDiagnostic("[ontology advice] \(file.path.debugDescription) could not be checked: \(error)\n")
            }
        }
    } catch {
        writeDiagnostic("[ontology advice] staged packages could not be checked: \(error)\n")
    }
}
