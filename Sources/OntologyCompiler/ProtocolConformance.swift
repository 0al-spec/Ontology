import Foundation
import OntologyRules

private struct ProtocolClassIdentity: Hashable {
    let package: DiagramPackageIdentity
    let name: String
}

private struct ProtocolClassScope {
    let package: SDKPackage
    let name: String

    var identity: ProtocolClassIdentity { .init(package: package.identity, name: name) }
}

private struct ProtocolAncestry {
    var scopes: [ProtocolClassScope]
    var complete: Bool
}

struct ProtocolApplication {
    let reference: String
    let owner: SDKPackage
    let className: String
    let rootClass: String
}

extension TypeScriptInheritance {
    /// Validate instance and relation obligations against the actual class ancestry.
    func validateProtocolRequirements(_ requirements: ProtocolRequirements, fields: [JSONObject],
                                      application: ProtocolApplication, warnings: inout Set<String>) {
        let ancestry = protocolAncestry(name: application.className, package: application.owner, visiting: [])
        validateProtocolFields(requirements.fields, fields: fields, ancestry: ancestry, application: application, warnings: &warnings)
        validateProtocolRelations(requirements.relations, ancestry: ancestry, application: application, warnings: &warnings)
    }

    private func validateProtocolFields(_ requirements: [String], fields: [JSONObject], ancestry: ProtocolAncestry,
                                        application: ProtocolApplication, warnings: inout Set<String>) {
        let location = protocolLocation(application)
        let availableFields = Set(fields.compactMap { $0["id"] as? String })
        for name in requirements {
            let decision = ProtocolObligationDecisionSpec().decide(.init(
                name: name, declaredNames: availableFields, ancestryComplete: ancestry.complete
            ))
            switch decision {
            case .satisfied:
                guard let field = fields.first(where: { $0["id"] as? String == name }) else { continue }
                let required = InheritedFieldSignature(type: "string", required: true, target: nil)
                if !CompatibleInheritedFieldSpec().isSatisfiedBy((signature(field), required)) {
                    let path = fieldLocation(package: application.owner, className: application.className, rootClass: application.rootClass, fieldID: name)
                    compiler.add("class.inheritance.protocol_field_conflict", path,
                                 "Protocol \(application.reference) requires field \(name) to be a required string")
                }
            case .missing:
                compiler.add("protocol.field.missing", location,
                             "Class \(application.owner.id)@\(application.owner.version):\(application.className) implements \(application.reference) but lacks required field \(name)")
            case .unverified:
                warnUnverified("field", name: name, ref: application.reference, location: location, rootClass: application.rootClass, warnings: &warnings)
            case nil:
                break
            }
        }
    }

    private func validateProtocolRelations(_ requirements: [String], ancestry: ProtocolAncestry,
                                           application: ProtocolApplication, warnings: inout Set<String>) {
        let location = protocolLocation(application)
        let availableRelations = declaredRelations(in: ancestry)
        for name in requirements {
            let decision = ProtocolObligationDecisionSpec().decide(.init(
                name: name, declaredNames: availableRelations, ancestryComplete: ancestry.complete
            ))
            switch decision {
            case .satisfied:
                break
            case .missing:
                compiler.add("protocol.relation.missing", location,
                             "Class \(application.owner.id)@\(application.owner.version):\(application.className) implements \(application.reference) but lacks required relation \(name)")
            case .unverified:
                warnUnverified("relation", name: name, ref: application.reference, location: location, rootClass: application.rootClass, warnings: &warnings)
            case nil:
                break
            }
        }
    }

    private func protocolLocation(_ application: ProtocolApplication) -> String {
        let ownerIsRoot = application.owner.identity == packages.first?.identity && application.className == application.rootClass
        return ownerIsRoot ? "spec.classes.\(application.rootClass).implements" : "spec.classes.\(application.rootClass).extends"
    }

    private func warnUnverified(_ kind: String, name: String, ref: String, location: String,
                                rootClass: String, warnings: inout Set<String>) {
        let message = "Cannot verify required \(kind) \(name) from \(ref): an ancestor source is unavailable"
        if warnings.insert("\(rootClass): \(message)").inserted {
            compiler.warn("protocol.\(kind).unverified", location, message)
        }
    }

    private func protocolAncestry(name: String, package: SDKPackage, visiting: Set<ProtocolClassIdentity>) -> ProtocolAncestry {
        let scope = ProtocolClassScope(package: package, name: name)
        guard !visiting.contains(scope.identity), let item = package.classes[name] else {
            return .init(scopes: [], complete: false)
        }
        var next = visiting
        next.insert(scope.identity)
        guard let base = item["extends"] as? String, let identity = protocolClassIdentity(base, owner: package) else {
            return .init(scopes: [scope], complete: false)
        }
        let id = identity.package.id.rawValue
        let version = identity.package.version.rawValue
        if FoundationExports.catalog(packageID: id, version: version) != nil {
            return .init(scopes: [scope], complete: true)
        }
        guard let parent = packages.first(where: { $0.identity == identity.package }) else {
            return .init(scopes: [scope], complete: false)
        }
        var ancestry = protocolAncestry(name: identity.name, package: parent, visiting: next)
        ancestry.scopes.insert(scope, at: 0)
        return ancestry
    }

    private func protocolClassIdentity(_ ref: String, owner: SDKPackage) -> ProtocolClassIdentity? {
        let parts = ref.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        if parts[0] == owner.namespace { return .init(package: owner.identity, name: parts[1]) }
        guard let binding = owner.imports.first(where: {
            ontologyImportNamespace(packageID: $0["id"] as? String, explicit: $0["namespace"] as? String) == parts[0]
        }), let id = binding["id"] as? String, let version = binding["version"] as? String else { return nil }
        return .init(package: .init(id: id, version: version), name: parts[1])
    }

    private func declaredRelations(in ancestry: ProtocolAncestry) -> Set<String> {
        let identities = Set(ancestry.scopes.map(\.identity))
        var result = Set<String>()
        for scope in ancestry.scopes {
            for (name, relation) in scope.package.relations {
                guard let domain = relation["domain"] as? String,
                      let identity = protocolClassIdentity(domain, owner: scope.package),
                      identities.contains(identity) else { continue }
                result.insert(name)
            }
        }
        return result
    }
}
