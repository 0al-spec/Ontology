import Foundation
import OntologyRules

/// Adds verified instance fields for SDK emission without changing the source IR.
struct TypeScriptInheritance {
    let compiler: OntologyCompiler
    let packages: [SDKPackage]
    let reachablePackages: [SDKPackage]

    init(compiler: OntologyCompiler, root: LoadedPackage, imports: [LoadedPackage], rootIR: JSONObject) {
        self.compiler = compiler
        let sources = [root] + imports.filter { $0.path != root.path }
        let available = sources.map { source in
            let ir = source.path == root.path ? rootIR : compiler.normalize(source, suppliedImports: sources.filter { $0.path != source.path })
            return SDKPackage(source: source, ir: ir)
        }
        packages = available
        reachablePackages = Self.reachablePackages(available)
    }

    private static func reachablePackages(_ packages: [SDKPackage]) -> [SDKPackage] {
        guard let root = packages.first else { return [] }
        let indexed = Dictionary(grouping: packages, by: \.identity)
        var pending = [root.identity]
        var reachable = Set<DiagramPackageIdentity>()
        while let current = pending.popLast() {
            guard reachable.insert(current).inserted else { continue }
            for package in indexed[current] ?? [] {
                for binding in package.imports {
                    guard let id = binding["id"] as? String, let version = binding["version"] as? String else { continue }
                    let identity = DiagramPackageIdentity(id: id, version: version)
                    if indexed[identity] != nil { pending.append(identity) }
                }
            }
        }
        return packages.filter {
            DiagramReachableImportSpec().isSatisfiedBy(.init(supplied: $0.identity, reachable: reachable))
        }
    }

    func project(_ ir: JSONObject) -> JSONObject {
        guard let root = packages.first else { return ir }
        var projected = ir
        var warnings = Set<String>()
        projected["classes"] = root.classes.keys.sorted().compactMap { name -> JSONObject? in
            guard var item = root.classes[name] else { return nil }
            let inherited = fields(of: name, in: root, rootClass: name, visiting: [], warnings: &warnings)
            let protocols = localProtocols(of: name, in: root, visiting: [])
            item["implements"] = verifiedProtocolRefs(protocols, fields: inherited, in: root)
            if !inherited.isEmpty { item["fields"] = inherited }
            if let foundation = foundationBase(of: name, in: root, visiting: []) {
                item["sdkFoundationBase"] = foundation
            }
            return item
        }
        if !warnings.isEmpty { projected["sdkInheritanceWarnings"] = warnings.sorted() }
        return projected
    }

    private func verifiedProtocolRefs(_ refs: [String], fields: [JSONObject], in root: SDKPackage) -> [String] {
        refs.filter { ref in
            let parts = ref.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2, parts[0] == root.namespace, let requirements = root.protocols[parts[1]] else { return true }
            let required = InheritedFieldSignature(type: "string", required: true, target: nil)
            return requirements.fields.allSatisfy { name in
                guard let field = fields.first(where: { $0["id"] as? String == name }) else { return false }
                return CompatibleInheritedFieldSpec().isSatisfiedBy((signature(field), required))
            }
        }
    }

