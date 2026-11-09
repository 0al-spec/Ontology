import Foundation

extension OntologyCompiler {
    func validateProtocols(_ protocols: JSONObject) {
        for name in protocols.keys.sorted() {
            let path = "spec.protocols.\(name)"
            validateSymbolName(name, path: path, code: "protocol.name.invalid")
            guard let definition = protocols[name] as? JSONObject else {
                add("protocol.type", path, "Protocol definition must be an object")
                continue
            }
            validateKnownKeys(
                definition,
                allowed: ["description", "requiredFields", "requiredRelations", "semanticConstraints", "layer"],
                path: path
            )
            validateLayer(definition, path: path)
            _ = requiredString(definition, "description", path: "\(path).description", code: "protocol.description.required")
            validateProtocolNameList(definition, key: "requiredFields", path: path, code: "protocol.field.name.invalid")
            validateProtocolNameList(definition, key: "requiredRelations", path: path, code: "protocol.relation.name.invalid")
        }
    }

    private func validateProtocolNameList(_ definition: JSONObject, key: String, path: String, code: String) {
        for (index, value) in (definition[key] as? [Any] ?? []).enumerated() {
            guard let name = string(value) else { continue }
            validateSymbolName(name, path: "\(path).\(key)[\(index)]", code: code)
        }
    }
}
