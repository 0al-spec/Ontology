import Foundation
import OntologyRules

/// Adds verified instance fields for SDK emission without changing the source IR.
struct TypeScriptInheritance {
    let compiler: OntologyCompiler
    let packages: [SDKPackage]

    init(compiler: OntologyCompiler, root: LoadedPackage, imports: [LoadedPackage], rootIR: JSONObject) {
        self.compiler = compiler
        let sources = [root] + imports.filter { $0.path != root.path }
        packages = sources.map { source in
            let ir = source.path == root.path ? rootIR : compiler.normalize(source, suppliedImports: sources.filter { $0.path != source.path })
            return SDKPackage(source: source, ir: ir)
        }
    }

    func project(_ ir: JSONObject) -> JSONObject {
        guard let root = packages.first else { return ir }
        var projected = ir
        var warnings = Set<String>()
        projected["classes"] = root.classes.keys.sorted().compactMap { name -> JSONObject? in
            guard var item = root.classes[name] else { return nil }
            var inherited = fields(of: name, in: root, visiting: [], warnings: &warnings)
            let protocols = localProtocols(of: name, in: root, visiting: [])
            if !protocols.isEmpty { item["implements"] = protocols }
            inherited = addProtocolFields(protocols, to: inherited, in: root, className: name)
            if !inherited.isEmpty { item["fields"] = inherited }
            if let foundation = foundationBase(of: name, in: root, visiting: []) {
                item["sdkFoundationBase"] = foundation
            }
            return item
        }
        if !warnings.isEmpty { projected["sdkInheritanceWarnings"] = warnings.sorted() }
        return projected
    }

