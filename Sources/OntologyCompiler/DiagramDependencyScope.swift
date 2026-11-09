import Foundation
import OntologyRules

/// Resolves only the dependency graph formed by the root and explicitly supplied files.
struct DiagramDependencyScope {
    let imported: [DiagramImportedPackage]
    let externalImports: [JSONObject]
    let foundationImports: [DiagramImportDeclaration]

    init(root: JSONObject, supplied: [JSONObject], digest: (String) -> String) throws {
        let graph = try DiagramPackageGraph(root: root, supplied: supplied)
        let reachable = graph.reachable()
        try graph.validateReachability(reachable)
        let bindings = try DiagramAliasScope(root: root, supplied: supplied, reachable: reachable, digest: digest)
        imported = try supplied.map { try bindings.importedPackage($0) }
        foundationImports = reachable.sorted { $0.diagramDescription < $1.diagramDescription }.compactMap { identity in
            guard graph.packages[identity] == nil, identity != graph.rootIdentity,
                  FoundationExports.catalog(packageID: identity.id.rawValue, version: identity.version.rawValue) != nil,
                  let alias = bindings.aliases[identity] else { return nil }
            return DiagramImportDeclaration(id: identity.id.rawValue, version: identity.version.rawValue, namespace: alias)
        }
        externalImports = reachable.sorted { $0.diagramDescription < $1.diagramDescription }.compactMap { identity in
            guard identity != graph.rootIdentity, bindings.direct[identity] == nil, graph.packages[identity] == nil,
                  let alias = bindings.aliases[identity] else { return nil }
            return ["id": identity.id.rawValue, "version": identity.version.rawValue, "alias": alias]
        }
    }
}