    private func protocolRequirements(_ ref: String, owner: SDKPackage, className: String,
                                      rootClass: String, warnings: inout Set<String>) -> ProtocolRequirements? {
        let parts = ref.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        let identity: DiagramPackageIdentity
        if parts[0] == owner.namespace {
            identity = owner.identity
        } else {
            guard let binding = owner.imports.first(where: {
                ontologyImportNamespace(packageID: $0["id"] as? String, explicit: $0["namespace"] as? String) == parts[0]
            }), let id = binding["id"] as? String, let version = binding["version"] as? String else { return nil }
            identity = DiagramPackageIdentity(id: id, version: version)
        }

        let candidates = packages.map { ProtocolSourceCandidate(identity: $0.identity, protocolNames: Set($0.protocols.keys)) }
        let context = ProtocolSourceContext(identity: identity, protocolName: parts[1], candidates: candidates)
        let ownerIsRoot = owner.identity == packages.first?.identity && className == rootClass
        let location = ownerIsRoot ? "spec.classes.\(rootClass).implements" : "spec.classes.\(rootClass).extends"
        switch ProtocolSourceDecisionSpec().decide(context) {
        case .resolved:
            return packages.first(where: { $0.identity == identity })?.protocols[parts[1]]
        case .missingSource:
            let message = "Unverified protocol \(ref) on \(owner.id)@\(owner.version):\(className); supply \(identity.id.rawValue)@\(identity.version.rawValue) with --import"
            if warnings.insert("\(rootClass): \(message)").inserted {
                compiler.warn("sdk.inheritance.protocol_unavailable", location, message)
            }
        case .missingProtocol:
            compiler.add("protocol.unresolved", location, "Protocol \(ref) is absent from supplied \(identity.id.rawValue)@\(identity.version.rawValue)")
        case .ambiguousSource:
            compiler.add("imports.source.duplicate", location, "Multiple sources supplied for \(identity.id.rawValue)@\(identity.version.rawValue)")
        case nil:
            break
        }
        return nil
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

    private func fields(of name: String, in package: SDKPackage, rootClass: String, visiting: Set<String>, warnings: inout Set<String>) -> [JSONObject] {
        let key = "\(package.id)@\(package.version):\(name)"
        let acyclic = AcyclicInheritanceSpec().isSatisfiedBy(.init(candidate: key, visited: visiting))
        guard acyclic else {
            compiler.add("class.inheritance.cycle", "spec.classes.\(rootClass).extends", "Class inheritance contains a cycle at \(key)")
            return []
        }
        guard let item = package.classes[name] else {
            compiler.add("class.extends.unresolved", "spec.classes.\(rootClass).extends", "Class \(key) is absent from the supplied package")
            return []
        }
        var next = visiting
        next.insert(key)
        var inherited = parentFields(item, package: package, rootClass: rootClass, visiting: next, warnings: &warnings)
        let own = item["fields"] as? [JSONObject] ?? []
        for var field in own {
            if package.id != packages.first?.id || package.version != packages.first?.version {
                if field["type"] as? String == "ref", field["targetType"] == nil,
                   let target = field["target"] as? String {
                    field["targetType"] = target
                }
            }
            let fieldID = field["id"] as? String ?? ""
            validateReference(field, owner: package, className: name, rootClass: rootClass, fieldID: fieldID)
            if let previous = inherited.first(where: { $0["id"] as? String == fieldID }) {
                if !CompatibleInheritedFieldSpec().isSatisfiedBy((signature(previous), signature(field))) {
                    let location = fieldLocation(package: package, className: name, rootClass: rootClass, fieldID: fieldID)
                    compiler.add("class.inheritance.field_conflict", location,
                                 "Inherited field \(fieldID) in \(key) has an incompatible type or requiredness")
                }
            } else {
                inherited.append(field)
            }
        }
        for ref in item["implements"] as? [String] ?? [] {
            guard let requirements = protocolRequirements(ref, owner: package, className: name,
                                                          rootClass: rootClass, warnings: &warnings) else { continue }
            if requirements.fields.contains(where: { ProtocolBuiltinIdentitySpec().isSatisfiedBy(.init(rawValue: $0)) }),
               !inherited.contains(where: { $0["id"] as? String == "id" }) {
                inherited.append(["id": "id", "type": "string", "required": true])
            }
            let application = ProtocolApplication(reference: ref, owner: package, className: name, rootClass: rootClass)
            validateProtocolRequirements(requirements, fields: inherited, application: application, warnings: &warnings)
        }
        return inherited.sorted { ($0["id"] as? String ?? "") < ($1["id"] as? String ?? "") }
    }

    private func validateReference(_ field: JSONObject, owner: SDKPackage, className: String, rootClass: String, fieldID: String) {
        guard field["type"] as? String == "ref",
              let target = (field["targetType"] as? String) ?? (field["target"] as? String) else { return }
        let parts = target.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return }
        let candidates = Set(reachablePackages.filter { $0.namespace == parts[0] && $0.classes[parts[1]] != nil }.map {
            "ontology://\($0.id)/\($0.version)/classes/\(parts[1])"
        })
        let expected = (field["targetUri"] as? String) ?? "ontology://\(owner.id)/\(owner.version)/classes/\(parts[1])"
        let context = RuntimeReferenceIdentityContext(expectedURI: expected, candidateURIs: candidates)
        if !UnambiguousRuntimeReferenceSpec().isSatisfiedBy(context) {
            let location = fieldLocation(package: owner, className: className, rootClass: rootClass, fieldID: fieldID)
            let suffix = location.hasSuffix(".fields.\(fieldID)") ? ".target" : ""
            compiler.add("class.field.target.namespace_conflict", location + suffix,
                         "Reference \(owner.id)@\(owner.version):\(className).\(fieldID) target \(target) does not uniquely identify \(expected) among supplied packages")
        }
    }

