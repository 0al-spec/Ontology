import CryptoKit
import Foundation
import OntologyRules
import Yams

extension OntologyCompiler {
    func scanUnsafeSource(_ source: String, filePath: String) {
        let unsafeTag = UnsafeYamlTagSpec()
        let executableValue = ExecutableLookingYamlValueSpec()
        for (lineIndex, line) in source.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let lineText = String(line)
            if unsafeTag.isSatisfiedBy(YamlSourceLine(rawValue: lineText)) ||
                executableValue.isSatisfiedBy(YamlScalarText(rawValue: lineText)) {
                add("security.executable_content", "\(filePath):\(lineIndex + 1)", "YAML contains executable-looking content")
            }
        }
    }

    func scanUnsafeNode(_ value: Any, path: String) {
        let unsafeKey = UnsafeYamlKeySpec()
        let executableValue = ExecutableLookingYamlValueSpec()
        if let object = value as? JSONObject {
            for key in object.keys.sorted() {
                if unsafeKey.isSatisfiedBy(YamlMappingKey(rawValue: key)) {
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
                  executableValue.isSatisfiedBy(YamlScalarText(rawValue: scalar)) {
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

    func validate(_ value: String, path: String, code: String, isSatisfied: (String) -> Bool) {
        if !value.isEmpty && !isSatisfied(value) {
            add(code, path, "\(path) has invalid format")
        }
    }

    func validateSymbolName(_ value: String, path: String, code: String) {
        validate(value, path: path, code: code) {
            OntologySymbolNameSpec().isSatisfiedBy(OntologySymbolName(rawValue: $0))
        }
    }

    func validateStateName(_ value: String, path: String, code: String) {
        validate(value, path: path, code: code) {
            OntologyStateNameSpec().isSatisfiedBy(OntologyStateName(rawValue: $0))
        }
    }

    func add(_ code: String, _ path: String, _ message: String, hint: String? = nil) {
        diagnostics.append(Diagnostic(code: code, severity: "error", path: path, message: message, hint: hint))
    }

    func warn(_ code: String, _ path: String, _ message: String, hint: String? = nil) {
        diagnostics.append(Diagnostic(code: code, severity: "warning", path: path, message: message, hint: hint))
    }

    func string(_ value: Any?) -> String? {
        value as? String
    }

    func relationRangeRefs(_ value: Any) -> [String] {
        switch RelationRangeShapeDecisionSpec().decide(value) {
        case .scalarRef(let ref):
            return [ref]
        case .oneOfRefs(let refs):
            return refs
        case .invalid, nil:
            return []
        }
    }

    func normalizeRange(_ value: Any?, namespace: String) -> Any {
        guard let value else { return "" }
        switch RelationRangeShapeDecisionSpec().decide(value) {
        case .scalarRef(let ref):
            return normalizeRef(ref, namespace: namespace)
        case .oneOfRefs(let refs):
            return ["oneOf": refs.map { normalizeRef($0, namespace: namespace) }.sorted()]
        case .invalid, nil:
            return ""
        }
    }

    func resolves(_ ref: String, localNames: Set<String>, packageNamespace: String, importNamespaces: Set<String>) -> Bool {
        let context = ConceptRefResolutionContext(
            ref: ref,
            localNames: localNames,
            packageNamespace: packageNamespace,
            importNamespaces: importNamespaces
        )
        return ConceptRefResolutionDecisionSpec().decide(context)?.resolves == true
    }

    func isLocalTrigger(_ ref: String, names: Set<String>, packageNamespace: String) -> Bool {
        let context = TriggerRefResolutionContext(ref: ref, names: names, packageNamespace: packageNamespace)
        return LocalTriggerRefSpec().isSatisfiedBy(context)
    }

    func normalizeRef(_ ref: String, namespace: String) -> String {
        ref.contains(":") ? ref : "\(namespace):\(ref)"
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
        guard let jsonText = String(data: data, encoding: .utf8) else {
            throw OntologyCompilerError.invalidArgument("Could not encode JSON as UTF-8")
        }
        let text = jsonText + "\n"
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
        do {
            let data = try JSONSerialization.data(
                withJSONObject: value,
                options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            )
            guard let text = String(data: data, encoding: .utf8) else {
                preconditionFailure("JSON serialization produced non-UTF-8 data")
            }
            return text
        } catch {
            preconditionFailure("Invalid JSON value passed to TypeScript emitter: \(error)")
        }
    }

    func matches(_ value: String, _ pattern: String, caseInsensitive: Bool = false) -> Bool {
        var options: String.CompareOptions = [.regularExpression]
        if caseInsensitive {
            options.insert(.caseInsensitive)
        }
        return value.range(of: pattern, options: options) != nil
    }
}
