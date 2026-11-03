import OntologyRules

struct PackageImportBindings {
    var namespaces = Set<String>()
    var foundations: [String: FoundationExports] = [:]

    func exports(for role: OntologyReferenceRole) -> [String: Set<String>] {
        foundations.mapValues { $0.names(for: role) }
    }
}

extension OntologyCompiler {
    func collectImportBindings(_ imports: [Any], package: LoadedPackage) -> PackageImportBindings {
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
            let catalog = FoundationExports.catalog(packageID: id, version: version)
            let defaultNamespace = FoundationExports.current.defaultNamespace(forPackageID: id)
            let isFoundation = defaultNamespace != nil
            if isFoundation, let version, catalog == nil {
                add("imports.foundation.version.unavailable", "\(path).version", "No foundation export catalog for version \(version)")
            }
            let alias: String?
            if entry["namespace"] != nil {
                alias = requiredString(entry, "namespace", path: "\(path).namespace", code: "imports.namespace.invalid")
            } else {
                alias = defaultNamespace
            }
            guard let alias else { continue }
            if alias == package.namespace || !bindings.namespaces.insert(alias).inserted {
                add("imports.namespace.conflict", "\(path).namespace", "Ambiguous import namespace \(alias)")
            }
            if let catalog {
                bindings.foundations[alias] = catalog
            }
        }
        return bindings
    }
}