    func fieldLocation(package: SDKPackage, className: String, rootClass: String, fieldID: String) -> String {
        if let root = packages.first, package.id == root.id, package.version == root.version, className == rootClass {
            return "spec.classes.\(className).fields.\(fieldID)"
        }
        return "spec.classes.\(rootClass).extends"
    }

    private func parentFields(_ item: JSONObject, package: SDKPackage, rootClass: String, visiting: Set<String>, warnings: inout Set<String>) -> [JSONObject] {
        guard let base = item["extends"] as? String else { return [] }
        let parts = base.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return [] }
        let alias = parts[0]
        let name = parts[1]
        if alias == package.namespace {
            return fields(of: name, in: package, rootClass: rootClass, visiting: visiting, warnings: &warnings)
        }
        guard let binding = package.imports.first(where: {
            ontologyImportNamespace(packageID: $0["id"] as? String, explicit: $0["namespace"] as? String) == alias
        }), let id = binding["id"] as? String, let version = binding["version"] as? String else { return [] }
        if FoundationExports.catalog(packageID: id, version: version) != nil { return [] }
        guard let parent = packages.first(where: { $0.id == id && $0.version == version }) else {
            let message = "Unverified inherited fields from \(id)@\(version):\(name); supply its source with --import"
            if warnings.insert(message).inserted {
                compiler.warn("sdk.inheritance.source_unavailable", "spec.classes.\(rootClass).extends", message)
            }
            return []
        }
        return fields(of: name, in: parent, rootClass: rootClass, visiting: visiting, warnings: &warnings)
    }

    func signature(_ field: JSONObject) -> InheritedFieldSignature {
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
    let protocols: [String: ProtocolRequirements]
    let relations: [String: JSONObject]

    var identity: DiagramPackageIdentity { DiagramPackageIdentity(id: id, version: version) }

    init(source: LoadedPackage, ir: JSONObject) {
        id = source.id
        version = source.version
        namespace = source.namespace
        imports = ir["imports"] as? [JSONObject] ?? []
        classes = Dictionary(uniqueKeysWithValues: (ir["classes"] as? [JSONObject] ?? []).compactMap { item in
            guard let name = item["id"] as? String else { return nil }
            return (name, item)
        })
        protocols = Dictionary(uniqueKeysWithValues: (ir["protocols"] as? [JSONObject] ?? []).compactMap { item in
            guard let name = item["id"] as? String else { return nil }
            return (name, ProtocolRequirements(fields: item["requiredFields"] as? [String] ?? [],
                                               relations: item["requiredRelations"] as? [String] ?? []))
        })
        relations = Dictionary(uniqueKeysWithValues: (ir["relations"] as? [JSONObject] ?? []).compactMap { item in
            guard let name = item["id"] as? String else { return nil }
            return (name, item)
        })
    }
}

struct ProtocolRequirements {
    let fields: [String]
    let relations: [String]
}
