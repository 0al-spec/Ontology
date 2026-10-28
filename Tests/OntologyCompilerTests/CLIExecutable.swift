import Foundation

func ontologycTestBinary(in root: URL) throws -> URL {
    guard let configured = ProcessInfo.processInfo.environment["ONTOLOGYC_TEST_BINARY_PATH"] else {
        return root.appendingPathComponent(".build/debug/ontologyc")
    }
    let binary = URL(fileURLWithPath: configured, relativeTo: root).standardizedFileURL
    guard FileManager.default.isExecutableFile(atPath: binary.path) else {
        throw UnavailableCLIExecutable(path: binary.path)
    }
    return binary
}

private struct UnavailableCLIExecutable: Error, CustomStringConvertible {
    let path: String
    var description: String { "Configured ontologyc is unavailable or not executable: \(path)" }
}
