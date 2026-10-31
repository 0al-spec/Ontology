import OntologyRules

struct PackageImportBindings {
    var namespaces = Set<String>()
    var foundationAliases = Set<String>()

    func exports(for role: OntologyReferenceRole) -> [String: Set<String>] {
        let names = FoundationExports.version010.names(for: role)
        return Dictionary(uniqueKeysWithValues: foundationAliases.map { ($0, names) })
    }
}

extension OntologyCompiler {
    func collectImportBindings(_ imports: [Any], package: LoadedPackage) -> PackageImportBindings {
        let catalog = FoundationExports.version010
        var bindings = PackageImportBindings()
        for (index, item) in imports.enumerated() {
            let path = "spec.imports[\(index)]"
            guard let entry = item as? JSONObject else {
                add("imports.type", path, "Import entry must be an object")
                continue
            }
            validateKnownKeys(entry, allowed: ["id", "namespace", "version"], path: path)
            let id = requiredString(entry, "id", path: "\(path).id", code: "imports.required")
            let version = requiredString(entry, "version", path: "\(path).version", code: "imports.required")
            let isFoundation = id == catalog.id
            if isFoundation, let version, version != catalog.version {
                add("imports.foundation.version.unavailable", "\(path).version", "No foundation export catalog for version \(version)")
            }
            let alias: String?
            if entry["namespace"] != nil {
                alias = requiredString(entry, "namespace", path: "\(path).namespace", code: "imports.namespace.invalid")
            } else {
                alias = isFoundation ? catalog.namespace : nil
            }
            guard let alias else { continue }
            if alias == package.namespace || !bindings.namespaces.insert(alias).inserted {
                add("imports.namespace.conflict", "\(path).namespace", "Ambiguous import namespace \(alias)")
            }
            if isFoundation, version == catalog.version {
                bindings.foundationAliases.insert(alias)
            }
        }
        return bindings
    }
}
