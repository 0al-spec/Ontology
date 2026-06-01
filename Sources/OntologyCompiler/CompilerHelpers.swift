import CryptoKit
import Foundation
import Yams

extension OntologyCompiler {
    func scanUnsafeSource(_ source: String, filePath: String) {
        for (lineIndex, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineText = String(line)
            if matches(lineText, unsafeTagPattern, caseInsensitive: true) ||
                unsafeValuePatterns.contains(where: { matches(lineText, $0) }) {
                add("security.executable_content", "\(filePath):\(lineIndex + 1)", "YAML contains executable-looking content")
            }
        }
    }

    func scanUnsafeNode(_ value: Any, path: String) {
        if let object = value as? JSONObject {
            for key in object.keys.sorted() {
                if unsafeKeys.contains(key.lowercased()) {
                    add("security.executable_content", "\(path).\(key)", "YAML contains executable-looking key")
                }
                if let child = object[key] {
                    scanUnsafeNode(child, path: "\(path).\(key)")
                }
            }
        } else if let array = value as? [Any] {
            for (index, child) in array.enumerated() {
                scanUnsafeNode(child, path: "\(path)[\(index)]")
            }
        } else if let scalar = value as? String,
                  unsafeValuePatterns.contains(where: { matches(scalar, $0) }) {
            add("security.executable_content", path, "YAML contains executable-looking string")
        }
    }

    func validateKnownKeys(_ object: JSONObject, allowed: Set<String>, path: String) {
        for key in object.keys.sorted() where !allowed.contains(key) {
            add("object.unknown_key", "\(path).\(key)", "Unknown key \(key)")
        }
    }

    func validateKnownKeys(_ object: JSONObject, allowed: [String], path: String) {
        validateKnownKeys(object, allowed: Set(allowed), path: path)
    }

    func requiredString(_ object: JSONObject, _ key: String, path: String, code: String) -> String? {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return nil
        }
        guard let value = string(object[key]), !value.isEmpty else {
            add("\(code).type", path, "\(path) must be a non-empty string")
            return nil
        }
        return value
    }

    func requiredArray(_ object: JSONObject, _ key: String, path: String, code: String) -> [Any] {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return []
        }
        guard let value = object[key] as? [Any] else {
            add("\(code).type", path, "\(path) must be an array")
            return []
        }
        return value
    }

    func requiredObject(_ object: JSONObject, _ key: String, path: String, code: String) -> JSONObject? {
        guard object.keys.contains(key) else {
            add(code, path, "\(path) is required")
            return nil
        }
        guard let value = object[key] as? JSONObject else {
            add("\(code).type", path, "\(path) must be an object")
            return nil
        }
        return value
    }

    func validatePattern(_ value: String, _ pattern: String, path: String, code: String) {
        if !value.isEmpty && !matches(value, pattern) {
            add(code, path, "\(path) has invalid format")
        }
    }

    func add(_ code: String, _ path: String, _ message: String, hint: String? = nil) {
        diagnostics.append(Diagnostic(code: code, severity: "error", path: path, message: message, hint: hint))
    }

    func string(_ value: Any?) -> String? {
        value as? String
    }

    func relationRangeRefs(_ value: Any) -> [String] {
        if let ref = string(value) {
            return [ref]
        }
        if let object = value as? JSONObject,
           let oneOf = object["oneOf"] as? [Any] {
            return oneOf.compactMap { string($0) }
        }
        return []
    }

    func normalizeRange(_ value: Any?, namespace: String) -> Any {
        guard let value else { return "" }
        if let ref = string(value) {
            return normalizeRef(ref, namespace: namespace)
        }
        if let object = value as? JSONObject,
           let oneOf = object["oneOf"] as? [Any] {
            return ["oneOf": oneOf.compactMap { string($0) }.map { normalizeRef($0, namespace: namespace) }.sorted()]
        }
        return ""
    }

    func resolves(_ ref: String, localNames: Set<String>, packageNamespace: String, importNamespaces: Set<String>) -> Bool {
        guard matches(ref, conceptPattern) else { return false }
        return isImported(ref, importNamespaces) || isLocal(ref, localNames: localNames, packageNamespace: packageNamespace)
    }

    func isImported(_ ref: String, _ importNamespaces: Set<String>) -> Bool {
        guard let namespace = refNamespace(ref) else { return false }
        return importNamespaces.contains(namespace)
    }

    func isLocal(_ ref: String, localNames: Set<String>, packageNamespace: String) -> Bool {
        if let namespace = refNamespace(ref) {
            return namespace == packageNamespace && localNames.contains(refName(ref))
        }
        return localNames.contains(ref)
    }

    func isLocalTrigger(_ ref: String, names: Set<String>, packageNamespace: String) -> Bool {
        if let namespace = refNamespace(ref), namespace != packageNamespace {
            return false
        }
        return names.contains(refName(ref))
    }

    func normalizeRef(_ ref: String, namespace: String) -> String {
        ref.contains(":") ? ref : "\(namespace):\(ref)"
    }

    func refNamespace(_ ref: String) -> String? {
        ref.split(separator: ":", maxSplits: 1).count == 2 ? String(ref.split(separator: ":", maxSplits: 1)[0]) : nil
    }

    func refName(_ ref: String) -> String {
        let parts = ref.split(separator: ":", maxSplits: 1)
        return String(parts.count == 2 ? parts[1] : parts[0])
    }

    func transitionSortKey(_ transition: JSONObject) -> String {
        [
            string(transition["from"]) ?? "",
            string(transition["to"]) ?? "",
            string(transition["command"]) ?? "",
            string(transition["event"]) ?? ""
        ].joined(separator: "\u{1f}")
    }

    func sha256(_ source: String) -> String {
        let digest = SHA256.hash(data: Data(source.utf8))
        return "sha256:" + digest.map { String(format: "%02x", $0) }.joined()
    }

    func write(json: Any, to url: URL) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        let text = String(data: data, encoding: .utf8)! + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func writeYAML(_ object: Any, to url: URL) throws {
        let text = try Yams.dump(object: object) + "\n"
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func write(text: String, to url: URL) throws {
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    func tsObject(_ object: JSONObject) -> String {
        jsonText(object)
    }

    func tsArray(_ array: [Any]) -> String {
        jsonText(array)
    }

    func jsonText(_ value: Any) -> String {
        let data = try! JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes])
        return String(data: data, encoding: .utf8)!
    }

    func matches(_ value: String, _ pattern: String, caseInsensitive: Bool = false) -> Bool {
        var options: String.CompareOptions = [.regularExpression]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }
        return value.range(of: pattern, options: options) != nil
    }
}
