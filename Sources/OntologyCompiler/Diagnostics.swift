import Foundation
import OntologyRules

typealias JSONObject = [String: Any]

/// One validation, compatibility, registry, or compiler diagnostic emitted by `OntologyCompiler`.
public struct Diagnostic: Encodable, Sendable {
    /// Stable machine-readable diagnostic code.
    public let code: String
    /// Diagnostic severity, currently `error` or `warning`.
    public let severity: String
    /// Source path or logical package path where the diagnostic applies.
    public let path: String
    /// Human-readable explanation of the problem.
    public let message: String
    /// Optional remediation hint.
    public let hint: String?
}

struct LoadedPackageMetadata {
    let id: OntologyPackageId
    let namespace: OntologyNamespace
    let version: OntologySemanticVersion
}

struct LoadedPackage {
    let path: String
    let source: String
    let root: JSONObject
    let metadata: JSONObject
    let spec: JSONObject
    let packageMetadata: LoadedPackageMetadata

    var id: String { packageMetadata.id.rawValue }
    var namespace: String { packageMetadata.namespace.rawValue }
    var version: String { packageMetadata.version.rawValue }
}
