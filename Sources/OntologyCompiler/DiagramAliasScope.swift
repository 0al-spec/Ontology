import Foundation
import OntologyRules

/// Flattens package-local aliases only after binding exact identities and versions.
struct DiagramAliasScope {
    let aliases: [DiagramPackageIdentity: String]
    let direct: [DiagramPackageIdentity: [DiagramImportDeclaration]]

    init(root: JSONObject, supplied: [JSONObject], reachable: Set<DiagramPackageIdentity>,
         digest: (String) -> String) throws {
        let rootIdentity = diagramIdentity(root)
        let rootNamespace = root["namespace"] as? String ?? ""
        let rootImports = diagramImports(root)
        let directImports = Dictionary(grouping: rootImports, by: diagramIdentity)
        direct = directImports
        var result = try Self.directAliases(rootIdentity: rootIdentity, rootNamespace: rootNamespace,
                                            rootImports: rootImports, direct: directImports, supplied: supplied)
        var occupied = Set(rootImports.map { $0.namespace.rawValue })
        occupied.insert(rootNamespace)
        for identity in reachable.sorted(by: { $0.diagramDescription < $1.diagramDescription }) {
            guard identity != rootIdentity, directImports[identity] == nil else { continue }
            let alias = Self.uniqueAlias(identity, occupied: occupied, digest: digest)
            result[identity] = alias
            occupied.insert(alias)
        }
        aliases = result
    }

    func importedPackage(_ ir: JSONObject) throws -> DiagramImportedPackage {
        let identity = diagramIdentity(ir)
        guard let alias = aliases[identity] else {
            throw OntologyCompilerError.invalidArgument("Ambiguous import binding for \(identity.diagramDescription)")
        }
        var namespaces = [ir["namespace"] as? String ?? "": alias]
        for dependency in diagramImports(ir) {
            if let target = aliases[diagramIdentity(dependency)] {
                namespaces[dependency.namespace.rawValue] = target
            }
        }
        return DiagramImportedPackage(namespace: alias, ir: ir, namespaces: namespaces)
    }

    private static func directAliases(
        rootIdentity: DiagramPackageIdentity, rootNamespace: String, rootImports: [DiagramImportDeclaration],
        direct: [DiagramPackageIdentity: [DiagramImportDeclaration]], supplied: [JSONObject]
    ) throws -> [DiagramPackageIdentity: String] {
        var result: [DiagramPackageIdentity: String] = [rootIdentity: rootNamespace]
        for (identity, declarations) in direct where declarations.count == 1 && identity != rootIdentity {
            result[identity] = declarations[0].namespace.rawValue
        }
        for ir in supplied {
            let identity = diagramIdentity(ir)
            guard direct[identity] != nil else { continue }
            let context = DiagramImportBindingContext(packageId: identity.id.rawValue, version: identity.version.rawValue,
                                                     rootNamespace: rootNamespace, imports: rootImports)
            switch DiagramImportBindingSpec().decide(context) {
            case .matched(let namespace): result[identity] = namespace
            case .ambiguous: throw OntologyCompilerError.invalidArgument("Ambiguous direct import binding for \(identity.diagramDescription)")
            case .invalidNamespace, nil: throw OntologyCompilerError.invalidArgument("Invalid or shadowed namespace for \(identity.diagramDescription)")
            case .missing: throw OntologyCompilerError.invalidArgument("Missing direct import for \(identity.diagramDescription)")
            }
        }
        return result
    }

    private static func uniqueAlias(_ identity: DiagramPackageIdentity, occupied: Set<String>, digest: (String) -> String) -> String {
        let hash = digest(identity.diagramDescription).replacingOccurrences(of: "sha256:", with: "")
        var length = min(12, hash.count)
        var alias = identity.diagramAliasStem + String(hash.prefix(length))
        while occupied.contains(alias), length < hash.count {
            length = min(length + 4, hash.count)
            alias = identity.diagramAliasStem + String(hash.prefix(length))
        }
        var suffix = 2
        let base = alias
        while occupied.contains(alias) {
            alias = "\(base)-\(suffix)"
            suffix += 1
        }
        return alias
    }
}