    private func addProtocolFields(_ refs: [String], to fields: [JSONObject], in package: SDKPackage, className: String) -> [JSONObject] {
        var result = fields
        for ref in refs {
            for name in package.protocolFields[ref] ?? [] {
                let required: JSONObject = ["id": name, "type": "string", "required": true]
                if let existing = result.first(where: { $0["id"] as? String == name }) {
                    if !CompatibleInheritedFieldSpec().isSatisfiedBy((signature(existing), signature(required))) {
                        compiler.add("class.inheritance.protocol_field_conflict", "spec.classes.\(className).fields.\(name)",
                                     "Protocol field \(name) conflicts with the declared instance field")
                    }
                } else {
                    result.append(required)
                }
            }
        }
        return result.sorted { ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "") }
    }

    private func foundationBase(of name: String, in package: SDKPackage, visiting: Set<String>) -> String? {
        let key = "\(package.id)@\(package.version):\(name)"
        guard !visiting.contains(key), let item = package.classes[name],
              let base = item["extends"] as? String else { return nil }
        let parts = base.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        var next = visiting
        next.insert(key)
        if parts[0] == package.namespace {
            return foundationBase(of: parts[1], in: package, visiting: next)
        }
        guard let binding = package.imports.first(where: {
            ontologyImportNamespace(packageID: $0["id"] as? String, explicit: $0["namespace"] as? String) == parts[0]
        }), let id = binding["id"] as? String, let version = binding["version"] as? String else { return nil }
        if FoundationExports.catalog(packageID: id, version: version) != nil {
            return "ontology://\(id)/\(version)/classes/\(parts[1])"
        }
        guard let parent = packages.first(where: { $0.id == id && $0.version == version }) else { return nil }
        return foundationBase(of: parts[1], in: parent, visiting: next)
    }

    private func localProtocols(of name: String, in package: SDKPackage, visiting: Set<String>) -> [String] {
        guard !visiting.contains(name), let item = package.classes[name] else { return [] }
        var next = visiting
        next.insert(name)
        var refs = item["implements"] as? [String] ?? []
        if let base = item["extends"] as? String {
            let parts = base.split(separator: ":", maxSplits: 1).map(String.init)
            if parts.count == 2, parts[0] == package.namespace {
                refs += localProtocols(of: parts[1], in: package, visiting: next)
            }
        }
        return Array(Set(refs)).sorted()
    }

    private func fields(of name: String, in package: SDKPackage, visiting: Set<String>, warnings: inout Set<String>) -> [JSONObject] {
        let key = "\(package.id)@\(package.version):\(name)"
        let acyclic = AcyclicInheritanceSpec().isSatisfiedBy(.init(candidate: key, visited: visiting))
        guard acyclic else {
            compiler.add("class.inheritance.cycle", "spec.classes.\(name).extends", "Class inheritance contains a cycle at \(key)")
            return []
        }
        guard let item = package.classes[name] else {
            compiler.add("class.extends.unresolved", "spec.classes.\(name)", "Class \(key) is absent from the supplied package")
            return []
        }
        if (package.id != packages.first?.id || package.version != packages.first?.version),
           let protocols = item["implements"] as? [String], !protocols.isEmpty {
            let message = "Unverified inherited protocol obligations from \(key): \(protocols.sorted().joined(separator: ", "))"
            if warnings.insert(message).inserted {
                compiler.warn("sdk.inheritance.protocol_unavailable", "spec.classes", message)
            }
        }
        var next = visiting
        next.insert(key)
        var inherited = parentFields(item, package: package, visiting: next, warnings: &warnings)
        let own = item["fields"] as? [JSONObject] ?? []
        for var field in own {
            if package.id != packages.first?.id || package.version != packages.first?.version {
                if field["type"] as? String == "ref", field["targetType"] == nil,
                   let target = field["target"] as? String {
                    field["targetType"] = target
                }
            }
            let fieldID = field["id"] as? String ?? ""
            validateReference(field, owner: package, className: name, fieldID: fieldID)
            if let previous = inherited.first(where: { $0["id"] as? String == fieldID }) {
                if !CompatibleInheritedFieldSpec().isSatisfiedBy((signature(previous), signature(field))) {
                    compiler.add("class.inheritance.field_conflict", "spec.classes.\(name).fields.\(fieldID)",
                                 "Inherited field \(fieldID) has an incompatible type or requiredness")
                }
            } else {
                inherited.append(field)
            }
        }
        return inherited.sorted { ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "") }
    }

    private func validateReference(_ field: JSONObject, owner: SDKPackage, className: String, fieldID: String) {
        guard field["type"] as? String == "ref",
              let target = (field["targetType"] as? String) ?? (field["target"] as? String) else { return }
        let parts = target.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let candidates = Set(packages.filter { $0.namespace == parts[0] && $0.classes[parts[1]] != nil }.map {
            "ontology://\($0.id)/\($0.version)/classes/\(parts[1])"
        })
        let expected = (field["targetUri"] as? String) ?? "ontology://\(owner.id)/\(owner.version)/classes/\(parts[1])"
        let context = RuntimeReferenceIdentityContext(expectedURI: expected, candidateURIs: candidates)
        if !UnambiguousRuntimeReferenceSpec().isSatisfiedBy(context) {
            compiler.add("class.field.target.namespace_conflict", "spec.classes.\(className).fields.\(fieldID).target",
                         "Reference target \(target) does not uniquely identify \(expected) among supplied packages")
        }
    }

    private func parentFields(_ item: JSONObject, package: SDKPackage, visiting: Set<String>, warnings: inout Set<String>) -> [JSONObject] {
        guard let base = item["extends"] as? String else { return [] }
        let parts = base.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return [] }
        let alias = parts[0]
        let name = parts[1]
        if alias == package.namespace {
            return fields(of: name, in: package, visiting: visiting, warnings: &warnings)
        }
        guard let binding = package.imports.first(where: {
            ontologyImportNamespace(packageID: $0["id"] as? String, explicit: $0["namespace"] as? String) == alias
        }), let id = binding["id"] as? String, let version = binding["version"] as? String else { return [] }
        if FoundationExports.catalog(packageID: id, version: version) != nil { return [] }
        guard let parent = packages.first(where: { $0.id == id && $0.version == version }) else {
            let message = "Unverified inherited fields from \(id)@\(version):\(name); supply its source with --import"
            if warnings.insert(message).inserted {
                compiler.warn("sdk.inheritance.source_unavailable", "spec.classes", message)
            }
            return []
        }
        return fields(of: name, in: parent, visiting: visiting, warnings: &warnings)
    }

    private func signature(_ field: JSONObject) -> InheritedFieldSignature {
        InheritedFieldSignature(type: field["type"] as? String, required: field["required"] as? Bool ?? false,
                                target: (field["targetType"] as? String) ?? (field["target"] as? String))
    }
}

struct SDKPackage {
    let id: String
    let version: String
    let namespace: String
    let imports: [JSONObject]
    let classes: [String: JSONObject]
    let protocolFields: [String: [String]]

    init(source: LoadedPackage, ir: JSONObject) {
        id = source.id
        version = source.version
        namespace = source.namespace
        imports = ir["imports"] as? [JSONObject] ?? []
        classes = Dictionary(uniqueKeysWithValues: (ir["classes"] as? [JSONObject] ?? []).compactMap { item in
            guard let name = item["id"] as? String else { return nil }
            return (name, item)
        })
        protocolFields = Dictionary(uniqueKeysWithValues: (ir["protocols"] as? [JSONObject] ?? []).compactMap { item in
            guard let ref = item["fqid"] as? String else { return nil }
            return (ref, item["requiredFields"] as? [String] ?? [])
        })
    }
}
