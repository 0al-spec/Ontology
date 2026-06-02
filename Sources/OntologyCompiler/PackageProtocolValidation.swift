import Foundation
import OntologyRules

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
                allowed: ["description", "requiredFields", "requiredRelations", "semanticConstraints"],
                path: path
            )
            _ = requiredString(definition, "description", path: "\(path).description", code: "protocol.description.required")
            validateProtocolNameList(definition, key: "requiredFields", path: path, code: "protocol.field.name.invalid")
            validateProtocolNameList(definition, key: "requiredRelations", path: path, code: "protocol.relation.name.invalid")
        }
    }

    func validateProtocolConformance(
        classes: JSONObject,
        protocols: JSONObject,
        relations: JSONObject,
        packageNamespace: String
    ) {
        let relationDomains = classRelationDomains(relations)
        for (className, value) in classes {
            guard let definition = value as? JSONObject,
                  let implementsList = definition["implements"] as? [Any] else { continue }
            let domains = relationDomains[className] ?? []
            for refValue in implementsList {
                guard let protoName = localProtocolName(refValue, packageNamespace: packageNamespace),
                      let protoDef = protocols[protoName] as? JSONObject else { continue }
                validateRequiredProtocolFields(protoDef, protoName: protoName, className: className, domains: domains)
                validateRequiredProtocolRelations(protoDef, protoName: protoName, className: className, domains: domains)
            }
        }
    }

    private func validateProtocolNameList(_ definition: JSONObject, key: String, path: String, code: String) {
        for (index, value) in (definition[key] as? [Any] ?? []).enumerated() {
            guard let name = string(value) else { continue }
            validateSymbolName(name, path: "\(path).\(key)[\(index)]", code: code)
        }
    }

    private func classRelationDomains(_ relations: JSONObject) -> [String: Set<String>] {
        var domains: [String: Set<String>] = [:]
        for (relationName, value) in relations {
            guard let definition = value as? JSONObject,
                  let domain = string(definition["domain"]) else { continue }
            domains[refName(domain), default: []].insert(relationName)
        }
        return domains
    }

    private func localProtocolName(_ refValue: Any, packageNamespace: String) -> String? {
        guard let ref = string(refValue) else { return nil }
        let parts = ref.split(separator: ":", maxSplits: 1)
        if parts.count == 2 {
            return String(parts[0]) == packageNamespace ? String(parts[1]) : nil
        }
        return ref
    }

    private func validateRequiredProtocolFields(
        _ protoDef: JSONObject,
        protoName: String,
        className: String,
        domains: Set<String>
    ) {
        for req in (protoDef["requiredFields"] as? [Any] ?? []).compactMap({ string($0) }) where !domains.contains(req) {
            add(
                "protocol.field.missing",
                "spec.classes.\(className).implements",
                "Class \(className) implements \(protoName) but is missing required field \(req)"
            )
        }
    }

    private func validateRequiredProtocolRelations(
        _ protoDef: JSONObject,
        protoName: String,
        className: String,
        domains: Set<String>
    ) {
        let required = (protoDef["requiredRelations"] as? [Any] ?? []).compactMap { string($0) }
        let context = ProtocolConformanceContext(protocolRequiredRelations: required, classRelationDomains: domains)
        guard !ProtocolRelationConformanceSpec().isSatisfiedBy(context) else { return }
        for req in required where !domains.contains(req) {
            add(
                "protocol.relation.missing",
                "spec.classes.\(className).implements",
                "Class \(className) implements \(protoName) but is missing required relation \(req)"
            )
        }
    }
}
