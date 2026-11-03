/// A reference slot determines which kind of imported symbol it can accept.
public enum OntologyReferenceRole: Sendable {
    case classType, protocolType, policyBase
}

/// The compiler-owned, offline export surface of the terminal foundation vocabulary.
public struct FoundationExports: Encodable, Sendable {
    public static let version010 = FoundationExports(version: "0.1.0", actorKinds: ["Actor", "SystemActor"])
    public static let current = FoundationExports(version: "0.2.0", actorKinds: [])

    public static func catalog(packageID: String?, version: String?) -> FoundationExports? {
        switch (packageID, version) {
        case (current.id, current.version): current
        case (version010.id, version010.version), ("specgraph.foundation", version010.version): version010
        default: nil
        }
    }

    public let schemaVersion: Int
    public let id: String
    public let version: String
    public let namespace: String
    public let classes: [String]
    public let protocols: [String]
    public let policyBases: [String]

    private init(version: String, actorKinds: [String]) {
        schemaVersion = 1
        id = "ontology.foundation"
        self.version = version
        namespace = "ont"
        classes = (["Capability", "Command", "DomainEntity", "Event", "Invariant", "Policy", "StateMachine", "ValueObject"] + actorKinds).sorted()
        protocols = ["Approvable", "Auditable", "DeviceBound", "RestrictableCapability", "Signable", "TimeBound", "Versioned"]
        policyBases = ["Policy"]
    }

    /// Use the historical namespace default for
    /// existing packages that omitted the namespace on their import.
    public func defaultNamespace(forPackageID packageID: String?) -> String? {
        switch packageID {
        case id: namespace
        case "specgraph.foundation": "sg"
        default: nil
        }
    }

    public func names(for role: OntologyReferenceRole) -> Set<String> {
        switch role {
        case .classType: Set(classes)
        case .protocolType: Set(protocols)
        case .policyBase: Set(policyBases)
        }
    }
}
