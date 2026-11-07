import Foundation
import OntologyRules

/// Identity graph of the root and locally supplied dependency documents.
struct DiagramPackageGraph {
    let rootIdentity: DiagramPackageIdentity
    let supplied: [JSONObject]
    let packages: [DiagramPackageIdentity: JSONObject]

    init(root: JSONObject, supplied: [JSONObject]) throws {
        let rootID = diagramIdentity(root)
        rootIdentity = rootID
        self.supplied = supplied
        var found: [DiagramPackageIdentity: JSONObject] = [rootID: root]
        for ir in supplied {
            let identity = diagramIdentity(ir)
            guard found[identity] == nil else {
                throw OntologyCompilerError.invalidArgument("Duplicate supplied import for \(identity.diagramDescription)")
            }
            let scope = DiagramImportBindingContext(packageId: identity.id.rawValue, version: identity.version.rawValue,
                                                    rootNamespace: ir["namespace"] as? String ?? "", imports: diagramImports(ir))
            guard DiagramImportScopeSpec().isSatisfiedBy(scope) else {
                throw OntologyCompilerError.invalidArgument("Ambiguous namespace scope in supplied package \(identity.id.rawValue)")
            }
            found[identity] = ir
        }
        packages = found
    }

    func reachable() -> Set<DiagramPackageIdentity> {
        var found = Set([rootIdentity])
        var queue = [rootIdentity]
        var cursor = 0
        while cursor < queue.count {
            let current = queue[cursor]
            cursor += 1
            guard let package = packages[current] else { continue }
            for dependency in diagramImports(package) {
                let identity = diagramIdentity(dependency)
                if found.insert(identity).inserted { queue.append(identity) }
            }
        }
        return found
    }

    func validateReachability(_ reachable: Set<DiagramPackageIdentity>) throws {
        let spec = DiagramReachableImportSpec()
        for ir in supplied {
            let identity = diagramIdentity(ir)
            guard spec.isSatisfiedBy(.init(supplied: identity, reachable: reachable)) else {
                throw OntologyCompilerError.invalidArgument(
                    "Supplied package \(identity.diagramDescription) is not an exact direct import or reachable transitive import"
                )
            }
        }
    }
}

func diagramIdentity(_ ir: JSONObject) -> DiagramPackageIdentity {
    DiagramPackageIdentity(id: ir["id"] as? String ?? "", version: ir["version"] as? String ?? "")
}

func diagramIdentity(_ declaration: DiagramImportDeclaration) -> DiagramPackageIdentity {
    DiagramPackageIdentity(id: declaration.id.rawValue, version: declaration.version.rawValue)
}

extension DiagramPackageIdentity {
    var diagramDescription: String { "\(id.rawValue)@\(version.rawValue)" }
    var diagramAliasStem: String { "pkg-\(id.rawValue.split(separator: ".").last ?? "package")-" }
}
