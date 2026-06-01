import Foundation

typealias JSONObject = [String: Any]

public struct Diagnostic: Encodable, Sendable {
    let code: String
    let severity: String
    let path: String
    let message: String
    let hint: String?
}

struct LoadedPackage {
    let path: String
    let source: String
    let root: JSONObject
    let metadata: JSONObject
    let spec: JSONObject
    let id: String
    let namespace: String
    let version: String
}
